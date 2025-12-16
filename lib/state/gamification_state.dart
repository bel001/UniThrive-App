import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/mascot_state.dart';
import '../services/mascot_service.dart';

class GamificationState extends ChangeNotifier {
  int _experiencePoints = 0;
  int _level = 1;
  final List<Achievement> _achievements = [];
  MascotState _mascotState = MascotState(
    mood: MascotMood.happy,
    message: '',
    timestamp: DateTime.now(),
  );
  final MascotService _mascotService = MascotService();
  int _streakDays = 0;
  int _pomodoroStreakDays = 0;
  DateTime? _lastActiveDay;
  DateTime? _lastPomodoroDay;

  // Getters
  int get experiencePoints => _experiencePoints;
  int get level => _level;
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  MascotState get mascotState => _mascotState;
  int get streakDays => _streakDays;
  int get pomodoroStreakDays => _pomodoroStreakDays;

  int get xpForNextLevel => _level * 100;
  int get xpProgressInCurrentLevel => _experiencePoints % xpForNextLevel;
  double get xpProgressPercent =>
      (xpProgressInCurrentLevel / xpForNextLevel * 100).clamp(0, 100);

  void loadFromMap(Map<String, dynamic> map) {
    _experiencePoints = map['experiencePoints'] ?? 0;
    _level = map['level'] ?? 1;
    _streakDays = map['streakDays'] ?? 0;
    _pomodoroStreakDays = map['pomodoroStreakDays'] ?? 0;

    if (map['lastActiveDay'] != null) {
      _lastActiveDay = DateTime.parse(map['lastActiveDay']);
    }
    if (map['lastPomodoroDay'] != null) {
      _lastPomodoroDay = DateTime.parse(map['lastPomodoroDay']);
    }

    if (map['achievements'] != null) {
      _achievements.clear();
      for (var a in map['achievements']) {
        _achievements.add(Achievement.fromJson(a));
      }
    }

    if (map['mascotState'] != null) {
      _mascotState = MascotState.fromJson(map['mascotState']);
    }

    _initializeAchievements();
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'experiencePoints': _experiencePoints,
      'level': _level,
      'streakDays': _streakDays,
      'pomodoroStreakDays': _pomodoroStreakDays,
      'lastActiveDay': _lastActiveDay?.toIso8601String(),
      'lastPomodoroDay': _lastPomodoroDay?.toIso8601String(),
      'achievements': _achievements.map((a) => a.toJson()).toList(),
      'mascotState': _mascotState.toJson(),
    };
  }

  void _initializeAchievements() {
    if (_achievements.isEmpty) {
      _achievements.addAll(PredefinedAchievements.all);
    } else {
      final existingIds = _achievements.map((a) => a.id).toSet();
      for (final newAch in PredefinedAchievements.all) {
        if (!existingIds.contains(newAch.id)) {
          _achievements.add(newAch);
        }
      }
    }
  }

  void addXP(int amount, {String? reason, bool skipAchievementCheck = false}) {
    _experiencePoints += amount;
    final oldLevel = _level;
    _level = (_experiencePoints ~/ 100) + 1;

    if (_level > oldLevel) {
      _mascotState = _mascotService.onLevelUp(_level);
      _mascotService.updateState(_mascotState);
    }

    notifyListeners();
  }

  void updateMascotMood(MascotState newState) {
    _mascotState = newState;
    _mascotService.updateState(newState);
    notifyListeners();
  }

  // Achievement checking logic will need access to DataState (tasks, projects).
  // This might be better handled in a coordinator or by passing stats to this method.
  void checkAchievements({
    required int completedTasks,
    required int completedProjects,
    required int totalFocusMinutes,
  }) {
    // Logic to check achievements based on passed stats
    // ... (Logic from AppState._checkAchievements adapted)
  }

  void unlockAchievement(String achievementId) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1 || _achievements[index].unlocked) return;

    _achievements[index] = _achievements[index].copyWith(
      unlocked: true,
      unlockedAt: DateTime.now(),
    );

    addXP(
      _achievements[index].xpReward,
      reason: 'Achievement unlocked',
      skipAchievementCheck: true,
    );

    _mascotState = _mascotService.onAchievementUnlocked(
      _achievements[index].title,
    );
    _mascotService.updateState(_mascotState);
    notifyListeners();
  }

  void reset() {
    _experiencePoints = 0;
    _level = 1;
    _achievements.clear();
    _initializeAchievements();
    _mascotState = MascotState(
      mood: MascotMood.happy,
      message: '',
      timestamp: DateTime.now(),
    );
    _streakDays = 0;
    _pomodoroStreakDays = 0;
    _lastActiveDay = null;
    _lastPomodoroDay = null;
    notifyListeners();
  }
}
