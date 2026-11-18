import '../models/project.dart';
import '../models/schedule.dart';
import '../models/voice_schedule_draft.dart';

class VoiceScheduleParser {
  const VoiceScheduleParser();

  /// Parse single class or event dictation.
  VoiceScheduleDraft parse(
    String transcript, {
    DateTime? referenceTime,
    Iterable<Project> existingProjects = const [],
    Iterable<ScheduleBlock> existingBlocks = const [],
  }) {
    final reference = referenceTime ?? DateTime.now();
    final compactTranscript = _compactWhitespace(transcript);
    if (compactTranscript.isEmpty) {
      return VoiceScheduleDraft.empty(referenceTime: reference);
    }

    final notes = <String>[];
    // 1. Normalize spoken numbers and fraction words ("ocho y media" -> "8:30")
    final preprocessed = _normalizeSpokenFractions(
      _normalizeSpokenNumbers(compactTranscript),
    );
    final normalized = _fuzzyCorrectDays(_normalizeForSearch(preprocessed));

    // 2. Check for exact specific date (e.g. "jueves 27 de agosto")
    final specificDateExtraction = _extractSpecificDate(
      normalized,
      preprocessed,
      reference,
    );
    final exactDate = specificDateExtraction?.date;

    // 3. Extract week days and time range
    final days = _extractWeekDays(normalized);
    final timeRange = _extractTimeRange(preprocessed);
    final academicPeriodEndDate = _extractEndDate(normalized, reference);
    final title = _extractTitle(preprocessed, normalized);
    final location = _extractLocation(preprocessed, timeRange?.endIndex);

    // 4. Resolve recurrence vs single event
    final isRepeatingMentioned =
        normalized.contains('todos los') ||
        normalized.contains('todas las') ||
        normalized.contains('cada') ||
        RegExp(r'\bhasta\s+(?:el\s+\d|enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|parciales|finales|el\s+ciclo|el\s+semestre)\b').hasMatch(normalized) ||
        normalized.contains('semanal') ||
        normalized.contains('diario') ||
        days.length > 1;

    final isSingleEvent =
        specificDateExtraction != null && !isRepeatingMentioned;

    final resolvedDays = (exactDate != null && !isRepeatingMentioned)
        ? [exactDate.weekday]
        : (days.isEmpty ? [reference.weekday] : days);

    if (days.isEmpty && exactDate == null) {
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

    // 5. Calculate start & end DateTime
    final anchorDate = exactDate ?? reference;
    final firstStart = exactDate != null
        ? DateTime(
            anchorDate.year,
            anchorDate.month,
            anchorDate.day,
            resolvedTimeRange.startHour,
            resolvedTimeRange.startMinute,
          )
        : _resolveFirstOccurrence(
            reference: reference,
            weekDays: resolvedDays,
            hour: resolvedTimeRange.startHour,
            minute: resolvedTimeRange.startMinute,
          );

    final firstEndCandidate = DateTime(
      firstStart.year,
      firstStart.month,
      firstStart.day,
      resolvedTimeRange.endHour,
      resolvedTimeRange.endMinute,
    );

    final adjustedEnd = firstEndCandidate.isAfter(firstStart)
        ? firstEndCandidate
        : firstEndCandidate.add(const Duration(hours: 1));

    var recurrenceEndDate = isSingleEvent ? null : academicPeriodEndDate;

    if (!isSingleEvent && recurrenceEndDate == null) {
      notes.add(
        'No detecté fin de ciclo. La serie se guardará sin fecha límite hasta que la edites.',
      );
    }

    if (exactDate != null) {
      final dateStr = '${exactDate.day}/${exactDate.month}/${exactDate.year}';
      if (isSingleEvent) {
        notes.add('Detecté la fecha específica $dateStr para este evento único.');
      } else {
        notes.add('Inicio fijado para la fecha $dateStr.');
      }
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

    // 6. Match project
    String? matchedProjectId;
    final matchedProject = _matchProject(cleanedTitle, existingProjects);
    if (matchedProject != null) {
      matchedProjectId = matchedProject.id;
      notes.add('Vinculado automáticamente a "${matchedProject.name}".');
    }

    // 7. Check conflicts
    var hasConflict = false;
    String? conflictMsg;
    for (final block in existingBlocks) {
      if (resolvedDays.contains(block.start.weekday)) {
        if (_overlapsTime(firstStart, adjustedEnd, block.start, block.end)) {
          hasConflict = true;
          conflictMsg =
              'Conflictúa con "${block.title}" (${_formatTime(block.start)} - ${_formatTime(block.end)})';
          notes.add('⚠️ $conflictMsg');
          break;
        }
      }
    }

    return VoiceScheduleDraft(
      transcript: compactTranscript,
      title: cleanedTitle,
      location: location,
      firstStart: firstStart,
      firstEnd: adjustedEnd,
      weekDays: resolvedDays,
      recurrenceEndDate: recurrenceEndDate,
      isSingleEvent: isSingleEvent,
      linkedProjectId: matchedProjectId,
      hasConflict: hasConflict,
      conflictMessage: conflictMsg,
      notes: notes,
    );
  }

  /// Parses multi-class batch dictations (e.g. "Cálculo lunes de 8 a 10 am; y los martes Física de 10 a 12 pm").
  List<VoiceScheduleDraft> parseBatch(
    String transcript, {
    DateTime? referenceTime,
    Iterable<Project> existingProjects = const [],
    Iterable<ScheduleBlock> existingBlocks = const [],
  }) {
    final reference = referenceTime ?? DateTime.now();
    final compact = _compactWhitespace(transcript);
    if (compact.isEmpty) return [];

    final segments = compact
        .split(
          RegExp(
            r';|\n|\b(?:despues|luego|ademas|tambien|y\s+los|y\s+las|y\s+el|y\s+mi\s+clase|y\s+clase)\b',
            caseSensitive: false,
          ),
        )
        .map((s) => s.trim())
        .where((s) => s.length > 5)
        .toList();

    if (segments.length <= 1) {
      return [
        parse(
          compact,
          referenceTime: reference,
          existingProjects: existingProjects,
          existingBlocks: existingBlocks,
        ),
      ];
    }

    final results = <VoiceScheduleDraft>[];
    for (final segment in segments) {
      final draft = parse(
        segment,
        referenceTime: reference,
        existingProjects: existingProjects,
        existingBlocks: existingBlocks,
      );
      if (draft.canSave) {
        results.add(draft);
      }
    }

    return results.isEmpty
        ? [
            parse(
              compact,
              referenceTime: reference,
              existingProjects: existingProjects,
              existingBlocks: existingBlocks,
            ),
          ]
        : results;
  }

  // ---------------------------------------------------------------------------
  // Specific Date extraction (e.g. "jueves 27 de agosto")
  // ---------------------------------------------------------------------------

  _SpecificDateResult? _extractSpecificDate(
    String normalizedTranscript,
    String rawTranscript,
    DateTime reference,
  ) {
    final match = RegExp(
      r'(?:(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\s+)?(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)(?:\s+de\s+(\d{4}))?',
    ).firstMatch(normalizedTranscript);

    if (match != null) {
      final day = int.tryParse(match.group(2) ?? '');
      final month = _monthFromSpanish(match.group(3) ?? '');
      final rawYear = match.group(4);
      if (day != null && month != null) {
        var year = reference.year;
        if (rawYear != null) {
          year = int.parse(rawYear);
        } else if (month < reference.month ||
            (month == reference.month && day < reference.day - 7)) {
          year += 1;
        }
        final date = _safeDate(year, month, day);
        if (date != null) {
          return _SpecificDateResult(date: date, matchedText: match.group(0) ?? '');
        }
      }
    }

    final slashMatch = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
    ).firstMatch(normalizedTranscript);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1) ?? '');
      final month = int.tryParse(slashMatch.group(2) ?? '');
      final rawYear = slashMatch.group(3);
      if (day != null && month != null && month <= 12) {
        var year = reference.year;
        if (rawYear != null) {
          year = int.parse(rawYear.length == 2 ? '20$rawYear' : rawYear);
        }
        final date = _safeDate(year, month, day);
        if (date != null) {
          return _SpecificDateResult(date: date, matchedText: slashMatch.group(0) ?? '');
        }
      }
    }

    if (RegExp(r'\bpasado\s+manana\b').hasMatch(normalizedTranscript)) {
      return _SpecificDateResult(
        date: reference.add(const Duration(days: 2)),
        matchedText: 'pasado manana',
      );
    }
    if (RegExp(r'(?<!de\s+la\s+|por\s+la\s+)\bmanana\b').hasMatch(normalizedTranscript)) {
      return _SpecificDateResult(
        date: reference.add(const Duration(days: 1)),
        matchedText: 'manana',
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Fraction / Half-hour spoken normalization ("ocho y media" -> "8:30")
  // ---------------------------------------------------------------------------

  String _normalizeSpokenFractions(String transcript) {
    var result = transcript;

    result = result.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\s+y\s+media\b', caseSensitive: false),
      (match) => '${match.group(1)}:30',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\s+y\s+cuarto\b', caseSensitive: false),
      (match) => '${match.group(1)}:15',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\s+y\s+quince\b', caseSensitive: false),
      (match) => '${match.group(1)}:15',
    );
    result = result.replaceAllMapped(
      RegExp(r'\b(\d{1,2})\s+y\s+cuarenta\s+y\s+cinco\b', caseSensitive: false),
      (match) => '${match.group(1)}:45',
    );

    return result;
  }

  // ---------------------------------------------------------------------------
  // Spoken number normalization
  // ---------------------------------------------------------------------------

  static const _spokenNumbers = <String, String>{
    'cero': '0',
    'una': '1',
    'uno': '1',
    'dos': '2',
    'tres': '3',
    'cuatro': '4',
    'cinco': '5',
    'seis': '6',
    'siete': '7',
    'ocho': '8',
    'nueve': '9',
    'diez': '10',
    'once': '11',
    'doce': '12',
    'trece': '13',
    'catorce': '14',
    'quince': '15',
    'dieciseis': '16',
    'diecisiete': '17',
    'dieciocho': '18',
    'diecinueve': '19',
    'veinte': '20',
    'veintiuno': '21',
    'veintidos': '22',
    'veintitres': '23',
    'veinticuatro': '24',
    'mediodia': '12',
    'mediodía': '12',
  };

  String _normalizeSpokenNumbers(String transcript) {
    var result = transcript;
    final sorted = _spokenNumbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final word in sorted) {
      result = result.replaceAllMapped(
        RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false),
        (match) => _spokenNumbers[word.toLowerCase()]!,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Day extraction with fuzzy matching
  // ---------------------------------------------------------------------------

  List<int> _extractWeekDays(String normalizedTranscript) {
    final corrected = _fuzzyCorrectDays(normalizedTranscript);
    final days = <int>{};

    final rangeMatch = RegExp(
      r'\b(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\s+a\s+(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\b',
    ).firstMatch(corrected);

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
      r'\b(lunes|martes|miercoles|jueves|viernes|sabado|domingo)\b',
    ).allMatches(corrected);
    for (final match in allMatches) {
      final weekday = _weekdayFromSpanish(match.group(1) ?? '');
      if (weekday != null) {
        days.add(weekday);
      }
    }

    if (corrected.contains('entre semana')) {
      days.addAll([1, 2, 3, 4, 5]);
    }
    if (corrected.contains('fin de semana') ||
        corrected.contains('fines de semana')) {
      days.addAll([6, 7]);
    }
    if (corrected.contains('todos los dias') || corrected.contains('diario')) {
      days.addAll([1, 2, 3, 4, 5, 6, 7]);
    }

    final ordered = days.toList()..sort();
    return ordered;
  }

  String _fuzzyCorrectDays(String text) {
    const corrections = <String, String>{
      'lune': 'lunes',
      'lumes': 'lunes',
      'marte': 'martes',
      'marque': 'martes',
      'miercole': 'miercoles',
      'mierkoles': 'miercoles',
      'juebe': 'jueves',
      'juebes': 'jueves',
      'jueve': 'jueves',
      'vierne': 'viernes',
      'biernes': 'viernes',
      'sabadoo': 'sabado',
      'savado': 'sabado',
      'domingoo': 'domingo',
    };
    var result = text;
    for (final entry in corrections.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        entry.value,
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Time range extraction — supports exact minutes (8:30 pm, 6:00 am)
  // ---------------------------------------------------------------------------

  _VoiceScheduleTimeRange? _extractTimeRange(String transcript) {
    final match = RegExp(
      r'(?:de\s+)?(?:las?\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm|de\s+la\s+(?:mañana|manana)|de\s+la\s+tarde|de\s+la\s+noche)?\s*(?:a|-|hasta)\s*(?:las?\s+)?(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm|de\s+la\s+(?:mañana|manana)|de\s+la\s+tarde|de\s+la\s+noche)?',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (match == null) {
      return _extractSingleTime(transcript);
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

    // Fix edge case: "10 a 12 pm" means 10:00 am to 12:00 pm (noon)
    if (startHint == null && endHint == 12 && startHourRaw >= 7 && startHourRaw <= 11 && endHourRaw == 12) {
      startHour = startHourRaw;
      endHour = 12;
    } else if (startHint == null && endHint == null) {
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

  _VoiceScheduleTimeRange? _extractSingleTime(String transcript) {
    final match = RegExp(
      r'a\s+las?\s+(\d{1,2})(?::(\d{2}))?\s*(a\.?\s*m\.?|p\.?\s*m\.?|am|pm|de\s+la\s+mañana|de\s+la\s+tarde|de\s+la\s+noche)?',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (match == null) return null;

    final hourRaw = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    if (hourRaw == null) return null;

    final hint = _parseMeridiem(match.group(3));
    var hour = hint != null ? _applyHourHint(hourRaw, hint) : _inferClassHour(hourRaw);
    var endHour = hour + 2;
    if (endHour > 23) endHour = 23;

    return _VoiceScheduleTimeRange(
      startHour: hour,
      startMinute: minute,
      endHour: endHour,
      endMinute: minute,
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

  // ---------------------------------------------------------------------------
  // End Date & Academic Periods ("hasta parciales", "todo el ciclo", "16 semanas")
  // ---------------------------------------------------------------------------

  DateTime? _extractEndDate(String normalizedTranscript, DateTime reference) {
    if (normalizedTranscript.contains('hasta parciales')) {
      return reference.add(const Duration(days: 56));
    }
    if (normalizedTranscript.contains('hasta finales') ||
        normalizedTranscript.contains('todo el ciclo') ||
        normalizedTranscript.contains('todo el semestre') ||
        normalizedTranscript.contains('16 semanas') ||
        normalizedTranscript.contains('semestre completo')) {
      return reference.add(const Duration(days: 112));
    }

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

  // ---------------------------------------------------------------------------
  // Title extraction
  // ---------------------------------------------------------------------------

  String _extractTitle(String transcript, String normalizedTranscript) {
    final titlePatterns = <RegExp>[
      RegExp(
        r'(?:mi\s+)?(?:clase|curso|laboratorio|lab|taller|materia|seminario|catedra|examen|prueba|parcial|final)\s+de\s+(.+?)(?=\s+(?:es|son|lunes|martes|miercoles|jueves|viernes|sabado|domingo|\d{1,2}\s+de|a\s+las|de\s+\d))',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:agrega|agenda|anota|pon|crea|programa|registra)\s+(?:mi\s+)?(?:clase|curso|laboratorio|lab|taller|materia|seminario|catedra|examen|prueba|parcial|final)?\s*(?:de\s+)?(.+?)(?=\s+(?:lunes|martes|miercoles|jueves|viernes|sabado|domingo|\d{1,2}\s+de|a\s+las|de\s+\d))',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:tengo|voy\s+a)\s+(?:clase\s+de\s+|la\s+clase\s+de\s+)?(.+?)(?=\s+(?:los\s+)?(?:lunes|martes|miercoles|jueves|viernes|sabado|domingo|el\s+\d{1,2}|\d{1,2}\s+de|a\s+las|de\s+\d))',
        caseSensitive: false,
      ),
      // Pattern for day BEFORE title, e.g. "martes Física de 10 a 12"
      RegExp(
        r'\b(?:lunes|martes|miercoles|jueves|viernes|sabado|domingo)\s+(?:de\s+)?([A-Za-z0-9áéíóúñÁÉÍÓÚÑ\s]+?)(?=\s+(?:de\s+\d|\d{1,2}|en\s+|por\s+|$))',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?)(?=\s+(?:los\s+)?(?:lunes|martes|miercoles|jueves|viernes|sabado|domingo|el\s+\d{1,2}\s+de|\d{1,2}\s+de\s+enero|\d{1,2}\s+de\s+febrero|\d{1,2}\s+de\s+marzo|\d{1,2}\s+de\s+abril|\d{1,2}\s+de\s+mayo|\d{1,2}\s+de\s+junio|\d{1,2}\s+de\s+julio|\d{1,2}\s+de\s+agosto|\d{1,2}\s+de\s+septiembre|\d{1,2}\s+de\s+octubre|\d{1,2}\s+de\s+noviembre|\d{1,2}\s+de\s+diciembre)\b)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(normalizedTranscript);
      if (match != null) {
        final candidate = match.group(1) ?? '';
        final humanized = _humanize(_cleanTitleCandidate(candidate));
        if (humanized.isNotEmpty && humanized.length > 1) {
          return humanized;
        }
      }
    }

    final firstWeekdayIndex = RegExp(
      r'\b(lunes|martes|miercoles|jueves|viernes|sabado|domingo|\d{1,2}\s+de\s+[a-z]+)\b',
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
    segment = _cleanTitleCandidate(segment);

    return _humanize(segment);
  }

  String _cleanTitleCandidate(String candidate) {
    var result = candidate
        .replaceFirst(
          RegExp(
            r'^(?:agrega|agenda|anota|pon|crea|programa|registra|tengo|voy\s+a)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(?:mi\s+)?(?:la\s+)?(?:clase|curso|laboratorio|lab|taller|materia|seminario|catedra)\s+de\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(?:mi\s+)?(?:la\s+)?(?:clase|curso|laboratorio|lab|taller|materia|seminario|catedra)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(RegExp(r'\s+(?:es|son|los|el|la|las)$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+de$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s+a$', caseSensitive: false), '')
        .trim();
    result = result
        .replaceFirst(RegExp(r'^\s*de\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*la\s+', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^\s*el\s+', caseSensitive: false), '')
        .trim();
    return result;
  }

  // ---------------------------------------------------------------------------
  // Location extraction
  // ---------------------------------------------------------------------------

  String _extractLocation(String transcript, int? lowerBound) {
    final onlineMatch = RegExp(
      r'\b(por\s+zoom|en\s+zoom|en\s+teams|por\s+teams|en\s+meet|por\s+meet|virtual|online)\b',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (onlineMatch != null) {
      return _humanize(onlineMatch.group(1) ?? 'Virtual');
    }

    final matches =
        RegExp(
          r'\ben\s+(?:el\s+)?([^,.;]+?)(?=\s+hasta\b|$)',
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
      r'\b(aula|sal[oó]n|laboratorio|lab\.?|edificio|bloque|piso|torre)\s+([^\s,.;]+(?:\s+[^\s,.;]+)?)',
      caseSensitive: false,
    ).firstMatch(transcript);
    if (directMatch != null) {
      return _humanize(
        '${directMatch.group(1) ?? ''} ${directMatch.group(2) ?? ''}',
      );
    }

    return '';
  }

  // ---------------------------------------------------------------------------
  // Project & Conflict helpers
  // ---------------------------------------------------------------------------

  Project? _matchProject(String title, Iterable<Project> projects) {
    if (title.isEmpty || projects.isEmpty) return null;
    final normTitle = _normalizeForSearch(title);
    for (final project in projects) {
      final normProj = _normalizeForSearch(project.name);
      if (normProj.isEmpty) continue;
      if (normTitle.contains(normProj) || normProj.contains(normTitle)) {
        return project;
      }
    }
    return null;
  }

  bool _overlapsTime(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final aStartMin = aStart.hour * 60 + aStart.minute;
    final aEndMin = aEnd.hour * 60 + aEnd.minute;
    final bStartMin = bStart.hour * 60 + bStart.minute;
    final bEndMin = bEnd.hour * 60 + bEnd.minute;
    return aStartMin < bEndMin && bStartMin < aEndMin;
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Resolution helpers
  // ---------------------------------------------------------------------------

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
    if (hint == null) return rawHour;
    if (hint == 12 && rawHour < 12) return rawHour + 12;
    if (hint == 0 && rawHour == 12) return 0;
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

class _SpecificDateResult {
  final DateTime date;
  final String matchedText;

  const _SpecificDateResult({required this.date, required this.matchedText});
}
