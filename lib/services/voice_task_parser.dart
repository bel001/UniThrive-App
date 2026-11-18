import '../models/project.dart';
import '../models/voice_task_draft.dart';

class VoiceTaskParser {
  const VoiceTaskParser();

  VoiceTaskDraft parse(
    String transcript, {
    Iterable<Project> projects = const [],
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final compactTranscript = _compactWhitespace(transcript);
    if (compactTranscript.isEmpty) {
      return VoiceTaskDraft.empty(referenceTime: now);
    }

    final notes = <String>[];
    final matchedProject = _matchExistingProject(compactTranscript, projects);
    final dueExtraction = _extractDueDate(compactTranscript, now);
    var remainingText = dueExtraction.remainingText;

    if (matchedProject != null) {
      remainingText = _removePhrase(remainingText, matchedProject.name);
    }

    final projectHintExtraction = matchedProject == null
        ? _extractProjectHint(remainingText)
        : null;
    if (projectHintExtraction != null) {
      remainingText = _removePhrase(
        remainingText,
        projectHintExtraction.matchedText,
      );
    }

    var title = _extractTitle(remainingText, compactTranscript);
    if (title.isEmpty) {
      title = _extractFallbackTitle(compactTranscript);
      notes.add(
        'Revisa el título antes de guardar. El dictado no separó bien la acción principal.',
      );
    }

    var dueDate = dueExtraction.dueDate;
    var dueDateWasInferred = false;
    if (dueDate == null) {
      dueDate = _defaultDueDate(now);
      dueDateWasInferred = true;
      notes.add(
        'No detecté una fecha clara. Dejé mañana a las 6:00 p. m. para que la confirmes.',
      );
    } else if (dueExtraction.usedDefaultTime) {
      notes.add(
        'No escuché una hora exacta. Dejé 6:00 p. m. y puedes cambiarla antes de guardar.',
      );
    }

    if (matchedProject == null && projectHintExtraction == null) {
      notes.add(
        'Si quieres ligarla a un curso específico, ajusta el proyecto antes de guardar.',
      );
    }

    return VoiceTaskDraft(
      transcript: compactTranscript,
      title: title,
      projectHint: matchedProject == null
          ? projectHintExtraction?.projectHint
          : null,
      matchedProjectName: matchedProject?.name,
      dueDate: dueDate,
      dueDateWasInferred: dueDateWasInferred,
      dueTimeWasInferred: dueExtraction.usedDefaultTime || dueDateWasInferred,
      notes: notes,
    );
  }

  DateTime _defaultDueDate(DateTime referenceTime) {
    final tomorrow = referenceTime.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18);
  }

  _ProjectMatch? _matchExistingProject(
    String transcript,
    Iterable<Project> projects,
  ) {
    final normalizedTranscript = _normalizeForSearch(transcript);
    _ProjectMatch? bestMatch;

    for (final project in projects) {
      if (project.completed || project.hidden) continue;
      final projectName = _compactWhitespace(_stripLeadingEmoji(project.name));
      if (projectName.isEmpty) continue;

      final normalizedProjectName = _normalizeForSearch(projectName);
      if (normalizedProjectName.isEmpty ||
          normalizedProjectName == 'tareas rapidas') {
        continue;
      }

      final score = _projectMatchScore(
        normalizedTranscript,
        normalizedProjectName,
      );
      if (score < 0.62) continue;

      if (bestMatch == null || score > bestMatch.score) {
        bestMatch = _ProjectMatch(name: projectName, score: score);
      }
    }

    return bestMatch;
  }

  double _projectMatchScore(String transcript, String projectName) {
    if (transcript.contains(projectName)) {
      return 1 + (projectName.length / 100);
    }

    final tokens = projectName
        .split(' ')
        .where((token) => token.length > 2)
        .toList();
    if (tokens.isEmpty) {
      return 0;
    }

    final matches = tokens.where(transcript.contains).length;
    if (matches == 0) {
      return 0;
    }

    final baseScore = matches / tokens.length;
    final bonus = tokens.length >= 2 ? 0.05 * matches : 0;
    return baseScore + bonus;
  }

