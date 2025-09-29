import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/nickname_validation_service.dart';

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  final DatabaseService _dbService = DatabaseService();
  final NicknameValidationService _nicknameService =
      NicknameValidationService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((firebase_auth.User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // Try to find user by UID first (for existing users)
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('firebaseUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        _currentUser =
            User.fromMap(query.docs.first.data() as Map<String, dynamic>);
      } else {
        // Fallback to direct UID lookup for backward compatibility
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists) {
          _currentUser = User.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail(
      String email, String password, String name, String nickname) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final user = User(
          id: credential.user!.uid,
          email: email,
          name: name,
          nickname: nickname,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );

        await _dbService.createUser(user);
        _currentUser = user;
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Comprehensive registration method with mobile as document ID
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String mobile,
    String? nickname,
    String? dateOfBirth,
    String? gender,
    String? address,
  }) async {
    try {
      debugPrint('Starting registration for: $email, mobile: $mobile');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Clean the mobile number for consistent use (remove spaces and special chars except +)
      final cleanMobile = mobile.replaceAll(RegExp(r'[^\d+]'), '');
      debugPrint('Clean mobile: $cleanMobile');

      // Create Firebase Auth user first
      debugPrint('Creating Firebase Auth user...');

      // Check if Firebase is properly initialized
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized!');
        _errorMessage = 'Firebase not initialized';
        return false;
      }

      debugPrint('Firebase apps: ${Firebase.apps.length}');
      debugPrint('Attempting to create user with email: $email');

      final credential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Firebase Auth timeout!');
          throw Exception(
              'Registration timed out. Please check your internet connection and try again.');
        },
      );
      debugPrint('Firebase Auth user created: ${credential.user?.uid}');

      if (credential.user == null) {
        debugPrint('Credential user is null');
        _errorMessage = 'Failed to create user account';
        return false;
      }

      // Now that we have an authenticated user, we can write to Firestore
      // Check if mobile number already exists (now with authenticated user)
      debugPrint('Checking if mobile number exists...');
      DocumentSnapshot mobileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanMobile)
          .get();

      if (mobileDoc.exists) {
        debugPrint('Mobile number already exists, deleting auth user...');
        // Delete the Firebase Auth user since we can't use this mobile
        await credential.user!.delete();
        _errorMessage = 'Mobile number already registered';
        return false;
      }
      debugPrint('Mobile number is available');

      // Validate and check nickname availability
      debugPrint('Validating nickname...');
      if (nickname == null || nickname.trim().isEmpty) {
        debugPrint('Nickname is required, deleting auth user...');
        await credential.user!.delete();
        _errorMessage = 'Nickname is required for registration';
        return false;
      }

      // Validate nickname format
      final formatValidation =
          _nicknameService.validateNicknameFormat(nickname);
      if (!formatValidation['isValid']) {
        debugPrint('Invalid nickname format, deleting auth user...');
        await credential.user!.delete();
        _errorMessage = formatValidation['error'];
        return false;
      }

      // Check if nickname is available (with enhanced error handling)
      debugPrint('Checking if nickname is available...');
      try {
        // Direct Firestore check with proper error handling
        final nicknameQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('nickname', isEqualTo: nickname.toLowerCase())
            .limit(1)
            .get();

        if (nicknameQuery.docs.isNotEmpty) {
          debugPrint('Nickname already taken, deleting auth user...');
          await credential.user!.delete();
          _errorMessage =
              'Nickname "$nickname" is already taken. Please choose a different one.';
          return false;
        }
        debugPrint('Nickname is available');
      } catch (nicknameCheckError) {
        debugPrint(
            'Error checking nickname availability during registration: $nicknameCheckError');
        // If we can't check nickname availability, we'll proceed but log the issue
        // The nickname validation will happen when we try to create the user document
        debugPrint(
            'Proceeding with registration - will validate nickname on document creation');
      }

      // Send email verification
      debugPrint('Sending email verification...');
      await credential.user!.sendEmailVerification();
      debugPrint('Email verification sent');

      // Create user document in Firestore with mobile as document ID
      debugPrint('Creating user object...');
      final user = User(
        id: cleanMobile, // Using clean mobile as document ID
        firebaseUid: credential.user!.uid, // Store Firebase UID separately
        email: email,
        name: name,
        nickname: nickname, // User model will handle lowercase storage
        phoneNumber: cleanMobile,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isEmailVerified: false,
      );
      debugPrint('User object created, converting to map...');

      // Save to Firestore using clean mobile as document ID
      final userMap = user.toMap();
      debugPrint('User map created successfully');
      debugPrint('User map keys: ${userMap.keys}');
      debugPrint(
          'User map has null values: ${userMap.values.where((v) => v == null).length} null values');

      debugPrint('Saving to Firestore...');
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cleanMobile)
            .set(userMap);
        debugPrint('User saved to Firestore successfully');
      } catch (firestoreError) {
        debugPrint('Error saving user to Firestore: $firestoreError');
        // If there's an error saving to Firestore, clean up the Firebase Auth user
        await credential.user!.delete();

        if (firestoreError.toString().contains('already exists') ||
            firestoreError.toString().contains('nickname')) {
          _errorMessage =
              'This nickname is already taken. Please choose a different one.';
        } else {
          _errorMessage = 'Failed to create user account. Please try again.';
        }
        return false;
      }

      _currentUser = user;
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      _errorMessage = _getFirebaseErrorMessage(e.code);
      return false;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Exception: ${e.code} - ${e.message}');
      _errorMessage = 'Database error: ${e.message}';
      return false;
    } catch (e) {
      debugPrint('Registration error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out';
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? nickname,
    String? status,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        nickname: nickname ?? _currentUser!.nickname,
        status: status ?? _currentUser!.status,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );

      await _dbService.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Email verification methods
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('Verification email sent to ${user.email}');
      }
    } catch (e) {
      _errorMessage = 'Failed to send verification email: $e';
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final isVerified = user.emailVerified;

        // Update user document with email verification status
        if (_currentUser != null &&
            isVerified != _currentUser!.isEmailVerified) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.id)
              .update({'isEmailVerified': isVerified});

          _currentUser = _currentUser!.copyWith(isEmailVerified: isVerified);
          notifyListeners();
        }

        return isVerified;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Password reset methods
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      _errorMessage = _getFirebaseErrorMessage(e.code);
      return false;
    } catch (e) {
      debugPrint('Password reset error: $e');
      _errorMessage = 'Failed to send password reset email. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'auth/user-not-found':
        return 'No account found with this email address.';
      case 'auth/invalid-email':
        return 'Please enter a valid email address.';
      case 'auth/missing-email':
        return 'Email address is required.';
      case 'auth/quota-exceeded':
        return 'Password reset limit exceeded. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if a nickname is available for registration
  Future<bool> checkNicknameAvailability(String nickname) async {
    try {
      return await _nicknameService.isNicknameAvailable(nickname);
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      return false;
    }
  }

  /// Validate nickname format and return validation result
  Map<String, dynamic> validateNicknameFormat(String nickname) {
    return _nicknameService.validateNicknameFormat(nickname);
  }

  /// Generate professional nickname suggestions
  Future<List<String>> generateNicknameSuggestions(String baseNickname,
      {String? fullName}) async {
    try {
      return await _nicknameService.generateNicknameSuggestions(baseNickname,
          fullName: fullName);
    } catch (e) {
      debugPrint('Error generating nickname suggestions: $e');
      return [];
    }
  }

  /// Get instant nickname suggestions as user types
  Future<List<String>> getInstantNicknameSuggestions(String partialNickname,
      {String? fullName}) async {
    try {
      return await _nicknameService.getInstantSuggestions(partialNickname,
          fullName: fullName);
    } catch (e) {
      debugPrint('Error getting instant suggestions: $e');
      return [];
    }
  }

  /// Find similar existing nicknames to warn user
  Future<List<String>> findSimilarNicknames(String nickname) async {
    try {
      return await _nicknameService.findSimilarNicknames(nickname);
    } catch (e) {
      debugPrint('Error finding similar nicknames: $e');
      return [];
    }
  }
}
