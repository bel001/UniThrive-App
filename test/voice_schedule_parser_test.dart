import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/services/voice_schedule_parser.dart';

void main() {
  const parser = VoiceScheduleParser();

  test('parsea clase recurrente con varios dias, rango horario y aula', () {
    final reference = DateTime(2026, 4, 20, 7, 30);
    final draft = parser.parse(
      'Mi clase de Fisica 2 es lunes y miercoles de 8 a 10 am en aula B203 hasta julio',
      referenceTime: reference,
    );

    expect(draft.title, 'Fisica 2');
    expect(draft.location, 'Aula B203');
    expect(draft.weekDays, [DateTime.monday, DateTime.wednesday]);
    expect(draft.firstStart, DateTime(2026, 4, 20, 8));
    expect(draft.firstEnd, DateTime(2026, 4, 20, 10));
    expect(draft.recurrenceEndDate, DateTime(2026, 7, 31));
  });

  test('parsea rango de dias y asume tarde en horas cortas', () {
    final reference = DateTime(2026, 4, 21, 9, 0);
    final draft = parser.parse(
      'Agregar laboratorio de quimica de lunes a viernes de 2 a 4 en laboratorio 3',
      referenceTime: reference,
    );

    expect(draft.weekDays, [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ]);
    expect(draft.firstStart.hour, 14);
    expect(draft.firstEnd.hour, 16);
    expect(draft.location, 'Laboratorio 3');
  });

  test('cuando faltan dias y hora deja sugerencias editables', () {
    final reference = DateTime(2026, 4, 23, 11, 0);
    final draft = parser.parse(
      'Anota mi clase de historia del arte',
      referenceTime: reference,
    );

    expect(draft.title, 'Historia Del Arte');
    expect(draft.weekDays, [DateTime.thursday]);
    expect(draft.firstStart.hour, 9);
    expect(draft.firstEnd.hour, 11);
    expect(draft.notes, isNotEmpty);
  });
}
