// lib/src/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Used for @required/debugPrint

/// A service class to handle all Firebase Authentication and
/// Firestore user profile management.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- PASSWORD VALIDATION HELPER (Must be STATIC) ---

  /// Validates a password string against secure complexity requirements.
  /// Returns null if valid, or a String error message if invalid.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit.';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }
    return null; // Password is valid
  }

  // --- HELPER: ROLE & CHANNEL DETERMINATION ---

  /// Determines the user's role and their default channel ID based on the custom ID prefix.
  // ... (Your existing _determineRoleAndChannel method is here)
  Map<String, String> _determineRoleAndChannel(String customId) {
    final upperId = customId.toUpperCase();
    String role;
    String channelId;

    if (upperId.startsWith('PAT')) {
      role = 'patient';
      // Extracts the number part (e.g., '402' from PAT402_JohnSmith)
      final roomNumber = upperId.substring(3).split('_').first;
      channelId = 'room_$roomNumber';
    } else if (upperId.startsWith('STF')) {
      role = 'staff';
      // Staff often joins rooms on demand, but needs a default/home base for signaling.
      channelId = 'room_staff_default';
    } else if (upperId.startsWith('RBT')) {
      role = 'robot';
      // Extracts the number part (e.g., '402' from RBT402)
      final roomNumber = upperId.substring(3).split('_').first;
      channelId = 'room_$roomNumber';
    } else {
      throw ArgumentError(
        'Invalid User ID prefix. Must start with PAT, STF, or RBT.',
      );
    }

    debugPrint('User Role determined: $role, Channel: $channelId');
    return {'role': role, 'channelId': channelId};
  }

  // --- AUTHENTICATION METHODS ---

  /// Registers a new user with Firebase Auth and creates their profile in Firestore.
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String customId,
  }) async {
    try {
      // **CRITICAL STEP:** Perform client-side validation first
      final passwordError = AuthService.validatePassword(password);
      if (passwordError != null) {
        // Wrap error in ArgumentError so it's caught cleanly in the UI
        throw ArgumentError(passwordError);
      }

      // 1. Determine Role and Channel ID based on Custom ID
      final roleData = _determineRoleAndChannel(customId);
      final role = roleData['role']!;
      final channelId = roleData['channelId']!;

      // 2. Create User in Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // 3. Create User Profile in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role,
          'channelId': channelId, // The user's default room ID
          'isHost': role == 'staff', // Staff is usually the host/initiator
          'isOnline': true,
          'customId': customId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return user;
      }
      return null;

    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors (e.g., email-already-in-use, weak-password)
      throw Exception(e.message ?? 'Authentication failed during sign-up.');
    } catch (e) {
      // Handle validation (e.g., ArgumentError from _determineRoleAndChannel or validatePassword) or Firestore errors
      throw Exception('Sign-up failed: $e');
    }
  }

  /// Signs in an existing user using only email and password.
  // ... (Your existing signIn method)
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update online status in Firestore upon successful login
      final uid = userCredential.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({'isOnline': true});
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors (e.g., user-not-found, wrong-password)
      throw Exception(e.message ?? 'Sign in failed.');
    }
  }

  /// Signs out the current user and updates their online status in Firestore.
  // ... (Your existing signOut method)
  Future<void> signOut() async {
    // Update Firestore to set isOnline: false BEFORE signing out of Auth
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({'isOnline': false});
      } catch (e) {
        debugPrint('Warning: Could not update online status for $uid: $e');
        // Continue to sign out even if update fails
      }
    }
    await _auth.signOut();
  }

  /// Gets the full user profile data from Firestore for the currently logged-in user.
  // ... (Your existing getCurrentUserProfile method)
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Stream of the current Firebase User, useful for handling auth state changes (login/logout).
  // ... (Your existing authStateChanges stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}