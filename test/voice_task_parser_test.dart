import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/models/project.dart';
import 'package:uni_thrive/services/voice_task_parser.dart';

void main() {
  const parser = VoiceTaskParser();

  test('parsea tarea con curso existente y fecha relativa', () {
    final referenceTime = DateTime(2026, 4, 19, 15, 0);
    final draft = parser.parse(
      'Agrega tarea de Calculo: resolver guia 4 para el jueves a las 6 pm',
      referenceTime: referenceTime,
      projects: [
        Project(
          id: '1',
          name: 'Calculo',
          dueDate: DateTime(2026, 7, 30),
          color: Color(0xFF7DB8A4),
        ),
      ],
    );

    expect(draft.title, 'Resolver guia 4');
    expect(draft.matchedProjectName, 'Calculo');
    expect(draft.dueDate.year, 2026);
    expect(draft.dueDate.month, 4);
    expect(draft.dueDate.day, 23);
    expect(draft.dueDate.hour, 18);
  });

  test('cuando falta fecha deja una sugerida y avisa', () {
    final referenceTime = DateTime(2026, 4, 19, 10, 0);
    final draft = parser.parse(
      'Anota tarea de Historia: leer el capitulo 3',
      referenceTime: referenceTime,
    );

    expect(draft.title, 'Leer el capitulo 3');
    expect(draft.dueDate.year, 2026);
    expect(draft.dueDate.month, 4);
    expect(draft.dueDate.day, 20);
    expect(draft.dueDate.hour, 18);
    expect(draft.notes, isNotEmpty);
  });

  test('extrae curso sugerido cuando no existe proyecto previo', () {
    final referenceTime = DateTime(2026, 4, 19, 9, 0);
    final draft = parser.parse(
      'Crear tarea del curso Fisica 2: hacer laboratorio para mañana',
      referenceTime: referenceTime,
    );

    expect(draft.projectHint, 'Fisica 2');
    expect(draft.matchedProjectName, isNull);
    expect(draft.title, 'Hacer laboratorio');
    expect(draft.dueDate.day, 20);
  });
}
