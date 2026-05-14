import 'package:flutter/material.dart';

import '../models/user_profile_summary.dart';

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
    _profiles.clear();
    _hasCompletedOnboarding = map['hasCompletedOnboarding'] as bool? ?? false;
    _userName = map['userName'] as String? ?? 'Sofía';
    _userEmail = map['userEmail'] as String? ?? 'sofia@unithrive.app';
    _activeProfileId = map['activeProfileId'];

    if (map['profiles'] != null) {
      for (var p in map['profiles']) {
        _profiles.add(UserProfileSummary.fromJson(p));
      }
    }

    _ensureDefaultProfile();
    _syncIdentityFromActiveProfile();
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'hasCompletedOnboarding': _hasCompletedOnboarding,
      'userName': _userName,
      'userEmail': _userEmail,
      'activeProfileId': _activeProfileId,
      'profiles': _profiles.map((p) => p.toJson()).toList(),
    };
  }

  void completeOnboarding() {
    if (_hasCompletedOnboarding) return;
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void reset() {
    _hasCompletedOnboarding = false;
    _userName = 'Sofía';
    _userEmail = 'sofia@unithrive.app';
    _profiles
      ..clear()
      ..add(_buildProfile(name: _userName, email: _userEmail));
    _activeProfileId = _profiles.first.id;
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
    _userEmail = _buildEmail(cleaned);

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

  UserProfileSummary addUserProfile(String name) {
    final cleaned = name.trim().isEmpty ? 'Nuevo perfil' : name.trim();
    final newProfile = _buildProfile(
      name: cleaned,
      email: _buildEmail(cleaned),
    );
    _profiles.add(newProfile);
    notifyListeners();
    return newProfile;
  }

  bool switchUserProfile(String profileId) {
    if (_activeProfileId == profileId) return true;
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx == -1) return false;

    _activeProfileId = profileId;
    _userName = _profiles[idx].name;
    _userEmail = _profiles[idx].email;
    notifyListeners();
    return true;
  }

  bool deleteUserProfile(String profileId) {
    if (_activeProfileId == profileId || _profiles.length <= 1) return false;
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) return false;
    _profiles.removeAt(index);
    notifyListeners();
    return true;
  }

  void setOnboardingState(bool value) {
    if (_hasCompletedOnboarding == value) return;
    _hasCompletedOnboarding = value;
    notifyListeners();
  }

  void ensureDefaultProfile() {
    _ensureDefaultProfile();
    _syncIdentityFromActiveProfile();
    notifyListeners();
  }

  void _ensureDefaultProfile() {
    if (_profiles.isEmpty) {
      _profiles.add(_buildProfile(name: _userName, email: _userEmail));
    }
    final hasActiveProfile =
        _activeProfileId != null &&
        _profiles.any((profile) => profile.id == _activeProfileId);
    if (!hasActiveProfile) {
      _activeProfileId = _profiles.first.id;
    }
  }

  void _syncIdentityFromActiveProfile() {
    final active = _profiles.cast<UserProfileSummary?>().firstWhere(
      (profile) => profile?.id == _activeProfileId,
      orElse: () => _profiles.isNotEmpty ? _profiles.first : null,
    );
    if (active == null) return;
    _activeProfileId = active.id;
    _userName = active.name;
    _userEmail = active.email;
  }

  UserProfileSummary _buildProfile({
    required String name,
    required String email,
  }) {
    return UserProfileSummary(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      email: email,
    );
  }

  String _buildEmail(String name) {
    final emailHandle = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${emailHandle.isEmpty ? 'perfil' : emailHandle}@unithrive.app';
  }
}
