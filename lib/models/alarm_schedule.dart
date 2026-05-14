enum AlarmRepeatType { once, daily, weekly }

class AlarmSchedule {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final bool enabled;
  final AlarmRepeatType repeatType;
  final List<int> weekDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? pausedUntil;
  final List<String> skippedDateKeys;
  final int snoozeMinutes;
  final int maxSnoozes;
  final bool vibrate;
  final String? soundAssetPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlarmSchedule({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.createdAt,
    required this.updatedAt,
    this.enabled = true,
    this.repeatType = AlarmRepeatType.once,
    this.weekDays = const [],
    this.startDate,
    this.endDate,
    this.pausedUntil,
    this.skippedDateKeys = const [],
    this.snoozeMinutes = 10,
    this.maxSnoozes = 3,
    this.vibrate = true,
    this.soundAssetPath,
  });

  AlarmSchedule copyWith({
    String? title,
    int? hour,
    int? minute,
    bool? enabled,
    AlarmRepeatType? repeatType,
    List<int>? weekDays,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    DateTime? Function()? pausedUntil,
    List<String>? skippedDateKeys,
    int? snoozeMinutes,
    int? maxSnoozes,
    bool? vibrate,
    String? Function()? soundAssetPath,
    DateTime? updatedAt,
  }) {
    return AlarmSchedule(
      id: id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      repeatType: repeatType ?? this.repeatType,
      weekDays: _normalizeWeekDays(weekDays ?? this.weekDays),
      startDate: startDate == null ? this.startDate : _dateOnly(startDate()),
      endDate: endDate == null ? this.endDate : _dateOnly(endDate()),
      pausedUntil: pausedUntil == null ? this.pausedUntil : pausedUntil(),
      skippedDateKeys: skippedDateKeys ?? this.skippedDateKeys,
      snoozeMinutes: (snoozeMinutes ?? this.snoozeMinutes).clamp(1, 60),
      maxSnoozes: (maxSnoozes ?? this.maxSnoozes).clamp(0, 10),
      vibrate: vibrate ?? this.vibrate,
      soundAssetPath: soundAssetPath == null
          ? this.soundAssetPath
          : _blankToNull(soundAssetPath()),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory AlarmSchedule.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return AlarmSchedule(
      id: json['id'] as String,
      title: (json['title'] as String? ?? 'Alarma').trim().isEmpty
          ? 'Alarma'
          : (json['title'] as String? ?? 'Alarma').trim(),
      hour: (json['hour'] as int? ?? 7).clamp(0, 23),
      minute: (json['minute'] as int? ?? 0).clamp(0, 59),
      enabled: json['enabled'] as bool? ?? true,
      repeatType: _repeatTypeFromString(json['repeatType'] as String?),
      weekDays: _normalizeWeekDays((json['weekDays'] as List?)?.cast<int>()),
      startDate: _parseDateOnly(json['startDate']),
      endDate: _parseDateOnly(json['endDate']),
      pausedUntil: _parseDateTime(json['pausedUntil']),
      skippedDateKeys:
          (json['skippedDateKeys'] as List?)?.whereType<String>().toList() ??
          const [],
      snoozeMinutes: (json['snoozeMinutes'] as int? ?? 10).clamp(1, 60),
      maxSnoozes: (json['maxSnoozes'] as int? ?? 3).clamp(0, 10),
      vibrate: json['vibrate'] as bool? ?? true,
      soundAssetPath: _blankToNull(json['soundAssetPath'] as String?),
      createdAt: _parseDateTime(json['createdAt']) ?? now,
      updatedAt: _parseDateTime(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'repeatType': repeatType.name,
    'weekDays': weekDays,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'pausedUntil': pausedUntil?.toIso8601String(),
    'skippedDateKeys': skippedDateKeys,
    'snoozeMinutes': snoozeMinutes,
    'maxSnoozes': maxSnoozes,
    'vibrate': vibrate,
    'soundAssetPath': soundAssetPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  DateTime? nextOccurrence({DateTime? from}) {
    final occurrences = occurrencesBetween(
      from ?? DateTime.now(),
      (from ?? DateTime.now()).add(const Duration(days: 30)),
    );
    return occurrences.isEmpty ? null : occurrences.first;
  }

  List<DateTime> occurrencesBetween(DateTime from, DateTime until) {
    if (!enabled || !until.isAfter(from)) return const [];
    final effectiveStart = startDate == null ? _dateOnly(from)! : startDate!;
    final effectiveEnd = endDate;
    final pauseEnd = pausedUntil;
    final results = <DateTime>[];
    var cursor = _dateOnly(from)!;
    final lastDay = _dateOnly(until)!;

    while (!cursor.isAfter(lastDay)) {
      final candidate = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        hour,
        minute,
      );
      if (candidate.isAfter(from) &&
          !candidate.isAfter(until) &&
          !cursor.isBefore(effectiveStart) &&
          (effectiveEnd == null || !cursor.isAfter(effectiveEnd)) &&
          (pauseEnd == null || candidate.isAfter(pauseEnd)) &&
          _matchesRepeat(cursor) &&
          !skippedDateKeys.contains(dateKey(candidate))) {
        results.add(candidate);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return results;
  }

  bool _matchesRepeat(DateTime day) {
    switch (repeatType) {
      case AlarmRepeatType.once:
        final anchor = startDate ?? _dateOnly(createdAt)!;
        return _sameDay(day, anchor);
      case AlarmRepeatType.daily:
        return true;
      case AlarmRepeatType.weekly:
        final days = weekDays.isEmpty ? [day.weekday] : weekDays;
        return days.contains(day.weekday);
    }
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get repeatLabel {
    switch (repeatType) {
      case AlarmRepeatType.once:
        return 'Una vez';
      case AlarmRepeatType.daily:
        return 'Diaria';
      case AlarmRepeatType.weekly:
        return weekDays.isEmpty ? 'Semanal' : 'Semanal (${weekDays.length})';
    }
  }

  static String dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

AlarmRepeatType _repeatTypeFromString(String? value) {
  return AlarmRepeatType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => AlarmRepeatType.once,
  );
}

List<int> _normalizeWeekDays(List<int>? days) {
  final normalized =
      (days ?? const <int>[])
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .toSet()
          .toList()
        ..sort();
  return normalized;
}

DateTime? _parseDateOnly(dynamic value) {
  final parsed = _parseDateTime(value);
  if (parsed == null) return null;
  return _dateOnly(parsed);
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}

DateTime? _dateOnly(DateTime? date) {
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day);
}

String? _blankToNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
