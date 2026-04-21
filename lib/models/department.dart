import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  final String id;
  final String name;
  final String? description;
  final String? email;
  final String? phone;

  Department({
    required this.id,
    required this.name,
    this.description,
    this.email,
    this.phone,
  });

  /// Convert Department to Map (for Firebase Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
    };
  }

  /// Create Department from Firebase Firestore Map
  factory Department.fromMap(String id, Map<String, dynamic> map) {
    return Department(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      email: map['email'],
      phone: map['phone'],
    );
  }

  /// Create Department from Firestore Document Snapshot
  factory Department.fromSnapshot(DocumentSnapshot snapshot) {
    return Department.fromMap(snapshot.id, snapshot.data() as Map<String, dynamic>);
  }
}
