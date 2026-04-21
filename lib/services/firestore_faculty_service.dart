import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:andfacconsult/models/faculty.dart';
import 'package:andfacconsult/services/firestore_department_service.dart';
import 'package:andfacconsult/utils/logger.dart' as logger_util;

class FirestoreFacultyService {
  // Use named database 'facconsult-firebase'
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  static const String _facultyCollection = 'faculty';

  /// Helper method to enrich faculty with department names
  Future<Faculty> _enrichFacultyWithDepartment(Faculty faculty) async {
    try {
      String? departmentName;
      if (faculty.departmentId.isNotEmpty) {
        departmentName = await _departmentService.getDepartmentName(faculty.departmentId);
      }
      return Faculty(
        id: faculty.id,
        firstName: faculty.firstName,
        lastName: faculty.lastName,
        email: faculty.email,
        departmentId: faculty.departmentId,
        departmentName: departmentName,
        availabilityStatus: faculty.availabilityStatus,
        profileImageUrl: faculty.profileImageUrl,
      );
    } catch (e) {
      logger_util.logError('Error enriching faculty data: $e');
      return faculty;
    }
  }

  /// Fetch all faculty members
  Future<List<Faculty>> getAllFaculty() async {
    try {
      final querySnapshot = await _firestore.collection(_facultyCollection).get();
      List<Faculty> facultyList = querySnapshot.docs
          .map((doc) => Faculty.fromSnapshot(doc))
          .toList();
      
      // Enrich with department names
      facultyList = await Future.wait(
        facultyList.map((faculty) => _enrichFacultyWithDepartment(faculty)),
      );
      
      logger_util.logInfo('Fetched ${facultyList.length} faculty members');
      return facultyList;
    } catch (e) {
      logger_util.logError('Error fetching faculty: $e');
      rethrow;
    }
  }

  /// Fetch faculty by department
  Future<List<Faculty>> getFacultyByDepartment(String departmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_facultyCollection)
          .where('department_id', isEqualTo: departmentId)
          .get();
      final facultyList = querySnapshot.docs
          .map((doc) => Faculty.fromSnapshot(doc))
          .toList();
      logger_util.logInfo('Fetched ${facultyList.length} faculty from department $departmentId');
      return facultyList;
    } catch (e) {
      logger_util.logError('Error fetching faculty by department: $e');
      rethrow;
    }
  }

  /// Fetch faculty by availability status
  Future<List<Faculty>> getFacultyByAvailability(String availabilityStatus) async {
    try {
      final querySnapshot = await _firestore
          .collection(_facultyCollection)
          .where('availability_status', isEqualTo: availabilityStatus)
          .get();
      final facultyList = querySnapshot.docs
          .map((doc) => Faculty.fromSnapshot(doc))
          .toList();
      logger_util.logInfo('Fetched ${facultyList.length} faculty with status $availabilityStatus');
      return facultyList;
    } catch (e) {
      logger_util.logError('Error fetching faculty by availability: $e');
      rethrow;
    }
  }

  /// Fetch faculty by ID
  Future<Faculty?> getFacultyById(String facultyId) async {
    try {
      final doc = await _firestore
          .collection(_facultyCollection)
          .doc(facultyId)
          .get();
      
      if (!doc.exists) {
        logger_util.logInfo('Faculty $facultyId not found');
        return null;
      }
      
      Faculty faculty = Faculty.fromSnapshot(doc);
      // Enrich with department name
      faculty = await _enrichFacultyWithDepartment(faculty);
      
      logger_util.logInfo('Fetched faculty: ${faculty.fullName}');
      return faculty;
    } catch (e) {
      logger_util.logError('Error fetching faculty by ID $facultyId: $e');
      return null;
    }
  }

  /// Stream of all faculty (for real-time updates)
  Stream<List<Faculty>> getFacultyStream() {
    return _firestore
        .collection(_facultyCollection)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Faculty> facultyList = snapshot.docs
          .map((doc) => Faculty.fromSnapshot(doc))
          .toList();
      
      // Enrich with department names
      facultyList = await Future.wait(
        facultyList.map((faculty) => _enrichFacultyWithDepartment(faculty)),
      );
      
      return facultyList;
    });
  }

  /// Add a new faculty member
  Future<String> addFaculty(Faculty faculty) async {
    try {
      final docRef = await _firestore
          .collection(_facultyCollection)
          .add(faculty.toMap());
      logger_util.logInfo('Faculty added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger_util.logError('Error adding faculty: $e');
      rethrow;
    }
  }

  /// Update faculty information
  Future<void> updateFaculty(String facultyId, Faculty faculty) async {
    try {
      await _firestore
          .collection(_facultyCollection)
          .doc(facultyId)
          .update(faculty.toMap());
      logger_util.logInfo('Faculty $facultyId updated');
    } catch (e) {
      logger_util.logError('Error updating faculty: $e');
      rethrow;
    }
  }

  /// Delete a faculty member
  Future<void> deleteFaculty(String facultyId) async {
    try {
      await _firestore.collection(_facultyCollection).doc(facultyId).delete();
      logger_util.logInfo('Faculty $facultyId deleted');
    } catch (e) {
      logger_util.logError('Error deleting faculty: $e');
      rethrow;
    }
  }
}
