import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andfacconsult/models/user.dart';
import 'package:andfacconsult/utils/constants.dart';
import 'package:andfacconsult/utils/logger.dart';
import 'package:andfacconsult/utils/device_identifier.dart';

class FirebaseAuthService {
  // Firebase instances
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  // Use named database 'facconsult-firebase'
  late final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  /// Sign in with Google (ADDU Mail only)
  Future<User> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Google Sign-In was cancelled");
      }

      // Validate that email is from ADDU domain
      final userEmail = googleUser.email;
      if (!_isValidADDUEmail(userEmail)) {
        // Sign out the user if they're not from ADDU
        await _googleSignIn.signOut();
        throw Exception(AppConstants.errorUnauthorizedEmail);
      }

      // Get authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

      // Sign in to Firebase with credential
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final googleUserEmail = googleUser.email;

      // Check if user already exists by email in Firestore (prevents duplicates)
      final existingUserByEmail = await _getUserByEmail(googleUserEmail);
      if (existingUserByEmail != null && existingUserByEmail.uid != userCredential.user!.uid) {
        logInfo('User with email $googleUserEmail already exists with different UID. Merging accounts.');
        // Delete the new duplicate UID document
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .delete();
        
        // Update the existing user's login method and role
        var updatedUser = existingUserByEmail.copyWith(
          loginMethod: AppConstants.loginMethodGoogle,
          photoUrl: userCredential.user!.photoURL,
        );
        if (updatedUser.role == AppConstants.roleAdmin || updatedUser.role == AppConstants.roleViewer) {
          updatedUser = updatedUser.copyWith(role: AppConstants.roleStudent);
          await updateUserRole(updatedUser.uid, AppConstants.roleStudent);
        }
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(existingUserByEmail.uid)
            .update({
              'login_method': AppConstants.loginMethodGoogle,
              'profile_image_url': userCredential.user!.photoURL,
            });
        return updatedUser;
      }

      // Check if user already exists by UID and convert admin/viewer role to student
      try {
        final existingUser = await _getUserFromFirestore(userCredential.user!.uid);
        if (existingUser.role == AppConstants.roleAdmin) {
          logInfo('Admin user ${existingUser.uid} logging in with Google through mobile app, converting to student role');
          await updateUserRole(existingUser.uid, AppConstants.roleStudent);
          return existingUser.copyWith(role: AppConstants.roleStudent);
        }
        if (existingUser.role == AppConstants.roleViewer) {
          logInfo('Viewer user ${existingUser.uid} logging in with Google, converting to student role');
          await updateUserRole(existingUser.uid, AppConstants.roleStudent);
          return existingUser.copyWith(role: AppConstants.roleStudent);
        }
        return existingUser;
      } catch (e) {
        // If user doesn't exist in Firestore, that's ok, continue with new user creation
        if (!e.toString().contains("User not found")) {
          rethrow;
        }
      }

      // Create User object from Firebase user
      final User user = User(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: userCredential.user!.displayName ?? 'Google User',
        photoUrl: userCredential.user!.photoURL,
        role: AppConstants.roleStudent, // ADDU students
        loginMethod: AppConstants.loginMethodGoogle,
        createdAt: DateTime.now(),
      );

      // Save user to Firestore
      await _createUserInFirestore(user);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      logError('Firebase Google Sign-In Error', e, stackTrace);
      throw Exception("Google Sign-In failed. Please try again.");
    }
  }

  /// Validate if email is from allowed ADDU domains
  bool _isValidADDUEmail(String email) {
    for (String domain in AppConstants.allowedEmailDomains) {
      if (email.toLowerCase().endsWith(domain)) {
        logInfo('Valid ADDU email: $email');
        return true;
      }
    }
    logWarning('Invalid email domain attempted: $email');
    return false;
  }

  /// Sign up with email and password
  Future<User> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        throw Exception("Email, password, and display name cannot be empty");
      }

      if (password.length < 6) {
        throw Exception("Password must be at least 6 characters");
      }

      // Check if user with this email already exists in Firestore
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        logInfo('User with email $email already exists (UID: ${existingUser.uid}), updating their account');
        // Update their existing Firestore account with new display name and convert role to student
        var updatedUser = existingUser.copyWith(
          displayName: displayName,
          loginMethod: AppConstants.loginMethodEmail,
        );
        if (updatedUser.role == AppConstants.roleAdmin || updatedUser.role == AppConstants.roleViewer) {
          updatedUser = updatedUser.copyWith(role: AppConstants.roleStudent);
          await updateUserRole(updatedUser.uid, AppConstants.roleStudent);
        }
        // Update the display name in Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(updatedUser.uid)
            .update({
              'display_name': displayName,
              'login_method': AppConstants.loginMethodEmail,
            });
        return updatedUser;
      }

      // Create user with Firebase Auth
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update user profile with display name
      await userCredential.user!.updateDisplayName(displayName);

      // Create User object
      final User user = User(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: null,
        role: AppConstants.roleStudent, // Email/password users are students
        loginMethod: AppConstants.loginMethodEmail,
        createdAt: DateTime.now(),
      );

      // Save user to Firestore
      await _createUserInFirestore(user);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      logError('Firebase Sign-Up Error', e, stackTrace);
      logWarning('Error Code: ${e.code}');
      throw Exception("Sign-up failed. Please check your information and try again.");
    }
  }

  /// Sign in with email and password
  Future<User> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email and password cannot be empty");
      }

      // Sign in with Firebase Auth
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if this email exists in faculty collection
      final facultyData = await _getFacultyByEmailWithId(email);
      if (facultyData != null) {
        // Faculty member logging in - create User object from faculty data (no users collection record needed)
        logInfo('Faculty member $email logging in');
        final facultyFirstName = facultyData['first_name'] ?? '';
        final facultyLastName = facultyData['last_name'] ?? '';
        final facultyFullName = '$facultyFirstName $facultyLastName'.trim();
        final facultyId = facultyData['_docId'] as String?;
        
        final user = User(
          uid: userCredential.user!.uid,
          email: email,
          displayName: facultyFullName.isNotEmpty ? facultyFullName : 'Faculty Member',
          photoUrl: null,
          role: AppConstants.roleStudent,
          loginMethod: AppConstants.loginMethodEmail,
          createdAt: DateTime.now(),
          facultyId: facultyId,
        );
        
        logInfo('Faculty $email authenticated as student role with facultyId: $facultyId');
        return user;
      }

      // Not a faculty member - try to get from users collection (normal student)
      User? user;
      try {
        user = await _getUserFromFirestore(userCredential.user!.uid);
      } catch (e) {
        // User not found, create new student account
        logInfo('Creating new student account for $email');
        user = User(
          uid: userCredential.user!.uid,
          email: email,
          displayName: userCredential.user!.displayName ?? 'Student',
          photoUrl: null,
          role: AppConstants.roleStudent,
          loginMethod: AppConstants.loginMethodEmail,
          createdAt: DateTime.now(),
        );
        
        // Save to Firestore
        await _createUserInFirestore(user);
      }

      // Convert admin role to student role for mobile app access
      if (user.role == AppConstants.roleAdmin) {
        logInfo('Admin user ${user.uid} logging in through mobile app, converting to student role');
        await updateUserRole(user.uid, AppConstants.roleStudent);
        user = user.copyWith(role: AppConstants.roleStudent);
      }

      // Migrate old email/password users from "viewer" to "student" role
      if (user.role == AppConstants.roleViewer && 
          user.loginMethod == AppConstants.loginMethodEmail) {
        logInfo('Migrating email user ${user.uid} from viewer to student role');
        await updateUserRole(user.uid, AppConstants.roleStudent);
        user = user.copyWith(role: AppConstants.roleStudent);
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      logError('Firebase Sign-In Error', e, stackTrace);
      logWarning('Error Code: ${e.code}');
      throw Exception(
        "Sign-in failed: Invalid email or password. Please try again.",
      );
    }
  }

  /// Sign in as Guest (Anonymous) - maintains identity per device
  Future<User> signInAsGuest() async {
    try {
      // Get unique device ID for this device
      final deviceId = await DeviceIdentifier.getDeviceId();
      
      // Check if guest user already exists for this device
      final existingGuest = await _getExistingGuestUser(deviceId);
      if (existingGuest != null) {
        logInfo('Returning existing guest user for device');
        return existingGuest;
      }

      // Sign in anonymously with Firebase Auth
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInAnonymously();

      // Create User object for guest with device ID
      final User user = User(
        uid: userCredential.user!.uid,
        email: "guest@anonymous.com",
        displayName: "Guest User",
        photoUrl: null,
        role: AppConstants.roleGuest, // Guest users cannot book
        loginMethod: AppConstants.loginMethodGuest,
        createdAt: DateTime.now(),
        deviceId: deviceId,
      );

      // Save guest user to Firestore
      await _createUserInFirestore(user);

      logInfo('Created new guest user with device ID: ${deviceId.substring(0, 8)}...');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      logError('Firebase Guest Sign-In Error', e);
      throw Exception("Guest Sign-In failed: ${e.message}");
    }
  }

  /// Get existing guest user for this device
  Future<User?> _getExistingGuestUser(String deviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('deviceId', isEqualTo: deviceId)
          .where('loginMethod', isEqualTo: AppConstants.loginMethodGuest)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return User.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e, stackTrace) {
      logError('Error getting existing guest user', e, stackTrace);
      return null;
    }
  }

  /// Get user by email from Firestore
  Future<User?> _getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return User.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      // Permission denied errors are expected during certain auth flows (e.g., logout, unauthenticated queries)
      if (!e.toString().contains('permission-denied')) {
        logError('Error getting user by email: $e');
      }
      return null;
    }
  }

  /// Get faculty by email from Firestore (to get correct faculty name)
  Future<Map<String, dynamic>?> _getFacultyByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.facultyCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      logError('Error getting faculty by email: $e');
      return null;
    }
  }

  /// Get faculty by email with document ID from Firestore
  Future<Map<String, dynamic>?> _getFacultyByEmailWithId(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.facultyCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['_docId'] = querySnapshot.docs.first.id; // Add document ID
        return data;
      }
      return null;
    } catch (e) {
      logError('Error getting faculty by email with ID: $e');
      return null;
    }
  }

  /// Create user in Firestore
  Future<void> _createUserInFirestore(User user) async {
    try {
      // Check if user already exists by UID
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        // Also check if user with same email already exists to prevent duplicates
        final existingByEmail = await _getUserByEmail(user.email);
        if (existingByEmail != null && existingByEmail.uid != user.uid) {
          logWarning('User with email ${user.email} already exists with different UID. Skipping duplicate creation.');
          return;
        }

        // Create new user document
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toMap());
      }
    } catch (e) {
      throw Exception("Failed to create user in Firestore: $e");
    }
  }

  /// Get user from Firestore
  Future<User> _getUserFromFirestore(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        return User.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        throw Exception("User not found in Firestore");
      }
    } catch (e) {
      throw Exception("Failed to get user from Firestore: $e");
    }
  }

  /// Get current logged-in user
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      final email = firebaseUser.email ?? '';

      // Check if this email exists in faculty collection first
      final facultyData = await _getFacultyByEmailWithId(email);
      if (facultyData != null) {
        // Faculty member - create User object from faculty data (no users collection record needed)
        logInfo('Faculty member $email detected, loading from faculty collection');
        final facultyFirstName = facultyData['first_name'] ?? '';
        final facultyLastName = facultyData['last_name'] ?? '';
        final facultyFullName = '$facultyFirstName $facultyLastName'.trim();
        final facultyId = facultyData['_docId'] as String?;
        
        return User(
          uid: firebaseUser.uid,
          email: email,
          displayName: facultyFullName.isNotEmpty ? facultyFullName : 'Faculty Member',
          photoUrl: null,
          role: AppConstants.roleStudent,
          loginMethod: AppConstants.loginMethodEmail,
          createdAt: DateTime.now(),
          facultyId: facultyId,
        );
      }

      // Not a faculty member - try to get from users collection
      User? user;
      try {
        user = await _getUserFromFirestore(firebaseUser.uid);
      } catch (e) {
        // User not found anywhere
        logWarning('User not found in either faculty or users collection');
        return null;
      }

      // Convert admin role to student role for mobile app access
      if (user.role == AppConstants.roleAdmin) {
        logInfo('Admin user ${user.uid} detected, converting to student role');
        await updateUserRole(user.uid, AppConstants.roleStudent);
        user = user.copyWith(role: AppConstants.roleStudent);
      }
      
      // Convert viewer role to student role
      if (user.role == AppConstants.roleViewer) {
        logInfo('Viewer user ${user.uid} detected, converting to student role');
        await updateUserRole(user.uid, AppConstants.roleStudent);
        user = user.copyWith(role: AppConstants.roleStudent);
      }

      return user;
    } catch (e, stackTrace) {
      logError('Error getting current user', e, stackTrace);
      return null;
    }
  }

  /// Update user role (Admin function)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {AppConstants.fieldRole: newRole},
      );
    } catch (e) {
      throw Exception("Failed to update user role: $e");
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _firebaseAuth.signOut();

      // Sign out from Google Sign-In if applicable
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception("Sign-out failed: $e");
    }
  }

  /// Update user profile (displayName)
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        throw Exception("No user is currently logged in");
      }

      // Update display name in Firebase Auth
      if (updatedUser.displayName != firebaseUser.displayName) {
        await firebaseUser.updateDisplayName(updatedUser.displayName);
      }

      // Update user profile in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .update(
            {
              'displayName': updatedUser.displayName,
              'photoUrl': updatedUser.photoUrl,
            },
          );

      logInfo('User profile updated successfully for ${firebaseUser.uid}');
    } on firebase_auth.FirebaseAuthException catch (e, stackTrace) {
      logError('Firebase Auth Error updating profile', e, stackTrace);
      throw Exception("Failed to update profile: ${e.message}");
    } catch (e, stackTrace) {
      logError('Error updating user profile', e, stackTrace);
      throw Exception("Failed to update profile: $e");
    }
  }

  /// Check if user is authenticated
  bool isUserAuthenticated() {
    return _firebaseAuth.currentUser != null;
  }

  /// Get current Firebase user UID
  String? getCurrentUserUID() {
    return _firebaseAuth.currentUser?.uid;
  }
}
