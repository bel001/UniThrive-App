import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_thrive/models/project.dart';
import 'package:uni_thrive/services/voice_ai_parse_service.dart';

void main() {
  test(
    'VoiceAiParseService convierte respuesta de tarea a draft usable',
    () async {
      final service = VoiceAiParseService(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://proxy.example.com/parse');
          expect(request.headers['Authorization'], 'Bearer proxy-token');
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['kind'], 'task');

          return http.Response(
            jsonEncode({
              'kind': 'task',
              'result': {
                'title': 'Resolver guía 4',
                'project_hint': 'Cálculo II',
                'matched_project_name': 'Cálculo II',
                'due_at': '2026-04-24T18:00:00',
                'due_date_was_inferred': false,
                'due_time_was_inferred': false,
                'notes': ['Fecha detectada desde el dictado.'],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final outcome = await service.enhanceTask(
        transcript:
            'Tarea de cálculo dos resolver guía 4 para el jueves a las 6',
        referenceTime: DateTime(2026, 4, 20, 14),
        activeProjects: [
          Project(
            id: 'p1',
            name: 'Cálculo II',
            dueDate: DateTime(2026, 7, 1),
            color: Colors.blue,
          ),
        ],
        endpointUrl: 'https://proxy.example.com/parse',
        proxyToken: 'proxy-token',
      );

      expect(outcome.hasDraft, isTrue);
      expect(outcome.warning, isNull);
      expect(outcome.draft!.title, 'Resolver guía 4');
      expect(outcome.draft!.matchedProjectName, 'Cálculo II');
      expect(outcome.draft!.dueDate, DateTime(2026, 4, 24, 18));
      expect(outcome.draft!.notes, isNotEmpty);
    },
  );

  test('VoiceAiParseService entrega warning si el proxy falla', () async {
    final service = VoiceAiParseService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Proxy fuera de línea'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final outcome = await service.enhanceSchedule(
      transcript: 'Mi clase de física es lunes y miércoles de 8 a 10',
      referenceTime: DateTime(2026, 4, 20, 9),
      endpointUrl: 'https://proxy.example.com/parse',
    );

    expect(outcome.hasDraft, isFalse);
    expect(outcome.warning, 'Proxy fuera de línea');
  });
}
