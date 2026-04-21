import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:andfacconsult/models/department.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;

class FirestoreDepartmentService {
  // Use named database 'facconsult-firebase'
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  static const String _departmentCollection = 'departments';

  /// Fetch all departments
  Future<List<Department>> getAllDepartments() async {
    try {
      final querySnapshot =
          await _firestore.collection(_departmentCollection).get();
      final departmentList = querySnapshot.docs
          .map((doc) => Department.fromSnapshot(doc))
          .toList();
      logger_util.logInfo('Fetched ${departmentList.length} departments');
      return departmentList;
    } catch (e) {
      logger_util.logError('Error fetching departments: $e');
      rethrow;
    }
  }

  /// Fetch a single department by ID
  Future<Department?> getDepartmentById(String departmentId) async {
    try {
      final doc = await _firestore
          .collection(_departmentCollection)
          .doc(departmentId)
          .get();
      if (doc.exists) {
        final department = Department.fromSnapshot(doc);
        logger_util.logInfo('Fetched department: ${department.name}');
        return department;
      }
      logger_util.logInfo('Department $departmentId not found');
      return null;
    } catch (e) {
      logger_util.logError('Error fetching department by ID: $e');
      rethrow;
    }
  }

  /// Stream of all departments (for real-time updates)
  Stream<List<Department>> getDepartmentsStream() {
    return _firestore
        .collection(_departmentCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Department.fromSnapshot(doc))
          .toList();
    });
  }

  /// Get department name by ID (cached with basic Future)
  Future<String> getDepartmentName(String departmentId) async {
    try {
      final department = await getDepartmentById(departmentId);
      return department?.name ?? departmentId;
    } catch (e) {
      logger_util.logError('Error getting department name: $e');
      return departmentId;
    }
  }

  /// Add a new department
  Future<String> addDepartment(Department department) async {
    try {
      final docRef = await _firestore
          .collection(_departmentCollection)
          .add(department.toMap());
      logger_util.logInfo('Department added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger_util.logError('Error adding department: $e');
      rethrow;
    }
  }

  /// Update department information
  Future<void> updateDepartment(String departmentId, Department department) async {
    try {
      await _firestore
          .collection(_departmentCollection)
          .doc(departmentId)
          .update(department.toMap());
      logger_util.logInfo('Department $departmentId updated');
    } catch (e) {
      logger_util.logError('Error updating department: $e');
      rethrow;
    }
  }

  /// Delete a department
  Future<void> deleteDepartment(String departmentId) async {
    try {
      await _firestore.collection(_departmentCollection).doc(departmentId).delete();
      logger_util.logInfo('Department $departmentId deleted');
    } catch (e) {
      logger_util.logError('Error deleting department: $e');
      rethrow;
    }
  }
}
