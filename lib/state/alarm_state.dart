import 'package:flutter/material.dart';

import '../models/alarm_schedule.dart';

class AlarmState extends ChangeNotifier {
  final List<AlarmSchedule> _alarms = [];
  final Map<String, List<int>> _nativeAlarmIdsByScheduleId = {};
  final Map<String, int> _snoozeCountsByOccurrence = {};

  List<AlarmSchedule> get alarms => List.unmodifiable(_alarms);
  Map<String, List<int>> get nativeAlarmIdsByScheduleId =>
      Map.unmodifiable(_nativeAlarmIdsByScheduleId);

  void loadFromMap(Map<String, dynamic> map) {
    _alarms
      ..clear()
      ..addAll(
        (map['alarms'] as List? ?? const []).whereType<Map>().map(
          (item) => AlarmSchedule.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        ),
      );

    _nativeAlarmIdsByScheduleId.clear();
    final rawNativeIds = map['nativeAlarmIdsByScheduleId'];
    if (rawNativeIds is Map) {
      rawNativeIds.forEach((key, value) {
        if (value is List) {
          _nativeAlarmIdsByScheduleId[key.toString()] = value
              .whereType<num>()
              .map((item) => item.toInt())
              .toList();
        }
      });
    }

    _snoozeCountsByOccurrence.clear();
    final rawSnoozes = map['snoozeCountsByOccurrence'];
    if (rawSnoozes is Map) {
      rawSnoozes.forEach((key, value) {
        if (value is num) {
          _snoozeCountsByOccurrence[key.toString()] = value.toInt();
        }
      });
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'alarms': _alarms.map((alarm) => alarm.toJson()).toList(),
    'nativeAlarmIdsByScheduleId': _nativeAlarmIdsByScheduleId,
    'snoozeCountsByOccurrence': _snoozeCountsByOccurrence,
  };

  void replaceNativeIds(Map<String, List<int>> nextIds) {
    _nativeAlarmIdsByScheduleId
      ..clear()
      ..addAll(
        nextIds.map(
          (key, value) => MapEntry(key, List<int>.unmodifiable(value)),
        ),
      );
    notifyListeners();
  }

  void addAlarm(AlarmSchedule alarm) {
    _alarms.add(alarm);
    notifyListeners();
  }

  void updateAlarm(AlarmSchedule alarm) {
    final index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) return;
    _alarms[index] = alarm;
    notifyListeners();
  }

  void deleteAlarm(String alarmId) {
    _alarms.removeWhere((alarm) => alarm.id == alarmId);
    _nativeAlarmIdsByScheduleId.remove(alarmId);
    _snoozeCountsByOccurrence.removeWhere(
      (key, _) => key.startsWith('$alarmId|'),
    );
    notifyListeners();
  }

  void clearAll() {
    _alarms.clear();
    _nativeAlarmIdsByScheduleId.clear();
    _snoozeCountsByOccurrence.clear();
    notifyListeners();
  }

  AlarmSchedule? alarmById(String alarmId) {
    try {
      return _alarms.firstWhere((alarm) => alarm.id == alarmId);
    } catch (_) {
      return null;
    }
  }

  int snoozeCount(String alarmId, DateTime occurrence) {
    return _snoozeCountsByOccurrence[_snoozeKey(alarmId, occurrence)] ?? 0;
  }

  bool registerSnooze(String alarmId, DateTime occurrence, int maxSnoozes) {
    final key = _snoozeKey(alarmId, occurrence);
    final current = _snoozeCountsByOccurrence[key] ?? 0;
    if (current >= maxSnoozes) return false;
    _snoozeCountsByOccurrence[key] = current + 1;
    notifyListeners();
    return true;
  }

  void resetSnoozes(String alarmId) {
    _snoozeCountsByOccurrence.removeWhere(
      (key, _) => key.startsWith('$alarmId|'),
    );
    notifyListeners();
  }

  static String _snoozeKey(String alarmId, DateTime occurrence) =>
      '$alarmId|${occurrence.toIso8601String()}';
}
