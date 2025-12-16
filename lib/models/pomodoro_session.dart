class PomodoroSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDurationMinutes; // Usually 25 for work, 5 for break
  final int actualDurationMinutes; // Real time worked
  final bool wasCompleted; // Did they finish the full session?
  final bool isBreak; // false = work session, true = break session

  const PomodoroSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.plannedDurationMinutes,
    required this.actualDurationMinutes,
    this.wasCompleted = false,
    this.isBreak = false,
  });

  PomodoroSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDurationMinutes,
    int? actualDurationMinutes,
    bool? wasCompleted,
    bool? isBreak,
  }) {
    return PomodoroSession(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      isBreak: isBreak ?? this.isBreak,
    );
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      plannedDurationMinutes: json['plannedDurationMinutes'] as int,
      actualDurationMinutes: json['actualDurationMinutes'] as int,
      wasCompleted: json['wasCompleted'] as bool? ?? false,
      isBreak: json['isBreak'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'plannedDurationMinutes': plannedDurationMinutes,
    'actualDurationMinutes': actualDurationMinutes,
    'wasCompleted': wasCompleted,
    'isBreak': isBreak,
  };
}
