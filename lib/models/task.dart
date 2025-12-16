import 'subtask.dart';
import 'pomodoro_session.dart';

enum EnergyLevel { low, medium, high }

class Task {
  final String id;
  final String title;
  final String projectId;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;
  final EnergyLevel energy;
  final String? description;
  final String? attachmentPath;
  final List<Subtask> subtasks;
  final int? customReminderMinutes; // null = use global default
  final int timeSpentMinutes; // Total time spent on this task
  final List<PomodoroSession> pomodoroSessions; // History of Pomodoro sessions

  const Task({
    required this.id,
    required this.title,
    required this.projectId,
    this.dueDate,
    this.completed = false,
    this.completedAt,
    this.energy = EnergyLevel.medium,
    this.description,
    this.attachmentPath,
    this.subtasks = const [],
    this.customReminderMinutes,
    this.timeSpentMinutes = 0,
    this.pomodoroSessions = const [],
  });

  Task copyWith({
    String? title,
    String? projectId,
    DateTime? dueDate,
    bool? completed,
    DateTime? completedAt,
    EnergyLevel? energy,
    String? description,
    String? attachmentPath,
    List<Subtask>? subtasks,
    int? customReminderMinutes,
    int? timeSpentMinutes,
    List<PomodoroSession>? pomodoroSessions,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      projectId: projectId ?? this.projectId,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      energy: energy ?? this.energy,
      description: description ?? this.description,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      subtasks: subtasks ?? this.subtasks,
      customReminderMinutes:
          customReminderMinutes ?? this.customReminderMinutes,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      projectId: json['projectId'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      energy: _energyFromString(json['energy'] as String?),
      description: json['description'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
      subtasks:
          (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      customReminderMinutes: json['customReminderMinutes'] as int?,
      timeSpentMinutes: json['timeSpentMinutes'] as int? ?? 0,
      pomodoroSessions:
          (json['pomodoroSessions'] as List<dynamic>?)
              ?.map((s) => PomodoroSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'projectId': projectId,
    'dueDate': dueDate?.toIso8601String(),
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'energy': energy.name,
    'description': description,
    'attachmentPath': attachmentPath,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'customReminderMinutes': customReminderMinutes,
    'timeSpentMinutes': timeSpentMinutes,
    'pomodoroSessions': pomodoroSessions.map((s) => s.toJson()).toList(),
  };
}

extension TaskHelpers on Task {
  /// Returns completion percentage based on subtasks (0.0 to 1.0)
  double get completionPercent {
    if (subtasks.isEmpty) return completed ? 1.0 : 0.0;
    final completedCount = subtasks.where((s) => s.completed).length;
    return completedCount / subtasks.length;
  }

  /// Number of completed subtasks
  int get completedSubtasksCount {
    return subtasks.where((s) => s.completed).length;
  }

  String get dueLabel {
    if (dueDate == null) return 'Sin fecha';
    return '${dueDate!.day}/${dueDate!.month} · ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
  }

  String get energyLabel {
    switch (energy) {
      case EnergyLevel.low:
        return 'Baja energía';
      case EnergyLevel.medium:
        return 'Energía media';
      case EnergyLevel.high:
        return 'Energía alta';
    }
  }
}

EnergyLevel _energyFromString(String? value) {
  switch (value) {
    case 'low':
      return EnergyLevel.low;
    case 'high':
      return EnergyLevel.high;
    default:
      return EnergyLevel.medium;
  }
}
