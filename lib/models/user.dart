import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // "viewer", "editor", "admin"
  final String loginMethod; // "google", "email", "guest"
  final DateTime createdAt;
  final String? deviceId; // Device ID for guest users to maintain identity
  final String? facultyId; // Reference to faculty document if user is faculty member

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = "viewer", // Default role
    required this.loginMethod,
    required this.createdAt,
    this.deviceId,
    this.facultyId,
  });

  /// Convert User to Map (for Firebase Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'loginMethod': loginMethod,
      'createdAt': createdAt,
      'deviceId': deviceId,
      'facultyId': facultyId,
    };
  }

  /// Create User from Firebase Firestore Map
  factory User.fromMap(Map<String, dynamic> map) {
    // Handle DateTime/Timestamp conversion from Firestore
    DateTime createdAtDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        // Firestore Timestamp object
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        // String timestamp
        createdAtDate = DateTime.parse(map['createdAt'] as String);
      } else if (map['createdAt'] is DateTime) {
        // Already a DateTime
        createdAtDate = map['createdAt'] as DateTime;
      }
    }

    return User(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? "viewer",
      loginMethod: map['loginMethod'] as String,
      createdAt: createdAtDate,
      deviceId: map['deviceId'] as String?,
      facultyId: map['facultyId'] as String?,
    );
  }

  /// Create a copy of User with modified fields
  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    String? loginMethod,
    DateTime? createdAt,
    String? deviceId,
    String? facultyId,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      loginMethod: loginMethod ?? this.loginMethod,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
      facultyId: facultyId ?? this.facultyId,
    );
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, displayName: $displayName, role: $role, loginMethod: $loginMethod)';
  }
}
