import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _motivationalMessages = true;
  bool _classRemindersEnabled = true;
  bool _taskRemindersEnabled = true;
  int _reminderLeadMinutes = 15;
  double _textScale = 1.0;
  String _alarmSound = 'Clásico';

  ThemeMode get themeMode => _themeMode;
  bool get motivationalMessages => _motivationalMessages;
  bool get classRemindersEnabled => _classRemindersEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  int get reminderLeadMinutes => _reminderLeadMinutes;
  double get textScale => _textScale;
  String get alarmSound => _alarmSound;

  void loadFromMap(Map<String, dynamic> map) {
    if (map['themeMode'] != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeMode.light,
      );
    }
    _motivationalMessages = map['motivationalMessages'] ?? true;
    _classRemindersEnabled = map['classRemindersEnabled'] ?? true;
    _taskRemindersEnabled = map['taskRemindersEnabled'] ?? true;
    _reminderLeadMinutes = map['reminderLeadMinutes'] ?? 15;
    _textScale = (map['textScale'] as num?)?.toDouble() ?? 1.0;
    _alarmSound = map['alarmSound'] ?? 'Clásico';
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': _themeMode.name,
      'motivationalMessages': _motivationalMessages,
      'classRemindersEnabled': _classRemindersEnabled,
      'taskRemindersEnabled': _taskRemindersEnabled,
      'reminderLeadMinutes': _reminderLeadMinutes,
      'textScale': _textScale,
      'alarmSound': _alarmSound,
    };
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleMotivationMessages() {
    _motivationalMessages = !_motivationalMessages;
    notifyListeners();
  }

  void setMotivationalMessages(bool enabled) {
    _motivationalMessages = enabled;
    notifyListeners();
  }

  void reset() {
    _themeMode = ThemeMode.system;
    _textScale = 1.0;
    _taskRemindersEnabled = true;
    _classRemindersEnabled = true;
    _motivationalMessages = true;
    notifyListeners();
  }

  void setClassReminders(bool value) {
    _classRemindersEnabled = value;
    notifyListeners();
  }

  void setTaskReminders(bool value) {
    _taskRemindersEnabled = value;
    notifyListeners();
  }

  void setReminderLeadMinutes(int minutes) {
    final normalized = minutes.clamp(5, 120);
    if (_reminderLeadMinutes == normalized) return;
    _reminderLeadMinutes = normalized;
    NotificationService.setDefaultLeadMinutes(_reminderLeadMinutes);
    notifyListeners();
  }

  void setTextScale(double scale) {
    final normalized = scale.clamp(1.0, 1.3);
    if ((normalized - _textScale).abs() < 0.01) return;
    _textScale = normalized;
    notifyListeners();
  }

  void setAlarmSound(String sound) {
    if (_alarmSound == sound) return;
    _alarmSound = sound;
    notifyListeners();
  }
}
