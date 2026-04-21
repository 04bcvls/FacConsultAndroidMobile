import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String studentId;
  final String bookingId;
  final String facultyId;
  final String facultyName;
  final String scheduleTitle; // Title of the consultation/meeting
  final String message;
  final String type; // approved, rejected, cancelled, etc.
  final String scheduleDatetime; // For reference
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.studentId,
    required this.bookingId,
    required this.facultyId,
    required this.facultyName,
    required this.scheduleTitle,
    required this.message,
    required this.type,
    required this.scheduleDatetime,
    required this.read,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'booking_id': bookingId,
      'faculty_id': facultyId,
      'faculty_name': facultyName,
      'schedule_title': scheduleTitle,
      'message': message,
      'type': type,
      'schedule_datetime': scheduleDatetime,
      'read': read,
      'created_at': createdAt,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      studentId: map['student_id'] ?? '',
      bookingId: map['booking_id'] ?? '',
      facultyId: map['faculty_id'] ?? '',
      facultyName: map['faculty_name'] ?? 'Unknown Faculty',
      scheduleTitle: map['schedule_title'] ?? 'Consultation',
      message: map['message'] ?? '',
      type: map['type'] ?? 'info',
      scheduleDatetime: map['schedule_datetime'] ?? '',
      read: map['read'] ?? false,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory NotificationModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap({
      ...data,
      'id': doc.id, // Use the Firestore document ID
    });
  }

  NotificationModel copyWith({
    String? id,
    String? studentId,
    String? bookingId,
    String? facultyId,
    String? facultyName,
    String? scheduleTitle,
    String? message,
    String? type,
    String? scheduleDatetime,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bookingId: bookingId ?? this.bookingId,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      scheduleTitle: scheduleTitle ?? this.scheduleTitle,
      message: message ?? this.message,
      type: type ?? this.type,
      scheduleDatetime: scheduleDatetime ?? this.scheduleDatetime,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
