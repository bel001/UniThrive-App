import '../models/voice_schedule_draft.dart';

class VoiceScheduleParser {
  const VoiceScheduleParser();

  VoiceScheduleDraft parse(String transcript, {DateTime? referenceTime}) {
    final reference = referenceTime ?? DateTime.now();
    final compactTranscript = _compactWhitespace(transcript);
    if (compactTranscript.isEmpty) {
      return VoiceScheduleDraft.empty(referenceTime: reference);
    }

    final notes = <String>[];
    final normalized = _normalizeForSearch(compactTranscript);
    final days = _extractWeekDays(normalized);
    final timeRange = _extractTimeRange(compactTranscript);
    final recurrenceEndDate = _extractEndDate(normalized, reference);
    final title = _extractTitle(compactTranscript, normalized);
    final location = _extractLocation(compactTranscript, timeRange?.endIndex);

    final resolvedDays = days.isEmpty ? [reference.weekday] : days;
    if (days.isEmpty) {
      notes.add(
        'No detecté días específicos. Dejé el día que estabas viendo para que lo ajustes.',
      );
    }

    final resolvedTimeRange = timeRange ?? _defaultTimeRange();
    if (timeRange == null) {
      notes.add(
        'No detecté un rango horario claro. Dejé 9:00 a. m. a 11:00 a. m. para que lo confirmes.',
      );
    }

    final firstStart = _resolveFirstOccurrence(
      reference: reference,
      weekDays: resolvedDays,
      hour: resolvedTimeRange.startHour,
      minute: resolvedTimeRange.startMinute,
    );
    final firstEnd = DateTime(
      firstStart.year,
      firstStart.month,
      firstStart.day,
      resolvedTimeRange.endHour,
      resolvedTimeRange.endMinute,
    );

    final adjustedEnd = firstEnd.isAfter(firstStart)
        ? firstEnd
        : firstEnd.add(const Duration(hours: 1));

    if (recurrenceEndDate == null) {
      notes.add(
        'No detecté fin de ciclo. La serie se guardará sin fecha límite hasta que la edites.',
      );
    }

    if (location.isEmpty) {
      notes.add(
        'No encontré aula o ubicación. Puedes dejarlo vacío o completarlo antes de guardar.',
      );
    }

    final cleanedTitle = title.isEmpty ? 'Clase' : title;
    if (title.isEmpty) {
      notes.add(
        'No pude separar bien el nombre de la clase. Dejé un título genérico para que lo ajustes.',
      );
    }

    return VoiceScheduleDraft(
      transcript: compactTranscript,
      title: cleanedTitle,
      location: location,
      firstStart: firstStart,
      firstEnd: adjustedEnd,
      weekDays: resolvedDays,
      recurrenceEndDate: recurrenceEndDate,
      notes: notes,
    );
  }

  List<int> _extractWeekDays(String normalizedTranscript) {
    final days = <int>{};
    final rangeMatch = RegExp(
      r'(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\s+a\s+(lunes|martes|miercoles|jueves|viernes|sabado|domingo)',
    ).firstMatch(normalizedTranscript);

    if (rangeMatch != null) {
      final startDay = _weekdayFromSpanish(rangeMatch.group(1) ?? '');
      final endDay = _weekdayFromSpanish(rangeMatch.group(2) ?? '');
      if (startDay != null && endDay != null) {
        var cursor = startDay;
        days.add(cursor);
        while (cursor != endDay) {
          cursor = cursor == DateTime.sunday ? DateTime.monday : cursor + 1;
          days.add(cursor);
          if (days.length > 7) break;
        }
      }
    }

    final allMatches = RegExp(
      r'(lunes|martes|miercoles|jueves|viernes|sabado|domingo)',
    ).allMatches(normalizedTranscript);
    for (final match in allMatches) {
      final weekday = _weekdayFromSpanish(match.group(1) ?? '');
      if (weekday != null) {
        days.add(weekday);
      }
    }

    final ordered = days.toList()..sort();
    return ordered;
  }

