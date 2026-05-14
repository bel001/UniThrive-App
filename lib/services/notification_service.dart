import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Random _rand = Random();
  static int _defaultLeadMinutes = 15;
  static const List<String> _motivationPool = [
    'Respira hondo, cada pequeño avance cuenta.',
    'Tu yo del futuro te agradecerá este esfuerzo.',
    'La constancia gana a la motivación. Sigue así.',
    'Tienes todo para lograrlo, da el siguiente paso.',
  ];
  static const String _streakKey = 'streak_soft';

  static Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestProvisionalPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
    _initialized = true;
  }

  static NotificationDetails get _notificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'unithrive_reminders',
          'Recordatorios UniThrive',
          channelDescription: 'Notificaciones para tareas rápidas y horario',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      );

  static void setDefaultLeadMinutes(int minutes) {
    _defaultLeadMinutes = minutes.clamp(5, 120);
  }

  static int get defaultLeadMinutes => _defaultLeadMinutes;

  static Duration get _leadDuration => Duration(minutes: _defaultLeadMinutes);

  static int _idFromKey(String key) => key.hashCode & 0x7fffffff;

  static Future<bool> ensurePermissions() async {
    if (!_initialized) await initialize();
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted =
          await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          ) ??
          false;
      return granted;
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
      try {
        final exactStatus = await Permission.scheduleExactAlarm.status;
        if (!exactStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (_) {
        // ignored on unsupported versions
      }
      return true;
    }
    return true;
  }

  static Future<void> openSystemNotificationSettings() async {
    await openAppSettings();
  }

  static Future<void> scheduleQuickTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    final reminderTime = dueDate.subtract(_leadDuration);
    if (reminderTime.isBefore(DateTime.now())) return;
    await _scheduleReminder(
      key: 'task_$taskId',
      title: 'Tarea rápida',
      body: 'Te toca "$title" en 10 minutos',
      scheduledDate: reminderTime,
    );
  }

  static Future<void> scheduleScheduleReminder(ScheduleBlock block) async {
    final reminderTime = block.start.subtract(_leadDuration);
    if (reminderTime.isBefore(DateTime.now())) return;
    await cancelReminder('schedule_${block.id}');
    final startTime =
        '${block.start.hour.toString().padLeft(2, '0')}:${block.start.minute.toString().padLeft(2, '0')}';
    await _scheduleReminder(
      key: 'schedule_${block.id}',
      title: 'Próxima clase',
      body:
          '${block.title} inicia a las $startTime${block.location.isEmpty ? '' : ' · ${block.location}'}',
      scheduledDate: reminderTime,
    );
  }

  static Future<void> cancelReminder(String key) async {
    if (!_initialized) return;
    await _plugin.cancel(_idFromKey(key));
  }

  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
    int? customMinutes, // null = use global default
    String? contextLabel,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final minutesToUse = customMinutes ?? _defaultLeadMinutes;
    final reminderTime = dueDate.subtract(Duration(minutes: minutesToUse));
    if (reminderTime.isBefore(DateTime.now())) return;
    final urgency = switch (priority) {
      TaskPriority.urgent => 'Urgente',
      TaskPriority.high => 'Alta prioridad',
      TaskPriority.medium => 'Pendiente',
      TaskPriority.low => 'Pendiente',
    };
    final dueTime =
        '${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    final context = contextLabel == null || contextLabel.trim().isEmpty
        ? ''
        : ' · ${contextLabel.trim()}';
    await _scheduleReminder(
      key: 'task_regular_$taskId',
      title: '$urgency$context',
      body: '"$title" vence a las $dueTime · en $minutesToUse min',
      scheduledDate: reminderTime,
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    await cancelReminder('task_regular_$taskId');
  }

  static Future<void> sendMotivationMessage([String? custom]) async {
    if (!_initialized) return;
    final body =
        custom ?? _motivationPool[_rand.nextInt(_motivationPool.length)];
    await _plugin.show(
      _idFromKey('motivation_${DateTime.now().millisecondsSinceEpoch}'),
      'Sigue avanzando 💜',
      body,
      _notificationDetails,
    );
  }

  static Future<void> scheduleStreakReminder(DateTime when) async {
    if (!_initialized) return;
    if (when.isBefore(DateTime.now())) return;
    await cancelReminder(_streakKey);
    await _scheduleReminder(
      key: _streakKey,
      title: 'No pierdas tu racha',
      body: 'Te quedan 10 minutos para mantener tu racha activa.',
      scheduledDate: when,
    );
  }

  static Future<void> _scheduleReminder({
    required String key,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) return;
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    Future<void> attempt(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        _idFromKey(key),
        title,
        body,
        tzDate,
        _notificationDetails,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    try {
      await attempt(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (error) {
      if (error.code == 'exact_alarms_not_permitted') {
        await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
      } else {
        debugPrint('Notification scheduling failed ($key): ${error.message}');
      }
    } catch (error) {
      debugPrint('Notification scheduling failed ($key): $error');
    }
  }
}
