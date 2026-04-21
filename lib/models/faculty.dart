import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String departmentId;
  final String? departmentName;
  final String availabilityStatus;
  final String? profileImageUrl;

  Faculty({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.departmentId,
    this.departmentName,
    required this.availabilityStatus,
    this.profileImageUrl,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Convert Faculty to Map (for Firebase Firestore)
  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'department_id': departmentId,
      'availability_status': availabilityStatus,
      'profile_image_url': profileImageUrl,
    };
  }

  /// Create Faculty from Firebase Firestore Map
  factory Faculty.fromMap(String id, Map<String, dynamic> map,
      {String? departmentName}) {
    return Faculty(
      id: id,
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      departmentId: map['department_id'] ?? '',
      departmentName: departmentName,
      availabilityStatus: map['availability_status'] ?? 'offline',
      profileImageUrl: map['profile_image_url'],
    );
  }

  /// Create Faculty from Firestore Document Snapshot
  factory Faculty.fromSnapshot(DocumentSnapshot snapshot,
      {String? departmentName}) {
    return Faculty.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>,
        departmentName: departmentName);
  }
}