  _VoiceScheduleTimeRange? _extractTimeRange(String transcript) {
    final match = RegExp(
      r'(?:de\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm|de\s+la\s+mañana|de\s+la\s+tarde|de\s+la\s+noche)?\s*(?:a|-|hasta)\s*(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm|de\s+la\s+mañana|de\s+la\s+tarde|de\s+la\s+noche)?',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (match == null) {
      return null;
    }

    final startHourRaw = int.tryParse(match.group(1) ?? '');
    final startMinute = int.tryParse(match.group(2) ?? '') ?? 0;
    final endHourRaw = int.tryParse(match.group(4) ?? '');
    final endMinute = int.tryParse(match.group(5) ?? '') ?? 0;
    if (startHourRaw == null || endHourRaw == null) {
      return null;
    }

    final startHint = _parseMeridiem(match.group(3));
    final endHint = _parseMeridiem(match.group(6));
    final sharedHint = endHint ?? startHint;
    var startHour = _applyHourHint(startHourRaw, startHint ?? sharedHint);
    var endHour = _applyHourHint(endHourRaw, endHint ?? sharedHint);

    if (startHint == null && endHint == null) {
      startHour = _inferClassHour(startHourRaw);
      endHour = _inferClassHour(endHourRaw);
    } else if (startHint == null) {
      startHour = _applyHourHint(startHourRaw, sharedHint);
    } else if (endHint == null) {
      endHour = _applyHourHint(endHourRaw, sharedHint);
    }

    if (endHour < startHour ||
        (endHour == startHour && endMinute <= startMinute)) {
      if (endHour < 12) {
        endHour += 12;
      }
    }

    return _VoiceScheduleTimeRange(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      startIndex: match.start,
      endIndex: match.end,
    );
  }

  _VoiceScheduleTimeRange _defaultTimeRange() {
    return const _VoiceScheduleTimeRange(
      startHour: 9,
      startMinute: 0,
      endHour: 11,
      endMinute: 0,
      startIndex: -1,
      endIndex: -1,
    );
  }

  DateTime? _extractEndDate(String normalizedTranscript, DateTime reference) {
    final slashMatch = RegExp(
      r'hasta\s+(?:el\s+)?(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?',
    ).firstMatch(normalizedTranscript);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1) ?? '');
      final month = int.tryParse(slashMatch.group(2) ?? '');
      final rawYear = slashMatch.group(3);
      if (day != null && month != null) {
        var year = reference.year;
        if (rawYear != null) {
          year = int.parse(rawYear.length == 2 ? '20$rawYear' : rawYear);
        }
        return _safeDate(year, month, day);
      }
    }

    final longMatch = RegExp(
      r'hasta\s+(?:el\s+)?(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)(?:\s+de\s+(\d{4}))?',
    ).firstMatch(normalizedTranscript);
    if (longMatch != null) {
      final day = int.tryParse(longMatch.group(1) ?? '');
      final month = _monthFromSpanish(longMatch.group(2) ?? '');
      final rawYear = longMatch.group(3);
      if (day != null && month != null) {
        final year = rawYear != null ? int.parse(rawYear) : reference.year;
        return _safeDate(year, month, day);
      }
    }

    final monthOnlyMatch = RegExp(
      r'hasta\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)',
    ).firstMatch(normalizedTranscript);
    if (monthOnlyMatch != null) {
      final month = _monthFromSpanish(monthOnlyMatch.group(1) ?? '');
      if (month != null) {
        var year = reference.year;
        if (month < reference.month) {
          year += 1;
        }
        return DateTime(year, month + 1, 0);
      }
    }

    return null;
  }

  String _extractTitle(String transcript, String normalizedTranscript) {
    final titlePatterns = <RegExp>[
      RegExp(
        r'(?:mi\s+)?(?:clase|curso|laboratorio|lab|taller)\s+de\s+(.+?)(?=\s+(?:es|son|lunes|martes|miercoles|jueves|viernes|sabado|domingo|a\s+las))',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:agrega|agenda|anota|pon)\s+(?:mi\s+)?(?:clase|curso|laboratorio|lab|taller)?\s*(.+?)(?=\s+(?:lunes|martes|miercoles|jueves|viernes|sabado|domingo|a\s+las))',
        caseSensitive: false,
      ),
    ];

    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(normalizedTranscript);
      if (match != null) {
        final sourceMatch = RegExp(
          RegExp.escape(match.group(1) ?? ''),
          caseSensitive: false,
        ).firstMatch(_normalizeForSearch(transcript));
        final candidate = match.group(1) ?? '';
        final humanized = _humanize(candidate);
        if (humanized.isNotEmpty) {
          return humanized;
        }
        if (sourceMatch != null) {
          return transcript
              .substring(sourceMatch.start, sourceMatch.end)
              .trim();
        }
      }
    }

    final firstWeekdayIndex = RegExp(
      r'\b(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\b',
    ).firstMatch(normalizedTranscript)?.start;
    final firstTimeIndex = RegExp(
      r'\b\d{1,2}(?::\d{2})?\b',
    ).firstMatch(normalizedTranscript)?.start;
    final cutIndex = [firstWeekdayIndex, firstTimeIndex]
        .whereType<int>()
        .fold<int?>(null, (current, value) {
          if (current == null) return value;
          return value < current ? value : current;
        });

    var segment = cutIndex == null
        ? transcript
        : transcript.substring(0, cutIndex).trim();
    if (segment.contains(':')) {
      segment = segment.split(':').first.trim();
    }
    segment = segment
        .replaceFirst(
          RegExp(r'^(?:agrega|agenda|anota|pon|crea)\s+', caseSensitive: false),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(?:mi\s+)?(?:clase|curso|laboratorio|lab|taller)\s+de\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(RegExp(r'\s+(?:es|son)$', caseSensitive: false), '')
        .trim();

    return _humanize(segment);
  }

  String _extractLocation(String transcript, int? lowerBound) {
    final matches =
        RegExp(
          r'\ben\s+([^,.;]+?)(?=\s+hasta\b|$)',
          caseSensitive: false,
        ).allMatches(transcript).where((match) {
          if (lowerBound == null) return true;
          return match.start >= lowerBound;
        }).toList();

    if (matches.isNotEmpty) {
      final value = matches.last.group(1) ?? '';
      return _humanize(value);
    }

    final directMatch = RegExp(
      r'\b(aula|sal[oó]n|laboratorio|lab\.?)\s+([^\s,.;]+(?:\s+[^\s,.;]+)?)',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (directMatch != null) {
      return _humanize(
        '${directMatch.group(1) ?? ''} ${directMatch.group(2) ?? ''}',
      );
    }

    return '';
  }

  DateTime _resolveFirstOccurrence({
    required DateTime reference,
    required List<int> weekDays,
    required int hour,
    required int minute,
  }) {
    final candidates = weekDays.map((weekday) {
      var daysAhead = weekday - reference.weekday;
      final candidate = DateTime(
        reference.year,
        reference.month,
        reference.day,
        hour,
        minute,
      ).add(Duration(days: daysAhead));

      if (daysAhead < 0 || candidate.isBefore(reference)) {
        return candidate.add(const Duration(days: 7));
      }
      return candidate;
    }).toList()..sort();

    return candidates.first;
  }

  int _inferClassHour(int rawHour) {
    if (rawHour >= 1 && rawHour <= 6) {
      return rawHour + 12;
    }
    return rawHour;
  }

  int? _parseMeridiem(String? value) {
    if (value == null) return null;
    final normalized = _normalizeForSearch(value);
    if (normalized.contains('pm') ||
        normalized.contains('tarde') ||
        normalized.contains('noche')) {
      return 12;
    }
    if (normalized.contains('am') || normalized.contains('manana')) {
      return 0;
    }
    return null;
  }

  int _applyHourHint(int rawHour, int? hint) {
    if (hint == null) {
      return rawHour;
    }
    if (hint == 12 && rawHour < 12) {
      return rawHour + 12;
    }
    if (hint == 0 && rawHour == 12) {
      return 0;
    }
    return rawHour;
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    final lastDay = DateTime(year, month + 1, 0).day;
    if (day < 1 || day > lastDay) return null;
    return DateTime(year, month, day);
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

  String _humanize(String text) {
    final compact = _compactWhitespace(
      text.replaceAll(RegExp(r'^[\s:;,.-]+|[\s:;,.-]+$'), ''),
    );
    if (compact.isEmpty) return '';
    return compact
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word.length <= 2 && word == word.toUpperCase()) {
            return word;
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
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
      } else if (RegExp(r'[a-z0-9\s:/.-]').hasMatch(character)) {
        buffer.write(character);
      } else {
        buffer.write(' ');
      }
    }
    return _compactWhitespace(buffer.toString());
  }
}

class _VoiceScheduleTimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int startIndex;
  final int endIndex;

  const _VoiceScheduleTimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.startIndex,
    required this.endIndex,
  });
}
