import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:andfacconsult/models/schedule.dart';
import 'package:andfacconsult/models/appointment.dart';
import 'package:andfacconsult/models/notification.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;
import 'package:andfacconsult/services/firestore_notification_service.dart';

class FirestoreScheduleBookingService {
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  
  late final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();

  static const String _scheduleCollection = 'schedules';
  static const String _bookingCollection = 'bookings';

  /// Get current student/user ID
  String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  /// Get current user email
  String? get _currentUserEmail => _firebaseAuth.currentUser?.email;

  // ==================== SCHEDULE OPERATIONS ====================

  /// Get all available schedules for a faculty member
  Future<List<Schedule>> getSchedulesForFaculty(String facultyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_scheduleCollection)
          .where('faculty_id', isEqualTo: facultyId)
          .where('status', isEqualTo: 'active')
          .orderBy('date', descending: false)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => Schedule.fromSnapshot(doc))
          .toList();

      logger_util.logInfo(
          'Fetched ${schedules.length} schedules for faculty $facultyId');
      return schedules;
    } catch (e) {
      logger_util.logError('Error fetching faculty schedules: $e');
      rethrow;
    }
  }

  /// Get active schedules for a faculty (real-time stream)
  Stream<List<Schedule>> getSchedulesForFacultyStream(String facultyId) {
    return _firestore
        .collection(_scheduleCollection)
        .where('faculty_id', isEqualTo: facultyId)
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Schedule.fromSnapshot(doc)).toList();
    });
  }

  /// Get a specific schedule by ID
  Future<Schedule?> getScheduleById(String scheduleId) async {
    try {
      final doc =
          await _firestore.collection(_scheduleCollection).doc(scheduleId).get();

      if (doc.exists) {
        final schedule = Schedule.fromSnapshot(doc);
        logger_util.logInfo('Fetched schedule: $scheduleId');
        return schedule;
      }

      logger_util.logInfo('Schedule $scheduleId not found');
      return null;
    } catch (e) {
      logger_util.logError('Error fetching schedule by ID: $e');
      rethrow;
    }
  }

  // ==================== BOOKING OPERATIONS ====================

  /// Check if a schedule is already booked
  Future<Appointment?> getExistingBooking(String scheduleId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingCollection)
          .where('schedule_id', isEqualTo: scheduleId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final booking = Appointment.fromSnapshot(querySnapshot.docs.first);
        logger_util.logInfo('Schedule $scheduleId is already booked');
        return booking;
      }

      return null;
    } catch (e) {
      logger_util.logError('Error checking existing booking: $e');
      rethrow;
    }
  }

  /// Book a schedule for current student
  Future<String> bookSchedule({
    required String scheduleId,
    required String facultyId,
    required String reason,
    required String studentName,
    required String studentDepartment,
  }) async {
    try {
      if (_currentUserId == null || _currentUserEmail == null) {
        throw Exception('User not authenticated');
      }

      // Check if schedule is already booked
      final existingBooking = await getExistingBooking(scheduleId);
      if (existingBooking != null) {
        throw Exception(
            'This schedule is already booked by another student');
      }

      // Fetch faculty name to store in booking
      var facultyName = 'Faculty Member';
      try {
        final facultyDoc = await _firestore
            .collection('faculty')
            .doc(facultyId)
            .get();
        
        if (facultyDoc.exists) {
          final facultyData = facultyDoc.data() as Map<String, dynamic>;
          // Faculty collection uses first_name and last_name
          final firstName = facultyData['first_name'] ?? '';
          final lastName = facultyData['last_name'] ?? '';
          
          if (firstName.toString().isNotEmpty || lastName.toString().isNotEmpty) {
            facultyName = '${firstName.toString()} ${lastName.toString()}'.trim();
          }
        }
      } catch (e) {
        logger_util.logError('Error fetching faculty name for booking: $e');
      }

      final appointment = Appointment(
        id: '', // Will be set by Firestore
        scheduleId: scheduleId,
        facultyId: facultyId,
        studentId: _currentUserId!,
        studentEmail: _currentUserEmail!,
        studentName: studentName,
        studentDepartment: studentDepartment,
        reason: reason,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final appointmentMap = appointment.toMap();
      // Add faculty name to booking for easy access and fallback
      appointmentMap['faculty_name'] = facultyName;

      final docRef = await _firestore
          .collection(_bookingCollection)
          .add(appointmentMap);

      logger_util.logInfo('Booking created with ID: ${docRef.id}');
      
      // Create initial "pending" notification with schedule details
      try {
        // Fetch schedule to get title
        var scheduleTitle = 'Consultation';
        var facultyName = 'Faculty Member';
        String scheduleDatetime = DateTime.now().toIso8601String();
        
        try {
          final scheduleDoc = await _firestore
              .collection(_scheduleCollection)
              .doc(scheduleId)
              .get();
          
          if (scheduleDoc.exists) {
            final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
            scheduleTitle = scheduleData['title'] ?? 'Consultation';
            
            // Build full datetime with date and time
            final dateStr = scheduleData['date'] ?? '';
            final timeStartStr = scheduleData['time_start'] ?? '';
            
            if (dateStr.isNotEmpty && timeStartStr.isNotEmpty) {
              try {
                final parts = dateStr.split('-');
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final day = int.parse(parts[2]);
                
                final timeStr = timeStartStr.replaceAll(RegExp(r'[^0-9:]'), '');
                final timeParts = timeStr.split(':');
                final hour = int.parse(timeParts[0]);
                final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
                
                final fullDateTime = DateTime(year, month, day, hour, minute);
                scheduleDatetime = fullDateTime.toIso8601String();
              } catch (e) {
                logger_util.logWarning('Error parsing schedule datetime: $e');
                scheduleDatetime = dateStr;
              }
            } else {
              scheduleDatetime = dateStr.isNotEmpty ? dateStr : DateTime.now().toIso8601String();
            }
          }
        } catch (e) {
          logger_util.logError('Error fetching schedule details: $e');
        }
        
        // Fetch faculty name
        try {
          final facultyDoc = await _firestore
              .collection('faculty')
              .doc(facultyId)
              .get();
          
          if (facultyDoc.exists) {
            final facultyData = facultyDoc.data() as Map<String, dynamic>;
            // Faculty collection uses first_name and last_name
            final firstName = facultyData['first_name'] ?? '';
            final lastName = facultyData['last_name'] ?? '';
            
            if (firstName.toString().isNotEmpty || lastName.toString().isNotEmpty) {
              facultyName = '${firstName.toString()} ${lastName.toString()}'.trim();
            }
            logger_util.logInfo('Fetched faculty name: $facultyName');
          }
        } catch (e) {
          logger_util.logError('Error fetching faculty name: $e');
        }
        
        final notification = NotificationModel(
          id: '',
          studentId: _currentUserId!,
          bookingId: docRef.id,
          facultyId: facultyId,
          facultyName: facultyName,
          scheduleTitle: scheduleTitle,
          message: 'Your consultation appointment request is pending approval.',
          type: 'pending',
          scheduleDatetime: scheduleDatetime,
          read: false,
          createdAt: DateTime.now(),
        );
        await _notificationService.createNotification(notification);
        logger_util.logInfo('Pending notification created for booking ${docRef.id}');
      } catch (e) {
        logger_util.logError('Error creating pending notification: $e');
        // Don't rethrow - booking was successful, just notification failed
      }
      
      return docRef.id;
    } catch (e) {
      logger_util.logError('Error booking schedule: $e');
      rethrow;
    }
  }

  /// Get all bookings for current student
  Future<List<Appointment>> getStudentBookings() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_bookingCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();

      // Sort by createdAt in Dart instead of using Firestore orderBy
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logger_util.logInfo(
          'Fetched ${bookings.length} bookings for student');
      return bookings;
    } catch (e) {
      logger_util.logError('Error fetching student bookings: $e');
      rethrow;
    }
  }

  /// Stream of all bookings for current student (real-time)
  Stream<List<Appointment>> getStudentBookingsStream() {
    if (_currentUserId == null) {
      return Stream.error('User not authenticated');
    }

    return _firestore
        .collection(_bookingCollection)
        .where('student_id', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();
      // Sort by createdAt in Dart instead of using Firestore orderBy
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// Get booking details with associated schedule
  Future<Map<String, dynamic>?> getBookingWithSchedule(
      String bookingId) async {
    try {
      final bookingDoc = await _firestore
          .collection(_bookingCollection)
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        return null;
      }

      final booking = Appointment.fromSnapshot(bookingDoc);
      final schedule = await getScheduleById(booking.scheduleId);

      return {
        'booking': booking,
        'schedule': schedule,
      };
    } catch (e) {
      logger_util.logError('Error fetching booking with schedule: $e');
      rethrow;
    }
  }

  /// Cancel a booking (student can only cancel pending bookings)
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore
          .collection(_bookingCollection)
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      logger_util.logInfo('Booking $bookingId cancelled');
    } catch (e) {
      logger_util.logError('Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Approve a booking and create notification
  Future<void> approveBooking({
    required String bookingId,
    required String studentId,
    required String facultyId,
    required String facultyName,
  }) async {
    try {
      // Update booking status
      await _firestore
          .collection(_bookingCollection)
          .doc(bookingId)
          .update({
        'status': 'approved',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Fetch booking to get schedule ID and details
      String scheduleTitle = 'Consultation';
      String scheduleDatetime = DateTime.now().toIso8601String();
      
      try {
        final bookingDoc = await _firestore
            .collection(_bookingCollection)
            .doc(bookingId)
            .get();
        
        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data() as Map<String, dynamic>;
          final scheduleId = bookingData['schedule_id'] ?? '';
          
          if (scheduleId.isNotEmpty) {
            final scheduleDoc = await _firestore
                .collection(_scheduleCollection)
                .doc(scheduleId)
                .get();
            
            if (scheduleDoc.exists) {
              final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
              scheduleTitle = scheduleData['title'] ?? 'Consultation';
              
              // Build full datetime with date and time
              final dateStr = scheduleData['date'] ?? '';
              final timeStartStr = scheduleData['time_start'] ?? '';
              
              if (dateStr.isNotEmpty && timeStartStr.isNotEmpty) {
                try {
                  final parts = dateStr.split('-');
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final day = int.parse(parts[2]);
                  
                  final timeStr = timeStartStr.replaceAll(RegExp(r'[^0-9:]'), '');
                  final timeParts = timeStr.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
                  
                  final fullDateTime = DateTime(year, month, day, hour, minute);
                  scheduleDatetime = fullDateTime.toIso8601String();
                } catch (e) {
                  logger_util.logWarning('Error parsing schedule datetime: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        logger_util.logError('Error fetching booking/schedule details: $e');
      }

      // Create approval notification
      final notification = NotificationModel(
        id: '',
        studentId: studentId,
        bookingId: bookingId,
        facultyId: facultyId,
        facultyName: facultyName,
        scheduleTitle: scheduleTitle,
        message: 'Your consultation appointment with $facultyName has been approved!',
        type: 'approved',
        scheduleDatetime: scheduleDatetime,
        read: false,
        createdAt: DateTime.now(),
      );
      await _notificationService.createNotification(notification);

      logger_util.logInfo('Booking $bookingId approved and notification sent');
    } catch (e) {
      logger_util.logError('Error approving booking: $e');
      rethrow;
    }
  }

  /// Reject a booking and create notification
  Future<void> rejectBooking({
    required String bookingId,
    required String studentId,
    required String facultyId,
    required String facultyName,
    required String reason,
  }) async {
    try {
      // Update booking status
      await _firestore
          .collection(_bookingCollection)
          .doc(bookingId)
          .update({
        'status': 'rejected',
        'rejection_reason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Fetch booking to get schedule ID and details
      String scheduleTitle = 'Consultation';
      String scheduleDatetime = DateTime.now().toIso8601String();
      
      try {
        final bookingDoc = await _firestore
            .collection(_bookingCollection)
            .doc(bookingId)
            .get();
        
        if (bookingDoc.exists) {
          final bookingData = bookingDoc.data() as Map<String, dynamic>;
          final scheduleId = bookingData['schedule_id'] ?? '';
          
          if (scheduleId.isNotEmpty) {
            final scheduleDoc = await _firestore
                .collection(_scheduleCollection)
                .doc(scheduleId)
                .get();
            
            if (scheduleDoc.exists) {
              final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
              scheduleTitle = scheduleData['title'] ?? 'Consultation';
              
              // Build full datetime with date and time
              final dateStr = scheduleData['date'] ?? '';
              final timeStartStr = scheduleData['time_start'] ?? '';
              
              if (dateStr.isNotEmpty && timeStartStr.isNotEmpty) {
                try {
                  final parts = dateStr.split('-');
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final day = int.parse(parts[2]);
                  
                  final timeStr = timeStartStr.replaceAll(RegExp(r'[^0-9:]'), '');
                  final timeParts = timeStr.split(':');
                  final hour = int.parse(timeParts[0]);
                  final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
                  
                  final fullDateTime = DateTime(year, month, day, hour, minute);
                  scheduleDatetime = fullDateTime.toIso8601String();
                } catch (e) {
                  logger_util.logWarning('Error parsing schedule datetime: $e');
                }
              }
            }
          }
        }
      } catch (e) {
        logger_util.logError('Error fetching booking/schedule details: $e');
      }

      // Create rejection notification
      final notification = NotificationModel(
        id: '',
        studentId: studentId,
        bookingId: bookingId,
        facultyId: facultyId,
        facultyName: facultyName,
        scheduleTitle: scheduleTitle,
        message: 'Your consultation request has been rejected. Reason: $reason',
        type: 'rejected',
        scheduleDatetime: scheduleDatetime,
        read: false,
        createdAt: DateTime.now(),
      );
      await _notificationService.createNotification(notification);

      logger_util.logInfo('Booking $bookingId rejected and notification sent');
    } catch (e) {
      logger_util.logError('Error rejecting booking: $e');
      rethrow;
    }
  }

  /// Cancel a booking and create notification
  Future<void> cancelBookingWithNotification({
    required String bookingId,
    required String studentId,
    required String facultyId,
    required String facultyName,
    String? cancellationReason,
  }) async {
    try {
      // Update booking status
      await _firestore
          .collection(_bookingCollection)
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'cancellation_reason': cancellationReason ?? '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create cancellation notification with reason
      final message = cancellationReason != null && cancellationReason.isNotEmpty
          ? 'Your consultation appointment has been cancelled.\n\nReason: $cancellationReason'
          : 'Your consultation appointment has been cancelled.';

      final notification = NotificationModel(
        id: '',
        studentId: studentId,
        bookingId: bookingId,
        facultyId: facultyId,
        facultyName: facultyName,
        scheduleTitle: 'Consultation',
        message: message,
        type: 'cancelled',
        scheduleDatetime: DateTime.now().toIso8601String(),
        read: false,
        createdAt: DateTime.now(),
      );
      await _notificationService.createNotification(notification);

      logger_util.logInfo('Booking $bookingId cancelled with reason: ${cancellationReason ?? "No reason provided"} and notification sent');
    } catch (e) {
      logger_util.logError('Error cancelling booking with notification: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  /// Get all bookings for a faculty member (stream for real-time updates)
  Stream<List<Appointment>> getFacultyBookingsStream(String facultyId) {
    return _firestore
        .collection(_bookingCollection)
        .where('faculty_id', isEqualTo: facultyId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();
      // Sort by created_at in descending order (newest first)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  /// Get all bookings for a faculty member (one-time fetch)
  Future<List<Appointment>> getFacultyBookings(String facultyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingCollection)
          .where('faculty_id', isEqualTo: facultyId)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();
      
      // Sort by created_at in descending order (newest first)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logger_util.logInfo('Fetched ${bookings.length} bookings for faculty $facultyId');
      return bookings;
    } catch (e) {
      logger_util.logError('Error fetching faculty bookings: $e');
      return [];
    }
  }

  /// Get all bookings for a schedule (to show who booked it)
  Future<List<Appointment>> getBookingsForSchedule(String scheduleId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingCollection)
          .where('schedule_id', isEqualTo: scheduleId)
          .get();

      final bookings = querySnapshot.docs
          .map((doc) => Appointment.fromSnapshot(doc))
          .toList();

      logger_util.logInfo(
          'Fetched ${bookings.length} bookings for schedule $scheduleId');
      return bookings;
    } catch (e) {
      logger_util.logError('Error fetching bookings for schedule: $e');
      rethrow;
    }
  }

  /// Get a specific booking by ID
  Future<Appointment?> getBookingById(String bookingId) async {
    try {
      final doc =
          await _firestore.collection(_bookingCollection).doc(bookingId).get();

      if (doc.exists) {
        final booking = Appointment.fromSnapshot(doc);
        logger_util.logInfo('Fetched booking: $bookingId');
        return booking;
      }

      logger_util.logInfo('Booking $bookingId not found');
      return null;
    } catch (e) {
      logger_util.logError('Error fetching booking by ID: $e');
      rethrow;
    }
  }
}
