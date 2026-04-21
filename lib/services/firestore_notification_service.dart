import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:andfacconsult/models/notification.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;

class FirestoreNotificationService {
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  late final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _notificationsCollection = 'notifications';
  
  // Prevent concurrent sync calls to avoid duplicates
  static bool _isSyncing = false;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get all notifications for the current student
  Future<List<NotificationModel>> getStudentNotifications() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromSnapshot(doc))
          .toList();
      
      // Sort by created_at in descending order (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logger_util.logInfo('Fetched ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      logger_util.logError('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get notifications stream (for real-time updates)
  Stream<List<NotificationModel>> getStudentNotificationsStream() {
    if (_currentUserId == null) {
      logger_util.logError('User not authenticated');
      return Stream.value([]);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('student_id', isEqualTo: _currentUserId)
        .snapshots()
        .handleError((error) {
          // Silently handle permission errors (occur during logout)
          if (error.toString().contains('permission-denied')) {
            logger_util.logInfo('Notification stream error: User logged out');
          } else {
            logger_util.logError('Error in notification stream: $error');
          }
          return [];
        })
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromSnapshot(doc))
              .toList();
          // Sort by created_at in descending order (newest first)
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .where('read', isEqualTo: false)
          .get();

      logger_util.logInfo('Unread notifications: ${querySnapshot.docs.length}');
      return querySnapshot.docs.length;
    } catch (e) {
      logger_util.logError('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Get unread notifications count stream
  Stream<int> getUnreadNotificationsCountStream() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('student_id', isEqualTo: _currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .handleError((error) {
          // Silently handle permission errors (occur during logout)
          if (error.toString().contains('permission-denied')) {
            logger_util.logInfo('Unread count stream error: User logged out');
          } else {
            logger_util.logError('Error in unread count stream: $error');
          }
          return 0;
        })
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'read': true});

      logger_util.logInfo('Notification $notificationId marked as read');
    } catch (e) {
      logger_util.logError('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'read': true});
      }

      logger_util.logInfo('All notifications marked as read');
    } catch (e) {
      logger_util.logError('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Create a notification (typically called from faculty/admin side, but included for completeness)
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection(_notificationsCollection)
          .add(notification.toMap());

      logger_util.logInfo('Notification created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger_util.logError('Error creating notification: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();

      logger_util.logInfo('Notification $notificationId deleted');
    } catch (e) {
      logger_util.logError('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Clear all old read notifications (older than 30 days)
  Future<void> clearOldNotifications() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .where('read', isEqualTo: true)
          .where('created_at', isLessThan: thirtyDaysAgo)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      logger_util.logInfo('Cleared ${querySnapshot.docs.length} old notifications');
    } catch (e) {
      logger_util.logError('Error clearing old notifications: $e');
    }
  }

  /// Clear ALL notifications for current student (no confirmation)
  Future<int> clearAllNotificationsDirectly() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .get();

      int deletedCount = querySnapshot.docs.length;
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      logger_util.logInfo('Directly cleared all $deletedCount notifications for student $_currentUserId');
      return deletedCount;
    } catch (e) {
      logger_util.logError('Error clearing all notifications directly: $e');
      rethrow;
    }
  }

  /// Clear ALL notifications for current student
  Future<void> clearAllNotifications() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('student_id', isEqualTo: _currentUserId)
          .get();

      int deletedCount = querySnapshot.docs.length;
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      logger_util.logInfo('Cleared all $deletedCount notifications for student $_currentUserId');
    } catch (e) {
      logger_util.logError('Error clearing all notifications: $e');
      rethrow;
    }
  }

  /// Sync notifications for bookings with status changes (e.g., faculty approved/rejected directly in Firestore)
  /// This creates notifications for approved/rejected/cancelled bookings that don't have corresponding notifications yet
  Future<void> syncNotificationsForBookingStatusChanges() async {
    // Prevent concurrent sync calls to avoid duplicates
    if (_isSyncing) {
      logger_util.logInfo('Sync already in progress, skipping');
      return;
    }

    // Early return if no user is authenticated (e.g., user logged out)
    if (_currentUserId == null) {
      logger_util.logInfo('No authenticated user, skipping notification sync');
      return;
    }

    _isSyncing = true;
    try {
      // Get all bookings for this student
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('student_id', isEqualTo: _currentUserId)
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final booking = bookingDoc.data();
        final bookingId = bookingDoc.id;
        final status = booking['status'] ?? 'pending';

        // Only process approved, rejected, cancelled
        if (!['approved', 'rejected', 'cancelled'].contains(status)) {
          continue;
        }

        // Check if notification already exists for this exact booking with this status
        final existingNotification = await _firestore
            .collection(_notificationsCollection)
            .where('booking_id', isEqualTo: bookingId)
            .where('type', isEqualTo: status)
            .get();

        // Skip if notification already exists
        if (existingNotification.docs.isNotEmpty) {
          // logger_util.logInfo('Notification already exists for booking $bookingId with status $status');
          continue;
        }

        // Create the missing notification
        var facultyName = booking['faculty_name'] ?? booking['facultyName'] ?? 'Faculty Member';
        var scheduleTitle = 'Consultation';
        
        logger_util.logInfo('Processing booking $bookingId with status $status - Initial faculty_name from booking: $facultyName');
        
        // Try to fetch the actual faculty name if we have a faculty_id
        try {
          final facultyId = booking['faculty_id'];
          if (facultyId != null && facultyId.isNotEmpty) {
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
                logger_util.logInfo('Fetched faculty name: $facultyName (from first_name: $firstName, last_name: $lastName)');
              } else {
                logger_util.logInfo('Faculty doc exists but first_name and last_name are empty. Available fields: ${facultyData.keys.toList()}');
              }
            } else {
              logger_util.logInfo('Faculty doc not found in collection for ID: $facultyId');
            }
          } else {
            logger_util.logInfo('No faculty_id in booking $bookingId');
          }
        } catch (e) {
          logger_util.logInfo('Could not fetch faculty name: $e');
        }
        
        // Get schedule date and title from the booking's schedule
        String scheduleDatetime = DateTime.now().toIso8601String();
        String timeStartFormatted = '';
        String timeEndFormatted = '';
        try {
          final scheduleId = booking['schedule_id'];
          if (scheduleId != null) {
            final scheduleDoc = await _firestore
                .collection('schedules')
                .doc(scheduleId)
                .get();
            if (scheduleDoc.exists) {
              final scheduleData = scheduleDoc.data() as Map<String, dynamic>;
              scheduleTitle = scheduleData['title'] ?? 'Consultation';
              
              // Get date, timeStart, and timeEnd
              final date = scheduleData['date'] ?? '';
              final timeStart = scheduleData['time_start'] ?? '';
              final timeEnd = scheduleData['time_end'] ?? '';
              
              timeStartFormatted = timeStart;
              timeEndFormatted = timeEnd;
              
              // Try to parse date and time to create a proper DateTime
              try {
                if (date.isNotEmpty && timeStart.isNotEmpty) {
                  // Parse date (format: "2026-04-20")
                  final dateParts = date.split('-');
                  if (dateParts.length == 3) {
                    final year = int.parse(dateParts[0]);
                    final month = int.parse(dateParts[1]);
                    final day = int.parse(dateParts[2]);
                    
                    // Parse time (format: "6:00 PM" or "10:00 AM")
                    final timeStr = timeStart.replaceAll(RegExp(r'[^0-9:]'), '');
                    final timeParts = timeStr.split(':');
                    var hour = int.parse(timeParts[0]);
                    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
                    
                    // Adjust hour for PM times
                    if (timeStart.toUpperCase().contains('PM') && hour != 12) {
                      hour += 12;
                    } else if (timeStart.toUpperCase().contains('AM') && hour == 12) {
                      hour = 0;
                    }
                    
                    final scheduleDateTime = DateTime(year, month, day, hour, minute);
                    scheduleDatetime = scheduleDateTime.toIso8601String();
                    logger_util.logInfo('Parsed schedule datetime: $scheduleDatetime from date=$date, timeStart=$timeStart');
                  }
                }
              } catch (e) {
                logger_util.logError('Error parsing schedule date/time: $e');
              }
            }
          }
        } catch (e) {
          logger_util.logError('Error fetching schedule date/title: $e');
        }
        
        late String message;
        switch (status) {
          case 'approved':
            message = 'Your consultation appointment with $facultyName has been approved!';
            break;
          case 'rejected':
            message = 'Your consultation appointment has been rejected. Reason: ${booking['rejectionReason'] ?? 'No reason provided'}';
            break;
          case 'cancelled':
            message = 'Your consultation appointment has been cancelled.';
            break;
          default:
            message = 'Your consultation appointment status has been updated to $status';
        }

        final notification = NotificationModel(
          id: '',
          studentId: _currentUserId!,
          bookingId: bookingId,
          facultyId: booking['faculty_id'] ?? '',
          facultyName: facultyName,
          scheduleTitle: scheduleTitle,
          message: message,
          type: status,
          scheduleDatetime: scheduleDatetime,
          read: false,
          createdAt: DateTime.now(),
        );

        await createNotification(notification);
        logger_util.logInfo('Created missing $status notification: Title="$scheduleTitle" Faculty="$facultyName" for booking $bookingId');
      }
    } catch (e) {
      // Skip permission errors gracefully (happens during logout when listeners still fire)
      if (e.toString().contains('permission-denied')) {
        logger_util.logInfo('Notification sync skipped: User logged out or permissions denied');
      } else {
        logger_util.logError('Error syncing booking notifications: $e');
      }
      // Don't rethrow - this is a best-effort operation
    } finally {
      _isSyncing = false;
    }
  }
}
