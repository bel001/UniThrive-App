import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/models/project.dart';
import 'package:uni_thrive/models/schedule.dart';
import 'package:uni_thrive/services/voice_schedule_parser.dart';
import 'package:flutter/material.dart';

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

  test('soporta numeros hablados como palabras (ocho, diez, dos, cuatro)', () {
    final reference = DateTime(2026, 4, 20, 7, 0);
    final draft = parser.parse(
      'Tengo Calculo Integral los martes y jueves de ocho a diez de la manana en salon 201',
      referenceTime: reference,
    );

    expect(draft.title, 'Calculo Integral');
    expect(draft.weekDays, [DateTime.tuesday, DateTime.thursday]);
    expect(draft.firstStart.hour, 8);
    expect(draft.firstEnd.hour, 10);
    expect(draft.location, 'Salon 201');
  });

  test('soporta correcciones fuzzy de STT para dias mal pronunciados', () {
    final reference = DateTime(2026, 4, 20, 7, 0);
    final draft = parser.parse(
      'Clase de Programacion marque y juebes de las 2 a las 4 de la tarde',
      referenceTime: reference,
    );

    expect(draft.title, 'Programacion');
    expect(draft.weekDays, [DateTime.tuesday, DateTime.thursday]);
    expect(draft.firstStart.hour, 14);
    expect(draft.firstEnd.hour, 16);
  });

  test('parsea fecha especifica exacta con minutos y fraccion (jueves 27 de agosto a las 6 am a 8:30 pm)', () {
    final reference = DateTime(2026, 1, 1, 9, 0);
    final draft = parser.parse(
      'Tengo examen de Algebra el jueves 27 de agosto a las 6 de la manana hasta las 8:30 pm en aula B203',
      referenceTime: reference,
    );

    expect(draft.title, 'Algebra');
    expect(draft.location, 'Aula B203');
    expect(draft.isSingleEvent, true);
    expect(draft.firstStart, DateTime(2026, 8, 27, 6, 0));
    expect(draft.firstEnd, DateTime(2026, 8, 27, 20, 30));
  });

  test('parsea periodos academicos como hasta parciales o todo el semestre', () {
    final reference = DateTime(2026, 3, 1, 8, 0);
    final draftParciales = parser.parse(
      'Clase de Anatomia los lunes de 8 a 10 hasta parciales',
      referenceTime: reference,
    );
    expect(draftParciales.recurrenceEndDate, reference.add(const Duration(days: 56)));

    final draftSemestre = parser.parse(
      'Clase de Anatomia los lunes de 8 a 10 todo el semestre',
      referenceTime: reference,
    );
    expect(draftSemestre.recurrenceEndDate, reference.add(const Duration(days: 112)));
  });

  test('parsea ubicaciones virtuales como Zoom o Teams', () {
    final reference = DateTime(2026, 4, 20, 9, 0);
    final draft = parser.parse(
      'Seminario de Etica los viernes de 4 a 6 pm por Zoom',
      referenceTime: reference,
    );

    expect(draft.location, 'Por Zoom');
  });

  test('parsea dictado multiclase en lote (batch)', () {
    final reference = DateTime(2026, 4, 20, 7, 0);
    final drafts = parser.parseBatch(
      'Clase de Calculo lunes y miercoles de 8 a 10 am en B203; y los martes Fisica de 10 a 12 pm en C101',
      referenceTime: reference,
    );

    expect(drafts.length, 2);
    expect(drafts[0].title, 'Calculo');
    expect(drafts[0].weekDays, [DateTime.monday, DateTime.wednesday]);
    expect(drafts[1].title, 'Fisica');
    expect(drafts[1].weekDays, [DateTime.tuesday]);
  });

  test('detecta conflictos de horario con bloques existentes', () {
    final reference = DateTime(2026, 4, 20, 7, 0);
    final existingBlock = ScheduleBlock(
      id: 'existing-1',
      title: 'Quimica Existente',
      start: DateTime(2026, 4, 20, 8, 0),
      end: DateTime(2026, 4, 20, 10, 0),
      color: Colors.blue,
      category: ScheduleCategory.classSession,
    );

    final draft = parser.parse(
      'Clase de Calculo los lunes de 8 a 10 am',
      referenceTime: reference,
      existingBlocks: [existingBlock],
    );

    expect(draft.hasConflict, true);
    expect(draft.conflictMessage, contains('Quimica Existente'));
  });

  test('vincula automaticamente con proyectos existentes', () {
    final reference = DateTime(2026, 4, 20, 7, 0);
    final project = Project(
      id: 'proj-101',
      name: 'Fisica II',
      dueDate: DateTime(2026, 7, 1),
      color: Colors.teal,
    );

    final draft = parser.parse(
      'Clase de Fisica II los martes de 10 a 12',
      referenceTime: reference,
      existingProjects: [project],
    );

    expect(draft.linkedProjectId, 'proj-101');
  });
}
