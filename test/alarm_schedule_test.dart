import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/models/alarm_schedule.dart';
import 'package:uni_thrive/services/alarm_service.dart';

void main() {
  test('serializa y restaura una alarma semanal avanzada', () {
    final alarm = AlarmSchedule(
      id: 'alarm-1',
      title: 'Clase temprana',
      hour: 6,
      minute: 30,
      repeatType: AlarmRepeatType.weekly,
      weekDays: const [DateTime.monday, DateTime.wednesday],
      startDate: DateTime(2026, 5, 4),
      endDate: DateTime(2026, 6, 1),
      skippedDateKeys: const ['2026-05-06'],
      snoozeMinutes: 15,
      maxSnoozes: 2,
      vibrate: false,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 2),
    );

    final restored = AlarmSchedule.fromJson(alarm.toJson());

    expect(restored.title, alarm.title);
    expect(restored.repeatType, AlarmRepeatType.weekly);
    expect(restored.weekDays, [DateTime.monday, DateTime.wednesday]);
    expect(restored.skippedDateKeys, ['2026-05-06']);
    expect(restored.snoozeMinutes, 15);
    expect(restored.vibrate, isFalse);
  });

  test('calcula ocurrencias respetando dias, rango y excepciones', () {
    final alarm = AlarmSchedule(
      id: 'alarm-2',
      title: 'Levantarse',
      hour: 7,
      minute: 0,
      repeatType: AlarmRepeatType.weekly,
      weekDays: const [DateTime.monday, DateTime.wednesday],
      startDate: DateTime(2026, 5, 4),
      endDate: DateTime(2026, 5, 13),
      skippedDateKeys: const ['2026-05-06'],
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

    final occurrences = alarm.occurrencesBetween(
      DateTime(2026, 5, 3),
      DateTime(2026, 5, 20),
    );

    expect(occurrences, [
      DateTime(2026, 5, 4, 7),
      DateTime(2026, 5, 11, 7),
      DateTime(2026, 5, 13, 7),
    ]);
  });

  test('genera ids nativos estables por ocurrencia', () {
    final occurrence = DateTime(2026, 5, 4, 7);

    expect(
      AlarmService.nativeIdFor('alarm-3', occurrence),
      AlarmService.nativeIdFor('alarm-3', occurrence),
    );
    expect(
      AlarmService.nativeIdFor('alarm-3', occurrence),
      isNot(
        AlarmService.nativeIdFor(
          'alarm-3',
          occurrence.add(const Duration(days: 1)),
        ),
      ),
    );
  });
}
