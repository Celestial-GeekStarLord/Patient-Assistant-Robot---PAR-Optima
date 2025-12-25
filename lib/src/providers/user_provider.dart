import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Notifies listeners when the user's profile data (like role) changes.
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  Map<String, dynamic>? _userProfile;

  UserProvider(this._authService);

  Map<String, dynamic>? get userProfile => _userProfile;
  String? get userRole => _userProfile?['role'] as String?;
  String? get userChannelId => _userProfile?['channelId'] as String?;

  bool get isProfileLoaded => _userProfile != null;

  /// Fetches the user profile from Firestore and updates the state.
  Future<void> loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (profile != null) {
      _userProfile = profile;
      notifyListeners();
    }
  }

  /// Clears the profile data on sign out.
  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}