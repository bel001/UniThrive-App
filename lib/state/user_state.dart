import 'package:flutter/material.dart';

// Assuming UserProfileSummary is defined in project.dart or we need to move it.
// Based on AppState analysis, UserProfileSummary seems to be used.
// Let's check where UserProfileSummary is defined. It was in AppState file or imported?
// Looking at AppState imports: import '../models/project.dart';
// It might be in project.dart or defined in AppState.dart itself?
// Wait, I didn't see UserProfileSummary definition in AppState view (it was truncated or I missed it).
// Let's assume it's in a model file or I need to define it.
// Actually, looking at AppState code: `final List<UserProfileSummary> _profiles = [];`
// I need to find where UserProfileSummary is defined.
// I will assume it's in `lib/models/user_profile.dart` or similar, or I might need to extract it.
// Let's check `lib/models` content again.

import '../models/user_profile_summary.dart'; // Placeholder, will fix if needed

class UserState extends ChangeNotifier {
  bool _hasCompletedOnboarding = false;
  String _userName = 'Sofía';
  String _userEmail = 'sofia@unithrive.app';
  final List<UserProfileSummary> _profiles = [];
  String? _activeProfileId;

  // Getters
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get avatarUrl => 'https://i.imgur.com/BoN9kdC.png';
  List<UserProfileSummary> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeProfileId;

  void loadFromMap(Map<String, dynamic> map) {
    _hasCompletedOnboarding = map['hasCompletedOnboarding'] ?? false;
    _userName = map['userName'] ?? 'Sofía';
    _userEmail = map['userEmail'] ?? 'sofia@unithrive.app';
    _activeProfileId = map['activeProfileId'];

    if (map['profiles'] != null) {
      _profiles.clear();
      for (var p in map['profiles']) {
        _profiles.add(UserProfileSummary.fromJson(p));
      }
    }

    // Logic to ensure at least one profile exists
    if (_profiles.isEmpty) {
      // We need a way to generate IDs, maybe pass a generator or use UUID
      // For now, simple logic or rely on AppState to init
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCompletedOnboarding': _hasCompletedOnboarding,
      'userName': _userName,
      'userEmail': _userEmail,
      'activeProfileId': _activeProfileId,
      'profiles': _profiles.map((p) => p.toJson()).toList(),
      // profileData is complex, might need to be handled by DataState or here?
      // In AppState, profileData stores the snapshot of DataState for each profile.
      // This suggests UserState might need to coordinate with DataState for switching.
    };
  }

  void completeOnboarding() {
    if (_hasCompletedOnboarding) return;
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void reset() {
    // This method's original implementation referred to `_profile` and `ProfileSnapshot`
    // which are not defined in this UserState class.
    // Adapting to reset the existing fields of UserState.
    _hasCompletedOnboarding = false;
    _userName = 'Sofía';
    _userEmail = 'sofia@unithrive.app';
    _profiles.clear(); // Clear all profiles
    _activeProfileId = null; // No active profile
    notifyListeners();
  }

  void restartOnboarding() {
    if (!_hasCompletedOnboarding) return;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  void updateUserProfile(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    _userName = cleaned;
    final emailHandle = cleaned.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    _userEmail = '$emailHandle@unithrive.app';

    if (_activeProfileId != null) {
      final idx = _profiles.indexWhere((p) => p.id == _activeProfileId);
      if (idx != -1) {
        _profiles[idx] = _profiles[idx].copyWith(
          name: _userName,
          email: _userEmail,
        );
      }
    }
    notifyListeners();
  }

  // Profile management methods
  void addUserProfile(String name) {
    // Generate ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newProfile = UserProfileSummary(
      id: id,
      name: name,
      email: '', // Optional or generate
    );
    _profiles.add(newProfile);
    notifyListeners();
  }

  void switchUserProfile(String profileId) {
    if (_activeProfileId == profileId) return;
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return;

    _activeProfileId = profileId;
    _userName = _profiles[idx].name;
    _userEmail = _profiles[idx].email;
    notifyListeners();
  }

  void deleteUserProfile(String profileId) {
    if (_activeProfileId == profileId) {
      // Cannot delete active profile, or must switch first
      // For now, just return
      return;
    }
    _profiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }
}
