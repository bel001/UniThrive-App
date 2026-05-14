import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/alarm_schedule.dart';

class AlarmService {
  AlarmService._();

  static const _platform = MethodChannel('com.unithrive.app/alarm_clock');
  static const int planningWindowDays = 30;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Alarm.init();
      if (!kIsWeb && Platform.isAndroid) {
        await Alarm.setWarningNotificationOnKill(
          'UniThrive puede perder alarmas',
          'Abre la app para mantener tus despertadores sincronizados.',
        );
      }
      _initialized = true;
    } on MissingPluginException {
      _initialized = true;
    } catch (error) {
      debugPrint('Alarm initialization failed: $error');
      _initialized = true;
    }
  }

  static Future<bool> ensureExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) return false;
      final exactStatus = await Permission.scheduleExactAlarm.status;
      if (exactStatus.isGranted) return true;
      final requested = await Permission.scheduleExactAlarm.request();
      return requested.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, List<int>>> reconcile({
    required Iterable<AlarmSchedule> schedules,
    required Map<String, List<int>> previousNativeIds,
  }) async {
    await initialize();
    for (final ids in previousNativeIds.values.expand((ids) => ids)) {
      await _stopNativeAlarm(ids);
    }

    final nextIds = <String, List<int>>{};
    final now = DateTime.now();
    final windowEnd = now.add(const Duration(days: planningWindowDays));
    for (final schedule in schedules) {
      if (!schedule.enabled) continue;
      final occurrences = schedule.occurrencesBetween(now, windowEnd);
      for (final occurrence in occurrences) {
        final nativeId = nativeIdFor(schedule.id, occurrence);
        final set = await _setNativeAlarm(
          schedule: schedule,
          occurrence: occurrence,
          nativeId: nativeId,
        );
        if (set) {
          nextIds.putIfAbsent(schedule.id, () => <int>[]).add(nativeId);
        }
      }
    }
    return nextIds;
  }

  static Future<bool> scheduleSnooze({
    required AlarmSchedule schedule,
    required DateTime occurrence,
  }) async {
    await initialize();
    final snoozeAt = DateTime.now().add(
      Duration(minutes: schedule.snoozeMinutes),
    );
    return _setNativeAlarm(
      schedule: schedule,
      occurrence: snoozeAt,
      nativeId: nativeIdFor(schedule.id, snoozeAt, salt: 'snooze'),
      body: 'Pospuesta desde ${_timeLabel(occurrence)}.',
    );
  }

  static Future<void> stopSchedule(
    String scheduleId,
    Map<String, List<int>> nativeIdsByScheduleId,
  ) async {
    await initialize();
    final ids = nativeIdsByScheduleId[scheduleId] ?? const <int>[];
    for (final id in ids) {
      await _stopNativeAlarm(id);
    }
  }

  static Future<bool> stopNativeId(int id) async {
    await initialize();
    return _stopNativeAlarm(id);
  }

  static Future<bool> openSystemAlarmClock({
    String? title,
    int? hour,
    int? minute,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _platform.invokeMethod<bool>('openAlarmClock', {
            if (title != null) 'title': title,
            if (hour != null) 'hour': hour,
            if (minute != null) 'minute': minute,
          }) ??
          false;
    } catch (error) {
      debugPrint('Could not open system alarm clock: $error');
      return false;
    }
  }

  static int nativeIdFor(
    String scheduleId,
    DateTime occurrence, {
    String salt = '',
  }) {
    final key = '$scheduleId|${occurrence.toIso8601String()}|$salt';
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static Future<bool> _setNativeAlarm({
    required AlarmSchedule schedule,
    required DateTime occurrence,
    required int nativeId,
    String? body,
  }) async {
    if (!occurrence.isAfter(DateTime.now())) return false;
    try {
      return await Alarm.set(
        alarmSettings: AlarmSettings(
          id: nativeId,
          dateTime: occurrence,
          assetAudioPath: schedule.soundAssetPath,
          loopAudio: true,
          vibrate: schedule.vibrate,
          warningNotificationOnKill: !kIsWeb && Platform.isIOS,
          androidFullScreenIntent: true,
          androidStopAlarmOnTermination: false,
          volumeSettings: VolumeSettings.fade(
            volume: 0.85,
            fadeDuration: const Duration(seconds: 8),
          ),
          notificationSettings: NotificationSettings(
            title: schedule.title,
            body: body ?? 'Alarma programada para ${_timeLabel(occurrence)}.',
            stopButton: 'Detener',
          ),
          payload: schedule.id,
        ),
      );
    } catch (error) {
      debugPrint('Could not schedule alarm ${schedule.id}: $error');
      return false;
    }
  }

  static Future<bool> _stopNativeAlarm(int id) async {
    try {
      return await Alarm.stop(id);
    } catch (_) {
      return false;
    }
  }

  static String _timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
