import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a consultation booking/history
class Booking {
  final String id;
  final String facultyId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String scheduleDay;
  final String timeStart;
  final String timeEnd;
  final String title;
  final String status; // 'completed', 'pending', 'cancelled'
  final String purpose;
  final DateTime bookedAt;
  final DateTime? completedAt;

  Booking({
    required this.id,
    required this.facultyId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.scheduleDay,
    required this.timeStart,
    required this.timeEnd,
    required this.title,
    required this.status,
    required this.purpose,
    required this.bookedAt,
    this.completedAt,
  });

  /// Convert Booking to Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'scheduleDay': scheduleDay,
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'title': title,
      'status': status,
      'purpose': purpose,
      'bookedAt': bookedAt,
      'completedAt': completedAt,
    };
  }

  /// Create Booking from Firestore document
  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      facultyId: data['facultyId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown Student',
      studentEmail: data['studentEmail'] ?? '',
      scheduleDay: data['scheduleDay'] ?? '',
      timeStart: data['timeStart'] ?? '',
      timeEnd: data['timeEnd'] ?? '',
      title: data['title'] ?? '',
      status: data['status'] ?? 'pending',
      purpose: data['purpose'] ?? '',
      bookedAt: data['bookedAt'] is Timestamp
          ? (data['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create a copy with some fields replaced
  Booking copyWith({
    String? id,
    String? facultyId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? scheduleDay,
    String? timeStart,
    String? timeEnd,
    String? title,
    String? status,
    String? purpose,
    DateTime? bookedAt,
    DateTime? completedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      scheduleDay: scheduleDay ?? this.scheduleDay,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      title: title ?? this.title,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      bookedAt: bookedAt ?? this.bookedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
