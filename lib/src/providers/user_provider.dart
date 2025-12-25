import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Notifies listeners when the user's profile data (like role) changes.
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  Map<String, dynamic>? _userProfile;

  UserProvider(this._authService);

  // --- Public Getters ---

  /// Returns the raw map of the user's profile data.
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Returns the user's role (e.g., 'patient', 'staff', 'robot').
  String? get userRole => _userProfile?['role'] as String?;

  /// Returns the user's primary communication channel ID (e.g., 'room_401').
  String? get userChannelId => _userProfile?['channelId'] as String?;

  /// Returns the user's display name.
  String? get userName => _userProfile?['name'] as String?;

  /// Returns the user's email address.
  String? get userEmail => _userProfile?['email'] as String?;

  /// Returns the user's custom ID (e.g., 'PAT401_JohnSmith').
  String? get userCustomId => _userProfile?['customId'] as String?;

  // 🛑 REQUIRED FIX: ADD STAFF ID GETTER 🛑
  /// Returns the ID of the staff member assigned to this patient.
  /// NOTE: This assumes the user's Firestore profile contains a key named 'assignedStaffId'.
  String? get staffId => _userProfile?['assignedStaffId'] as String?;

  /// Checks if the profile data has been successfully loaded.
  bool get isProfileLoaded => _userProfile != null;

  // --- Helper Getter to derive room number from Channel ID ---
  String get roomNumber {
    final channelId = userChannelId;
    if (channelId != null && channelId.startsWith('room_')) {
      return channelId.split('_').last;
    }
    return 'N/A';
  }
  //

  // --- Core Methods ---

  /// Fetches the user profile from Firestore and updates the state.
  Future<void> loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null) {
      _userProfile = profile;
      notifyListeners();
      debugPrint('✅ User profile loaded for role: $userRole');
      // Added a debug print to confirm the new field is loaded
      debugPrint('✅ Assigned Staff ID: $staffId');
    } else {
      _userProfile = null;
      notifyListeners();
      debugPrint('⚠️ User profile not found in Firestore.');
    }
  }

  /// Clears the profile data on sign out.
  void clearProfile() {
    _userProfile = null;
    notifyListeners();
    debugPrint('Profile cleared on logout.');
  }
}