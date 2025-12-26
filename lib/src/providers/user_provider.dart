// lib/src/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
// 🛑 NEW IMPORT: Import the centralized model 🛑
import '../models/patient_record.dart'; // ASSUMING PATH IS CORRECT

// 🛑 REMOVED: The entire local PatientRecord class definition was here.

/// Notifies listeners when the user's profile data (like role) changes.
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  Map<String, dynamic>? _userProfile;

  // 🛑 NEW STATE VARIABLES FOR STAFF DASHBOARD 🛑
  // These now correctly reference the imported PatientRecord type.
  List<PatientRecord> _patientList = [];
  bool _isPatientListLoading = false;
  String? _patientListError;

  UserProvider(this._authService);

  // --- Public Getters (Existing) ---

  Map<String, dynamic>? get userProfile => _userProfile;

  String? get userRole => _userProfile?['role'] as String?;

  String? get userChannelId => _userProfile?['channelId'] as String?;

  String? get userName => _userProfile?['name'] as String?;

  String? get userEmail => _userProfile?['email'] as String?;

  String? get userCustomId => _userProfile?['customId'] as String?;

  String? get staffId => _userProfile?['assignedStaffId'] as String?;

  bool get isProfileLoaded => _userProfile != null;

  String get roomNumber {
    final channelId = userChannelId;
    if (channelId != null && channelId.startsWith('room_')) {
      return channelId.split('_').last;
    }
    return 'N/A';
  }

  // 🛑 NEW PUBLIC GETTERS FOR PATIENT LIST 🛑
  List<PatientRecord> get patientList => _patientList;
  bool get isPatientListLoading => _isPatientListLoading;
  String? get patientListError => _patientListError;

  // --- Core Methods (Existing) ---

  Future<void> loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null) {
      _userProfile = profile;
      notifyListeners();
      debugPrint('✅ User profile loaded for role: $userRole');
      debugPrint('✅ Assigned Staff ID: $staffId');
    } else {
      _userProfile = null;
      notifyListeners();
      debugPrint('⚠️ User profile not found in Firestore.');
    }
  }

  void clearProfile() {
    _userProfile = null;
    _patientList = [];
    notifyListeners();
    debugPrint('Profile cleared on logout.');
  }

  // 🛑 NEW CORE METHOD: LOGOUT 🛑
  /// Signs the user out of the authentication service and clears the local profile state.
  Future<void> logout() async {
    try {
      // 1. Sign out from the underlying authentication service (e.g., Firebase Auth)
      await _authService.signOut();
      debugPrint('✅ User signed out successfully from Auth service.');
    } catch (e) {
      debugPrint('⚠️ Error during AuthService sign out: $e');
      // Continue to clear local state even if auth sign-out fails, to prevent
      // an infinite loop or stale UI, but log the error.
    }

    // 2. Clear all local state variables
    clearProfile();
    // Note: clearProfile already calls notifyListeners()
  }


  // --- FETCH ALL PATIENT RECORDS FOR STAFF DASHBOARD ---

  /// Fetches all records from the 'users' collection where role is 'patient'.
  Future<void> fetchPatientList() async {
    _isPatientListLoading = true;
    _patientListError = null;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
      // 🛑 FIX APPLIED HERE: Changed 'Patient' to 'patient' 🛑
          .where('role', isEqualTo: 'patient')
          .get();

      final List<PatientRecord> fetchedPatients = [];

      for (var doc in querySnapshot.docs) {
        // Factory constructor is called here, using the imported PatientRecord
        final record = PatientRecord.fromFirestore(doc);

        if (record.channelId != 'N/A') {
          fetchedPatients.add(record);
        }
      }

      _patientList = fetchedPatients;
      _isPatientListLoading = false;
      debugPrint('✅ Fetched ${_patientList.length} patient records.');

    } on FirebaseException catch (e) {
      debugPrint('Firestore Error fetching patient list: ${e.message}');
      _patientListError = "Failed to load patient data: ${e.code}.";
      _isPatientListLoading = false;
    } catch (e) {
      debugPrint('General Error fetching patient list: $e');
      _patientListError = "An unexpected error occurred.";
      _isPatientListLoading = false;
    }

    notifyListeners();
  }
}