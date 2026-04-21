import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String scheduleId;
  final String facultyId;
  final String studentId;
  final String studentEmail;
  final String studentName;
  final String studentDepartment;
  final String reason; // reason for booking
  final String status; // pending, approved, rejected, cancelled
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.scheduleId,
    required this.facultyId,
    required this.studentId,
    required this.studentEmail,
    required this.studentName,
    required this.studentDepartment,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Appointment to Map (for Firebase Firestore)
  Map<String, dynamic> toMap() {
    return {
      'schedule_id': scheduleId,
      'faculty_id': facultyId,
      'student_id': studentId,
      'student_email': studentEmail,
      'student_name': studentName,
      'student_department': studentDepartment,
      'reason': reason,
      'status': status,
      'rejection_reason': rejectionReason,
      'cancellation_reason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create Appointment from Firebase Firestore Map
  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      }
    }

    DateTime updatedAt = DateTime.now();
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
      } else if (map['updatedAt'] is String) {
        updatedAt = DateTime.parse(map['updatedAt'] as String);
      }
    }

    return Appointment(
      id: id,
      scheduleId: map['schedule_id'] ?? '',
      facultyId: map['faculty_id'] ?? '',
      studentId: map['student_id'] ?? '',
      studentEmail: map['student_email'] ?? '',
      studentName: map['student_name'] ?? '',
      studentDepartment: map['student_department'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      cancellationReason: map['cancellation_reason'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create Appointment from Firestore Document Snapshot
  factory Appointment.fromSnapshot(DocumentSnapshot snapshot) {
    return Appointment.fromMap(
        snapshot.id, snapshot.data() as Map<String, dynamic>);
  }

  /// Create a copy with modified fields
  Appointment copyWith({
    String? id,
    String? scheduleId,
    String? facultyId,
    String? studentId,
    String? studentEmail,
    String? studentName,
    String? studentDepartment,
    String? reason,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      facultyId: facultyId ?? this.facultyId,
      studentId: studentId ?? this.studentId,
      studentEmail: studentEmail ?? this.studentEmail,
      studentName: studentName ?? this.studentName,
      studentDepartment: studentDepartment ?? this.studentDepartment,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, scheduleId: $scheduleId, studentId: $studentId, status: $status)';
  }
}
