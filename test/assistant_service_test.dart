import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/services/assistant_service.dart';

void main() {
  final lunes = DateTime(2026, 9, 7, 10);

  group('AssistantService.splitSegments', () {
    test('separa varias cosas unidas con además', () {
      final parts = AssistantService.splitSegments(
        'Tengo clase de física los lunes de 8 a 10, además entregar el informe mañana',
      );
      expect(parts.length, 2);
    });

    test('separa con también y luego', () {
      final parts = AssistantService.splitSegments(
        'Clase de matemática los martes de 9 a 11 también comprar cuadernos luego llamar al tutor',
      );
      expect(parts.length, 3);
    });

    test('texto vacío no da segmentos', () {
      expect(AssistantService.splitSegments('   '), isEmpty);
    });
  });

  group('AssistantService.classifySegment', () {
    test('detecta clase por palabras de horario', () {
      expect(
        AssistantService.classifySegment(
          'Clase de física los lunes de 8 a 10 en el aula B203',
        ),
        AssistantCandidateKind.classBlock,
      );
    });

    test('lo demás es tarea', () {
      expect(
        AssistantService.classifySegment('Comprar pan mañana'),
        AssistantCandidateKind.task,
      );
      expect(
        AssistantService.classifySegment('Tengo examen de química el viernes'),
        AssistantCandidateKind.task,
      );
    });
  });

  group('AssistantService.parseText', () {
    test('un turno con clase y tarea da una candidata de cada tipo', () {
      final candidates = AssistantService.parseText(
        'Tengo clase de física los lunes de 8 a 10 en el aula B203, además entregar el informe mañana a las 6 de la tarde',
        referenceTime: lunes,
      );
      expect(candidates.length, 2);

      final clase = candidates.firstWhere((c) => !c.isTask);
      expect(clase.title.toLowerCase(), contains('fisica'));
      expect(clase.scheduleDraft!.weekDays, contains(DateTime.monday));

      final tarea = candidates.firstWhere((c) => c.isTask);
      expect(tarea.title.toLowerCase(), contains('informe'));
      expect(tarea.taskDraft!.dueDateWasInferred, isFalse);
    });

    test('cada turno nuevo suma candidatas (conversación intercalada)', () {
      final primero = AssistantService.parseText(
        'Clase de matemática los miércoles de 9 a 11',
        referenceTime: lunes,
      );
      final despues = AssistantService.parseText(
        'Ah, y también estudiar inglés el jueves',
        referenceTime: lunes,
      );
      final todas = [...primero, ...despues];
      expect(todas.where((c) => !c.isTask), hasLength(1));
      expect(todas.where((c) => c.isTask), hasLength(1));
    });

    test('texto tipo foto de horario da clases', () {
      final candidates = AssistantService.parseText(
        'Lunes: matemática de 8 a 10 en aula 201; Miércoles: física de 9 a 11 en laboratorio 3',
        referenceTime: lunes,
      );
      expect(candidates, isNotEmpty);
      expect(candidates.every((c) => !c.isTask), isTrue);
    });

    test('texto vacío no da candidatas', () {
      expect(
        AssistantService.parseText('  ', referenceTime: lunes),
        isEmpty,
      );
    });
  });
}
