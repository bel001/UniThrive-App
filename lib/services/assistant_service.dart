import '../models/project.dart';
import '../models/voice_schedule_draft.dart';
import '../models/voice_task_draft.dart';
import 'voice_schedule_parser.dart';
import 'voice_task_parser.dart';

/// Destino de un elemento detectado por el asistente.
enum AssistantCandidateKind { task, classBlock }

/// Un elemento (tarea o clase) detectado en un turno del asistente,
/// listo para revisar y confirmar antes de guardar.
class AssistantCandidate {
  final AssistantCandidateKind kind;
  final String sourceText;
  final VoiceTaskDraft? taskDraft;
  final VoiceScheduleDraft? scheduleDraft;

  const AssistantCandidate.task({
    required this.sourceText,
    required VoiceTaskDraft draft,
  })  : kind = AssistantCandidateKind.task,
        taskDraft = draft,
        scheduleDraft = null;

  const AssistantCandidate.classBlock({
    required this.sourceText,
    required VoiceScheduleDraft draft,
  })  : kind = AssistantCandidateKind.classBlock,
        taskDraft = null,
        scheduleDraft = draft;

  bool get isTask => kind == AssistantCandidateKind.task;

  String get title {
    if (isTask) return taskDraft?.title.trim() ?? '';
    return scheduleDraft?.title.trim() ?? '';
  }

  bool get canSave {
    if (isTask) return taskDraft?.canSave ?? false;
    return scheduleDraft?.canSave ?? false;
  }
}

/// Cerebro del asistente: divide el dictado en partes, clasifica cada una
/// (tarea o clase) y la convierte en candidata editable con los parsers
/// locales. Todo 100% local, sin red.
class AssistantService {
  AssistantService._();

  static const _taskParser = VoiceTaskParser();
  static const _scheduleParser = VoiceScheduleParser();

  /// Pistas de que el segmento habla de una clase/horario.
  static final _classCues = RegExp(
    r'\b(clase|curso|aula|sal[oó]n|laboratorio|profesor|profesora|docente|taller|seminario|facultad|ciclo|semestre|asignatura|ponencia|pr[aá]ctica de laboratorio)\b',
    caseSensitive: false,
  );

  /// Conectores que separan varias cosas en un mismo dictado o turno.
  static final _splitPattern = RegExp(
      r';|\n|'
      r'\b(adem[aá]s|tambi[eé]n|luego|despu[eé]s|otra cosa|apunta(?: esto)?|anota(?: esto)?|agrega(?: esto)?|y tengo|y el |y la |y los |y las |y mi clase|y clase|y una tarea|y tengo una)\b',
      caseSensitive: false);

  /// Divide un texto en segmentos independientes ("primero X, además Y").
  static List<String> splitSegments(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return const [];
    return compact
        .split(_splitPattern)
        .map(_cleanSegment)
        .where(_isMeaningfulSegment)
        .toList();
  }

  static final _fillerStart = RegExp(
    r'^(ah|eh|mmm|bueno|oye|este|y)\b[\s,]*',
    caseSensitive: false,
  );
  static final _contentWord = RegExp(r'[a-záéíóúñü]{3,}', caseSensitive: false);

  static String _cleanSegment(String segment) {
    var cleaned = segment.trim();
    for (var i = 0; i < 3; i++) {
      final next = cleaned
          .replaceFirst(_fillerStart, '')
          .replaceFirst(RegExp(r'^[\s,.;:¡!¿?]+'), '')
          .trim();
      if (next == cleaned) break;
      cleaned = next;
    }
    return cleaned;
  }

  /// Descarta restos sin contenido ("Ah, y", "eh") que dejan los conectores.
  static bool _isMeaningfulSegment(String segment) {
    return segment.length > 6 && _contentWord.hasMatch(segment);
  }

  /// Clasifica un segmento: clase si huele a horario, tarea en otro caso.
  static AssistantCandidateKind classifySegment(String segment) {
    if (_classCues.hasMatch(segment)) {
      return AssistantCandidateKind.classBlock;
    }
    return AssistantCandidateKind.task;
  }

  /// Convierte un texto (dictado, OCR o pegado) en candidatas confirmables.
  /// Cada segmento se clasifica y se parsea con el parser que corresponde.
  static List<AssistantCandidate> parseText(
    String text, {
    Iterable<Project> projects = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final segments = splitSegments(text);
    if (segments.isEmpty) return const [];

    final candidates = <AssistantCandidate>[];
    for (final segment in segments) {
      if (classifySegment(segment) == AssistantCandidateKind.classBlock) {
        final draft = _scheduleParser.parse(
          segment,
          referenceTime: now,
          existingProjects: projects,
        );
        if (draft.canSave) {
          candidates.add(
            AssistantCandidate.classBlock(
              sourceText: segment,
              draft: draft,
            ),
          );
          continue;
        }
      }
      final draft = _taskParser.parse(
        segment,
        projects: projects,
        referenceTime: now,
      );
      if (draft.canSave) {
        candidates.add(
          AssistantCandidate.task(sourceText: segment, draft: draft),
        );
      }
    }
    return candidates;
  }
}
