import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/project.dart';
import '../models/voice_schedule_draft.dart';
import '../models/voice_task_draft.dart';

class VoiceAiParseOutcome<T> {
  final T? draft;
  final String? warning;

  const VoiceAiParseOutcome({this.draft, this.warning});

  bool get hasDraft => draft != null;
}

class VoiceAiParseService {
  VoiceAiParseService({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      timeout = timeout ?? const Duration(seconds: 12);

  static final VoiceAiParseService instance = VoiceAiParseService();

  final http.Client _client;
  final Duration timeout;

  Future<VoiceAiParseOutcome<VoiceTaskDraft>> enhanceTask({
    required String transcript,
    required DateTime referenceTime,
    required Iterable<Project> activeProjects,
    required String endpointUrl,
    String? proxyToken,
  }) async {
    final normalizedTranscript = transcript.trim();
    if (normalizedTranscript.isEmpty) {
      return const VoiceAiParseOutcome(
        warning: 'No había suficiente texto para mejorar el dictado.',
      );
    }

    final responseMap = await _postParseRequest(
      endpointUrl: endpointUrl,
      proxyToken: proxyToken,
      payload: {
        'kind': 'task',
        'transcript': normalizedTranscript,
        'reference_time': referenceTime.toIso8601String(),
        'context': {
          'active_project_names': activeProjects
              .where((project) => !project.completed && !project.hidden)
              .map((project) => project.name)
              .toList(),
        },
      },
    );
    if (responseMap.warning != null) {
      return VoiceAiParseOutcome(warning: responseMap.warning);
    }

    try {
      final draft = _taskDraftFromMap(
        responseMap.result!,
        transcript: normalizedTranscript,
        activeProjects: activeProjects,
      );
      if (draft == null) {
        return const VoiceAiParseOutcome(
          warning: 'El endpoint IA respondió, pero faltaron datos clave.',
        );
      }
      return VoiceAiParseOutcome(draft: draft);
    } catch (_) {
      return const VoiceAiParseOutcome(
        warning: 'El endpoint IA respondió con un formato inválido.',
      );
    }
  }

  Future<VoiceAiParseOutcome<VoiceScheduleDraft>> enhanceSchedule({
    required String transcript,
    required DateTime referenceTime,
    required String endpointUrl,
    String? proxyToken,
  }) async {
    final normalizedTranscript = transcript.trim();
    if (normalizedTranscript.isEmpty) {
      return const VoiceAiParseOutcome(
        warning: 'No había suficiente texto para mejorar el dictado.',
      );
    }

    final responseMap = await _postParseRequest(
      endpointUrl: endpointUrl,
      proxyToken: proxyToken,
      payload: {
        'kind': 'schedule',
        'transcript': normalizedTranscript,
        'reference_time': referenceTime.toIso8601String(),
      },
    );
    if (responseMap.warning != null) {
      return VoiceAiParseOutcome(warning: responseMap.warning);
    }

    try {
      final draft = _scheduleDraftFromMap(
        responseMap.result!,
        transcript: normalizedTranscript,
      );
      if (draft == null) {
        return const VoiceAiParseOutcome(
          warning: 'El endpoint IA respondió, pero faltaron datos clave.',
        );
      }
      return VoiceAiParseOutcome(draft: draft);
    } catch (_) {
      return const VoiceAiParseOutcome(
        warning: 'El endpoint IA respondió con un formato inválido.',
      );
    }
  }

  Future<_ParseHttpResult> _postParseRequest({
    required String endpointUrl,
    required Map<String, dynamic> payload,
    String? proxyToken,
  }) async {
    final normalizedEndpoint = endpointUrl.trim();
    final uri = Uri.tryParse(normalizedEndpoint);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const _ParseHttpResult(
        warning: 'El endpoint IA configurado no tiene una URL válida.',
      );
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if ((proxyToken ?? '').trim().isNotEmpty)
                'Authorization': 'Bearer ${(proxyToken ?? '').trim()}',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractErrorMessage(decoded);
        return _ParseHttpResult(
          warning:
              message ??
              'El endpoint IA devolvió error ${response.statusCode}.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        return const _ParseHttpResult(
          warning: 'El endpoint IA no devolvió un objeto JSON.',
        );
      }

      final result = decoded['result'];
      if (result is Map<String, dynamic>) {
        return _ParseHttpResult(result: result);
      }

      return _ParseHttpResult(result: decoded);
    } on TimeoutException {
      return const _ParseHttpResult(
        warning: 'El endpoint IA tardó demasiado. Se usó el parser local.',
      );
    } on FormatException {
      return const _ParseHttpResult(
        warning: 'La respuesta del endpoint IA no se pudo leer como JSON.',
      );
    } on http.ClientException {
      return const _ParseHttpResult(
        warning: 'No pude conectar con el endpoint IA. Se usó el parser local.',
      );
    } catch (_) {
      return const _ParseHttpResult(
        warning:
            'No pude usar el endpoint IA. Se mantuvo la interpretación local.',
      );
    }
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  VoiceTaskDraft? _taskDraftFromMap(
    Map<String, dynamic> map, {
    required String transcript,
    required Iterable<Project> activeProjects,
  }) {
    final title = _readString(map, 'title');
    final dueAt = _parseDateTime(map['due_at'] ?? map['dueAt']);
    if (title.isEmpty || dueAt == null) {
      return null;
    }

    final rawMatchedProject =
        _readString(map, 'matched_project_name').isNotEmpty
        ? _readString(map, 'matched_project_name')
        : _readString(map, 'matchedProjectName');
    final rawProjectHint = _readString(map, 'project_hint').isNotEmpty
        ? _readString(map, 'project_hint')
        : _readString(map, 'projectHint');
    final matchedProjectName = _resolveProjectName(
      rawMatchedProject,
      activeProjects,
    );
    final projectHint = matchedProjectName == null
        ? _blankToNull(
            rawProjectHint.isNotEmpty ? rawProjectHint : rawMatchedProject,
          )
        : null;

    return VoiceTaskDraft(
      transcript: transcript,
      title: title,
      projectHint: projectHint,
      matchedProjectName: matchedProjectName,
      dueDate: dueAt,
      dueDateWasInferred:
          _readBool(map['due_date_was_inferred']) ||
          _readBool(map['dueDateWasInferred']),
      dueTimeWasInferred:
          _readBool(map['due_time_was_inferred']) ||
          _readBool(map['dueTimeWasInferred']),
      notes: _readStringList(map['notes']),
    );
  }

  VoiceScheduleDraft? _scheduleDraftFromMap(
    Map<String, dynamic> map, {
    required String transcript,
  }) {
    final title = _readString(map, 'title');
    final location = _readString(map, 'location');
    final firstStart = _parseDateTime(map['first_start'] ?? map['firstStart']);
    final firstEnd = _parseDateTime(map['first_end'] ?? map['firstEnd']);
    final weekDays = _readWeekDays(map['week_days'] ?? map['weekDays']);

    if (title.isEmpty ||
        firstStart == null ||
        firstEnd == null ||
        weekDays.isEmpty) {
      return null;
    }

    final safeEnd = firstEnd.isAfter(firstStart)
        ? firstEnd
        : firstStart.add(const Duration(hours: 1));

    return VoiceScheduleDraft(
      transcript: transcript,
      title: title,
      location: location,
      firstStart: firstStart,
      firstEnd: safeEnd,
      weekDays: weekDays,
      recurrenceEndDate: _parseDateOnly(
        map['recurrence_end_date'] ?? map['recurrenceEndDate'],
      ),
      notes: _readStringList(map['notes']),
    );
  }

  String? _resolveProjectName(String rawValue, Iterable<Project> projects) {
    final normalizedRaw = _normalize(rawValue);
    if (normalizedRaw.isEmpty) return null;

    for (final project in projects) {
      if (project.completed || project.hidden) continue;
      if (_normalize(project.name) == normalizedRaw) {
        return project.name;
      }
    }

    for (final project in projects) {
      if (project.completed || project.hidden) continue;
      final normalizedProject = _normalize(project.name);
      if (normalizedProject.contains(normalizedRaw) ||
          normalizedRaw.contains(normalizedProject)) {
        return project.name;
      }
    }

    return null;
  }

  String _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  bool _readBool(dynamic value) {
    return value is bool ? value : false;
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<int> _readWeekDays(dynamic value) {
    if (value is! List) return const [];
    final weekDays =
        value
            .map((item) {
              if (item is int) return item;
              if (item is num) return item.toInt();
              return int.tryParse(item.toString());
            })
            .whereType<int>()
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toSet()
            .toList()
          ..sort();
    return weekDays;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  DateTime? _parseDateOnly(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
      final parts = normalized.split('-');
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) {
        return null;
      }
      return DateTime(year, month, day);
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String? _blankToNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}

class _ParseHttpResult {
  final Map<String, dynamic>? result;
  final String? warning;

  const _ParseHttpResult({this.result, this.warning});
}