  _ProjectHintExtraction? _extractProjectHint(String text) {
    final patterns = <RegExp>[
      RegExp(
        r'(?:del?\s+curso|de\s+la\s+materia|de\s+la\s+clase|del?\s+ramo|de\s+la\s+asignatura)\s+([^,.;:]+?)(?=\s+(?:para|hoy|mañana|pasado|el|este|esta|a\s+las|antes\s+del?)\b|[:;,.]|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'tarea\s+de\s+([^,.;:]+?)(?=\s*[:;,.-]|\s+(?:para|hoy|mañana|pasado|el|este|esta|a\s+las|antes\s+del?)\b|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:curso|materia|clase|ramo|asignatura)\s+([^,.;:]+?)(?=\s+(?:para|hoy|mañana|pasado|el|este|esta|a\s+las|antes\s+del?)\b|[:;,.]|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final candidate = _humanizeFragment(match.group(1) ?? '');
      if (candidate.isEmpty) continue;
      return _ProjectHintExtraction(
        projectHint: candidate,
        matchedText: match.group(0) ?? candidate,
      );
    }

    if (text.contains(':')) {
      final beforeColon = text.split(':').first;
      final courseMatch = RegExp(
        r'\bde\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(beforeColon);
      if (courseMatch != null) {
        final candidate = _humanizeFragment(courseMatch.group(1) ?? '');
        if (candidate.isNotEmpty) {
          return _ProjectHintExtraction(
            projectHint: candidate,
            matchedText: courseMatch.group(0) ?? candidate,
          );
        }
      }
    }

    return null;
  }

  String _extractTitle(String remainingText, String fallbackSource) {
    var title = remainingText;

    if (fallbackSource.contains(':')) {
      final tail = fallbackSource.split(':').skip(1).join(':').trim();
      if (tail.isNotEmpty) {
        title = tail;
      }
    }

    final cleanupPatterns = <RegExp>[
      RegExp(
        r'^(?:agrega|agregar|crea|crear|añade|anota|apunta|pon|programa|agenda|recordame|recu[eé]rdame|necesito|tengo\s+que)\s+',
        caseSensitive: false,
      ),
      RegExp(
        r'^(?:una\s+|un\s+)?(?:tarea|recordatorio|pendiente)\s+',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:del?\s+curso|de\s+la\s+materia|de\s+la\s+clase|del?\s+ramo|curso|materia|clase|ramo|asignatura)\b.*$',
        caseSensitive: false,
      ),
    ];
    final trailingSchedulePatterns = <RegExp>[
      RegExp(
        r'\s+(?:para\s+)?(?:hoy|mañana|manana|pasado mañana|pasado manana|el\s+(?:lunes|martes|mi[eé]rcoles|jueves|viernes|s[áa]bado|domingo)|este\s+(?:lunes|martes|mi[eé]rcoles|jueves|viernes|s[áa]bado|domingo)|esta\s+(?:tarde|noche)|\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?|\d{1,2}\s+de\s+(?:enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre))(?:\s+a\s+las.*)?$',
        caseSensitive: false,
      ),
      RegExp(
        r'\s+a\s+las\s+\d{1,2}(?::\d{2}|\s+y\s+(?:media|cuarto))?\s*(?:a\.?\s*m\.?|p\.?\s*m\.?|de\s+la\s+mañana|de\s+la\s+tarde|de\s+la\s+noche)?$',
        caseSensitive: false,
      ),
    ];

    for (final pattern in cleanupPatterns) {
      title = title.replaceFirst(pattern, '');
    }
    for (final pattern in trailingSchedulePatterns) {
      title = title.replaceFirst(pattern, '');
    }
    // Limpia coletilla huérfana tras remover fecha: "para", "en", "de" sueltos
    title = title.replaceFirst(RegExp(r'\s+(?:para|en|de|del|con)\s*$', caseSensitive: false), '');
    // Soporta nuevo patrón "en 3 días / dentro de X días / en una semana / fin de semana"
    title = title.replaceFirst(RegExp(r'\s+(?:en|dentro\s+de)\s+(?:\d+|una|un)\s+d[ií]as?(?:\s+a\s+las.*)?$', caseSensitive: false), '');
    title = title.replaceFirst(RegExp(r'\s+fin\s+de\s+semana(?:\s+a\s+las.*)?$', caseSensitive: false), '');

    title = title
        .replaceAll(
          RegExp(
            r'\b(?:por\s+favor|urgente|importante)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'^[\s:;,.-]+|[\s:;,.-]+$'), '');

    title = _compactWhitespace(title);
    if (title.isEmpty) {
      return '';
    }

    return _sentenceCase(title);
  }

  String _extractFallbackTitle(String transcript) {
    var cleaned = transcript.replaceAll(
      RegExp(
        r'^(?:agrega|agregar|crea|crear|añade|anota|apunta|pon|programa|agenda|recordame|recu[eé]rdame)\s+',
        caseSensitive: false,
      ),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\s+(?:para|en|de)\s*$', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'^[\s:;,.-]+|[\s:;,.-]+$'), '');
    cleaned = _compactWhitespace(cleaned);
    if (cleaned.isEmpty) {
      return '';
    }
    return _sentenceCase(cleaned);
  }

  _DueDateExtraction _extractDueDate(String text, DateTime referenceTime) {
    final lowerText = text.toLowerCase();
    DateTime? baseDate;
    var matchedDateText = '';

    final namedDate = _extractNamedDate(lowerText, referenceTime);
    if (namedDate != null) {
      baseDate = namedDate.date;
      matchedDateText = namedDate.matchedText;
    } else {
      final explicitDate = _extractExplicitDate(lowerText, referenceTime);
      if (explicitDate != null) {
        baseDate = explicitDate.date;
        matchedDateText = explicitDate.matchedText;
      }
    }

    final timeExtraction = _extractTime(text);
    if (timeExtraction != null) {
      final date =
          baseDate ??
          _resolveDateFromTimeOnly(timeExtraction.time, referenceTime);
      return _DueDateExtraction(
        dueDate: DateTime(
          date.year,
          date.month,
          date.day,
          timeExtraction.time.hour,
          timeExtraction.time.minute,
        ),
        remainingText: _removePhrase(
          _removePhrase(text, matchedDateText),
          timeExtraction.matchedText,
        ),
        usedDefaultTime: false,
      );
    }

    if (baseDate != null) {
      return _DueDateExtraction(
        dueDate: DateTime(baseDate.year, baseDate.month, baseDate.day, 18),
        remainingText: _removePhrase(text, matchedDateText),
        usedDefaultTime: true,
      );
    }

    return _DueDateExtraction(
      dueDate: null,
      remainingText: text,
      usedDefaultTime: false,
    );
  }

  _NamedDateExtraction? _extractNamedDate(String text, DateTime referenceTime) {
    // Soporte: "en 3 días", "dentro de 2 días", "en una semana", "fin de semana", "esta tarde/noche"
    final normalized = text.toLowerCase();
    // en X días / dentro de X días
    final inDaysMatch = RegExp(r'(?:en|dentro\s+de)\s+(\d+|una|un)\s+d[ií]as?').firstMatch(normalized);
    if (inDaysMatch != null) {
      final raw = inDaysMatch.group(1) ?? '1';
      final days = raw == 'una' || raw == 'un' ? 1 : int.tryParse(raw) ?? 1;
      final date = DateTime(referenceTime.year, referenceTime.month, referenceTime.day).add(Duration(days: days));
      return _NamedDateExtraction(date: date, matchedText: inDaysMatch.group(0) ?? raw);
    }
    if (normalized.contains('en una semana') || normalized.contains('en una seman')) {
      final date = DateTime(referenceTime.year, referenceTime.month, referenceTime.day).add(const Duration(days: 7));
      return _NamedDateExtraction(date: date, matchedText: 'en una semana');
    }
    if (normalized.contains('fin de semana')) {
      // sábado próximo
      var daysAhead = DateTime.saturday - referenceTime.weekday;
      if (daysAhead <= 0) daysAhead += 7;
      final date = DateTime(referenceTime.year, referenceTime.month, referenceTime.day).add(Duration(days: daysAhead));
      return _NamedDateExtraction(date: date, matchedText: 'fin de semana');
    }
    // "esta tarde/noche" y "hoy en la tarde/noche" → hoy
    if (normalized.contains('esta tarde') || normalized.contains('esta noche') || normalized.contains('hoy en la')) {
      final date = DateTime(referenceTime.year, referenceTime.month, referenceTime.day);
      return _NamedDateExtraction(date: date, matchedText: 'hoy');
    }

    final relativeMatches = <String, int>{
      'pasado mañana': 2,
      'pasado manana': 2,
      'mañana': 1,
      'manana': 1,
      'hoy': 0,
    };

    for (final entry in relativeMatches.entries) {
      if (text.contains(entry.key)) {
        final date = DateTime(
          referenceTime.year,
          referenceTime.month,
          referenceTime.day,
        ).add(Duration(days: entry.value));
        return _NamedDateExtraction(date: date, matchedText: entry.key);
      }
    }

    final weekdayRegex = RegExp(
      r'(?:el|este|esta|pr[oó]ximo|proximo)?\s*(lunes|martes|mi[eé]rcoles|jueves|viernes|s[áa]bado|domingo)',
      caseSensitive: false,
    );
    final weekdayMatch = weekdayRegex.firstMatch(text);
    if (weekdayMatch != null) {
      final full = weekdayMatch.group(0) ?? '';
      final weekdayLabel = weekdayMatch.group(1) ?? '';
      final weekday = _weekdayFromSpanish(weekdayLabel);
      if (weekday != null) {
        var daysAhead = weekday - referenceTime.weekday;
        final isProximo = full.toLowerCase().contains('proximo') || full.toLowerCase().contains('próximo');
        if (isProximo) {
          // "próximo lunes" si hoy es lunes → +7, no 0
          if (daysAhead <= 0) daysAhead += 7;
          if (daysAhead == 0) daysAhead = 7;
        } else {
          if (daysAhead < 0) daysAhead += 7;
        }
        final date = DateTime(
          referenceTime.year,
          referenceTime.month,
          referenceTime.day,
        ).add(Duration(days: daysAhead));
        return _NamedDateExtraction(
          date: date,
          matchedText: full,
        );
      }
    }

    return null;
  }

  _NamedDateExtraction? _extractExplicitDate(
    String text,
    DateTime referenceTime,
  ) {
    final slashDate = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(text);
    if (slashDate != null) {
      final day = int.tryParse(slashDate.group(1) ?? '');
      final month = int.tryParse(slashDate.group(2) ?? '');
      final rawYear = slashDate.group(3);
      if (day != null && month != null) {
        var year = referenceTime.year;
        if (rawYear != null) {
          year = int.parse(rawYear.length == 2 ? '20$rawYear' : rawYear);
        }
        var candidate = _safeDate(year, month, day);
        if (candidate != null &&
            rawYear == null &&
            candidate.isBefore(
              DateTime(
                referenceTime.year,
                referenceTime.month,
                referenceTime.day,
              ),
            )) {
          candidate = _safeDate(year + 1, month, day);
        }
        if (candidate != null) {
          return _NamedDateExtraction(
            date: candidate,
            matchedText: slashDate.group(0) ?? '',
          );
        }
      }
    }

    final longDate = RegExp(
      r'\b(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)(?:\s+de\s+(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (longDate != null) {
      final day = int.tryParse(longDate.group(1) ?? '');
      final month = _monthFromSpanish(longDate.group(2) ?? '');
      final rawYear = longDate.group(3);
      if (day != null && month != null) {
        var year = rawYear != null ? int.parse(rawYear) : referenceTime.year;
        var candidate = _safeDate(year, month, day);
        if (candidate != null &&
            rawYear == null &&
            candidate.isBefore(
              DateTime(
                referenceTime.year,
                referenceTime.month,
                referenceTime.day,
              ),
            )) {
          candidate = _safeDate(year + 1, month, day);
        }
        if (candidate != null) {
          return _NamedDateExtraction(
            date: candidate,
            matchedText: longDate.group(0) ?? '',
          );
        }
      }
    }

    return null;
  }

  _TimeExtraction? _extractTime(String text) {
    // Soporte "menos cuarto/diez" ej. "7 menos cuarto" -> 6:45
    final menosMatch = RegExp(
      r'(?:a\s+las\s+)?(\d{1,2})\s+menos\s+(cuarto|diez|veinte|cinco)',
      caseSensitive: false,
    ).firstMatch(text);
    if (menosMatch != null) {
      var hour = int.tryParse(menosMatch.group(1) ?? '') ?? 0;
      final word = menosMatch.group(2)?.toLowerCase() ?? '';
      var delta = 15;
      if (word == 'diez') delta = 10;
      if (word == 'veinte') delta = 20;
      if (word == 'cinco') delta = 5;
      hour -= 1;
      if (hour < 0) hour += 12;
      if (hour == 0) hour = 12;
      var minute = 60 - delta;
      // Ajuste meridiem por frase circundante
      final after = text.substring(menosMatch.end).toLowerCase();
      final before = text.substring(0, menosMatch.start).toLowerCase();
      final hasPm = after.contains('tarde') || after.contains('noche') || after.contains('pm') || before.contains('tarde');
      if (hasPm && hour < 12) hour += 12;
      if (!hasPm && hour >= 1 && hour <= 6 && !text.toLowerCase().contains('mañana')) {
        // heurística mañana/tarde ya aplicada abajo, mantenemos
      }
      return _TimeExtraction(
        time: DateTime(0, 1, 1, hour % 24, minute),
        matchedText: menosMatch.group(0) ?? '',
      );
    }

    final patterns = <RegExp>[
      RegExp(
        r'(?:a\s+las|a\s+la|para\s+las|para\s+la)\s*(\d{1,2})(?:[:.](\d{2})|\s+y\s+(media|cuarto))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|de\s+la\s+mañana|de\s+la\s+tarde|de\s+la\s+noche)?',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(\d{1,2})(?::(\d{2}))\s*(a\.?\s*m\.?|p\.?\s*m\.?)?\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      var hour = int.tryParse(match.group(1) ?? '');
      if (hour == null || hour > 23) continue;

      var minute = int.tryParse(match.group(2) ?? '');
      final halfWord = match.group(3)?.toLowerCase();
      if (minute == null) {
        if (halfWord == 'media') {
          minute = 30;
        } else if (halfWord == 'cuarto') {
          minute = 15;
        } else {
          minute = 0;
        }
      }

      final meridiem = (match.groupCount >= 4 ? match.group(4) : match.group(3))
          ?.toLowerCase();
      if (meridiem != null) {
        if ((meridiem.contains('p') ||
                meridiem.contains('tarde') ||
                meridiem.contains('noche')) &&
            hour < 12) {
          hour += 12;
        } else if ((meridiem.contains('a') || meridiem.contains('mañana')) &&
            hour == 12) {
          hour = 0;
        }
      } else if (hour >= 1 && hour <= 7) {
        hour += 12;
      }

      return _TimeExtraction(
        time: DateTime(0, 1, 1, hour, minute),
        matchedText: match.group(0) ?? '',
      );
    }

    return null;
  }

  DateTime _resolveDateFromTimeOnly(DateTime time, DateTime referenceTime) {
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
      time.hour,
      time.minute,
    );
    if (!today.isBefore(referenceTime)) {
      return today;
    }
    final tomorrow = referenceTime.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    final lastDay = DateTime(year, month + 1, 0).day;
    if (day < 1 || day > lastDay) return null;
    return DateTime(year, month, day);
  }

  int? _weekdayFromSpanish(String value) {
    switch (_normalizeForSearch(value)) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miercoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sabado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  int? _monthFromSpanish(String value) {
    switch (_normalizeForSearch(value)) {
      case 'enero':
        return 1;
      case 'febrero':
        return 2;
      case 'marzo':
        return 3;
      case 'abril':
        return 4;
      case 'mayo':
        return 5;
      case 'junio':
        return 6;
      case 'julio':
        return 7;
      case 'agosto':
        return 8;
      case 'septiembre':
      case 'setiembre':
        return 9;
      case 'octubre':
        return 10;
      case 'noviembre':
        return 11;
      case 'diciembre':
        return 12;
      default:
        return null;
    }
  }

  String _stripLeadingEmoji(String text) {
    return text.replaceFirst(RegExp(r'^[^\w\d]+'), '').trim();
  }

  String _humanizeFragment(String text) {
    final compact = _compactWhitespace(
      text.replaceAll(RegExp(r'^[\s:;,.-]+|[\s:;,.-]+$'), ''),
    );
    if (compact.isEmpty) return '';
    return compact
        .split(' ')
        .map((word) {
          if (word.length <= 2 && word == word.toUpperCase()) {
            return word;
          }
          return _sentenceCase(word);
        })
        .join(' ');
  }

  String _sentenceCase(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _removePhrase(String text, String phrase) {
    if (phrase.trim().isEmpty) {
      return _compactWhitespace(text);
    }
    return _compactWhitespace(
      text.replaceFirst(
        RegExp(RegExp.escape(phrase), caseSensitive: false),
        ' ',
      ),
    );
  }

  String _compactWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeForSearch(String value) {
    final accents = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      if (accents.containsKey(character)) {
        buffer.write(accents[character]);
      } else if (RegExp(r'[a-z0-9\s]').hasMatch(character)) {
        buffer.write(character);
      } else {
        buffer.write(' ');
      }
    }

    return _compactWhitespace(buffer.toString());
  }
}

class _DueDateExtraction {
  final DateTime? dueDate;
  final String remainingText;
  final bool usedDefaultTime;

  const _DueDateExtraction({
    required this.dueDate,
    required this.remainingText,
    required this.usedDefaultTime,
  });
}

class _NamedDateExtraction {
  final DateTime date;
  final String matchedText;

  const _NamedDateExtraction({required this.date, required this.matchedText});
}

class _TimeExtraction {
  final DateTime time;
  final String matchedText;

  const _TimeExtraction({required this.time, required this.matchedText});
}

class _ProjectHintExtraction {
  final String projectHint;
  final String matchedText;

  const _ProjectHintExtraction({
    required this.projectHint,
    required this.matchedText,
  });
}

class _ProjectMatch {
  final String name;
  final double score;

  const _ProjectMatch({required this.name, required this.score});
}
