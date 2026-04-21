import 'package:cloud_firestore/cloud_firestore.dart';

/// Schedule model representing a faculty-created consultation time slot
class Schedule {
  final String id;
  final String facultyId;
  final String date; // ISO format: "2026-04-20"
  final String timeStart; // "10:00 AM"
  final String timeEnd; // "12:00 PM"
  final String type; // consultation, class, meeting
  final String title;
  final String location;
  final String status; // active, cancelled
  final String? cancellationReason;
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.facultyId,
    required this.date,
    required this.timeStart,
    required this.timeEnd,
    required this.type,
    required this.title,
    required this.location,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
  });

  /// Get formatted date string
  String get formattedDate {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[month - 1]} $day, $year';
  }

  /// Get datetime from date and time start
  DateTime get scheduleDateTime {
    final parts = date.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    
    final timeStr = timeStart.replaceAll(RegExp(r'[^0-9:]'), '');
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
    
    return DateTime(year, month, day, hour, minute);
  }

  /// Convert Schedule to Map (for Firebase Firestore)
  Map<String, dynamic> toMap() {
    return {
      'faculty_id': facultyId,
      'date': date,
      'time_start': timeStart,
      'time_end': timeEnd,
      'type': type,
      'title': title,
      'location': location,
      'status': status,
      'cancellation_reason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create Schedule from Firebase Firestore Map
  factory Schedule.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      }
    }

    return Schedule(
      id: id,
      facultyId: map['faculty_id'] ?? '',
      date: map['date'] ?? '',
      timeStart: map['time_start'] ?? '',
      timeEnd: map['time_end'] ?? '',
      type: map['type'] ?? 'consultation',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'active',
      cancellationReason: map['cancellation_reason'],
      createdAt: createdAt,
    );
  }

  /// Create Schedule from Firestore Document Snapshot
  factory Schedule.fromSnapshot(DocumentSnapshot snapshot) {
    return Schedule.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);
  }

  /// Create a copy with modified fields
  Schedule copyWith({
    String? id,
    String? facultyId,
    String? date,
    String? timeStart,
    String? timeEnd,
    String? type,
    String? title,
    String? location,
    String? status,
    String? cancellationReason,
    DateTime? createdAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      date: date ?? this.date,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      type: type ?? this.type,
      title: title ?? this.title,
      location: location ?? this.location,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Schedule(id: $id, facultyId: $facultyId, date: $date, timeStart: $timeStart, timeEnd: $timeEnd, type: $type, status: $status)';
  }
}
