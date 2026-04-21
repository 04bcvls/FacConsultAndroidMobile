import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:andfacconsult/models/user.dart';
import 'package:andfacconsult/services/firebase_auth_service.dart';
import 'package:andfacconsult/utils/constants.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  // State variables
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize the controller and check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _errorMessage = null;
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Validate inputs
    if (!_validateEmail(email)) {
      _errorMessage = AppConstants.errorInvalidEmail;
      notifyListeners();
      return false;
    }

    if (!_validatePassword(password)) {
      _errorMessage = AppConstants.errorPasswordTooShort;
      notifyListeners();
      return false;
    }

    if (displayName.trim().isEmpty) {
      _errorMessage = "Display name cannot be empty";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _errorMessage = null;
      final user = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.trim().isEmpty) {
      _errorMessage = AppConstants.errorEmptyEmail;
      notifyListeners();
      return false;
    }

    if (password.trim().isEmpty) {
      _errorMessage = AppConstants.errorEmptyPassword;
      notifyListeners();
      return false;
    }

    if (!_validateEmail(email)) {
      _errorMessage = AppConstants.errorInvalidEmail;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      _errorMessage = null;
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in as Guest
  Future<bool> signInAsGuest() async {
    _setLoading(true);
    try {
      _errorMessage = null;
      final user = await _authService.signInAsGuest();
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<bool> signOut() async {
    _setLoading(true);
    try {
      _errorMessage = null;
      await _authService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload profile photo to Firebase Storage
  Future<String?> uploadProfilePhoto(File photoFile) async {
    _setLoading(true);
    try {
      _errorMessage = null;

      if (_currentUser?.uid == null) {
        _errorMessage = "User not authenticated";
        notifyListeners();
        return null;
      }

      // Generate storage path: users/{uid}/profile_photo.jpg
      final storageRef = FirebaseStorage.instance.ref();
      final photoRef =
          storageRef.child('users/${_currentUser!.uid}/profile_photo.jpg');

      // Upload file
      final uploadTask = photoRef.putFile(photoFile);
      await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await photoRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);
    try {
      _errorMessage = null;

      if (updatedUser.displayName.trim().isEmpty) {
        _errorMessage = "Display name cannot be empty";
        notifyListeners();
        return false;
      }

      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== Helper Methods ====================

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Validate email format
  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  /// Get user role
  String? getUserRole() {
    return _currentUser?.role;
  }

  /// Check if user is admin
  bool isUserAdmin() {
    return _currentUser?.role == AppConstants.roleAdmin;
  }

  /// Check if user is editor
  bool isUserEditor() {
    return _currentUser?.role == AppConstants.roleEditor;
  }

  /// Check if user is viewer
  bool isUserViewer() {
    return _currentUser?.role == AppConstants.roleViewer;
  }

  /// Check if user is student (ADDU Google account holder)
  bool isUserStudent() {
    return _currentUser?.role == AppConstants.roleStudent;
  }

  /// Check if user is guest
  bool isUserGuest() {
    return _currentUser?.role == AppConstants.roleGuest;
  }
}

String _cleanErrorMessage(String message) {
  if (message.startsWith('Exception: ')) {
    return message.replaceFirst('Exception: ', '');
  }
  return message;
}
