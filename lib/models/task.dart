import 'subtask.dart';
import 'pomodoro_session.dart';

enum EnergyLevel { low, medium, high }

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get priorityLabel {
    switch (this) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }
}

class Task {
  final String id;
  final String title;
  final String projectId;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;
  final EnergyLevel energy;
  final TaskPriority priority;
  final String? description;

  /// Rutas de archivos locales o enlaces. El primer elemento mantiene
  /// compatibilidad con el antiguo campo único `attachmentPath`.
  final List<String> attachments;
  final List<String> labels;
  final List<Subtask> subtasks;
  final int? customReminderMinutes; // null = use global default
  final int timeSpentMinutes; // Total time spent on this task
  final List<PomodoroSession> pomodoroSessions; // History of Pomodoro sessions

  /// Compatibilidad: primer adjunto (o null si no hay).
  String? get attachmentPath =>
      attachments.isEmpty ? null : attachments.first;

  Task({
    required this.id,
    required this.title,
    required this.projectId,
    this.dueDate,
    this.completed = false,
    this.completedAt,
    this.energy = EnergyLevel.medium,
    this.priority = TaskPriority.medium,
    this.description,
    String? attachmentPath,
    List<String>? attachments,
    this.labels = const [],
    this.subtasks = const [],
    this.customReminderMinutes,
    this.timeSpentMinutes = 0,
    this.pomodoroSessions = const [],
  }) : attachments =
           attachments ??
           (attachmentPath != null ? [attachmentPath] : const <String>[]);

  Task copyWith({
    String? title,
    String? projectId,
    DateTime? dueDate,
    bool? completed,
    DateTime? completedAt,
    EnergyLevel? energy,
    TaskPriority? priority,
    String? description,
    String? attachmentPath,
    List<String>? attachments,
    List<String>? labels,
    List<Subtask>? subtasks,
    int? customReminderMinutes,
    int? timeSpentMinutes,
    List<PomodoroSession>? pomodoroSessions,
  }) {
    // Semántica legacy: si se pasa attachmentPath, reemplaza/agrega el adjunto.
    List<String>? nextAttachments = attachments ?? this.attachments;
    if (attachments == null && attachmentPath != null) {
      nextAttachments = this.attachments.isEmpty
          ? [attachmentPath]
          : [attachmentPath, ...this.attachments.sublist(1)];
    }
    return Task(
      id: id,
      title: title ?? this.title,
      projectId: projectId ?? this.projectId,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      energy: energy ?? this.energy,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      attachments: nextAttachments,
      labels: labels ?? this.labels,
      subtasks: subtasks ?? this.subtasks,
      customReminderMinutes:
          customReminderMinutes ?? this.customReminderMinutes,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final legacyAttachment = json['attachmentPath'] as String?;
    final parsedAttachments =
        (json['attachments'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            (legacyAttachment != null ? [legacyAttachment] : <String>[]);
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
      priority: _priorityFromString(json['priority'] as String?),
      description: json['description'] as String?,
      attachments: parsedAttachments,
      labels:
          (json['labels'] as List<dynamic>?)
              ?.whereType<String>()
              .map((label) => label.trim())
              .where((label) => label.isNotEmpty)
              .toList() ??
          [],
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
    'priority': priority.name,
    'description': description,
    'attachmentPath': attachmentPath,
    'attachments': attachments,
    'labels': labels,
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

  String get priorityLabel {
    return priority.priorityLabel;
  }

  bool get isOverdue {
    if (completed || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueSoon {
    if (completed || dueDate == null) return false;
    final now = DateTime.now();
    final diff = dueDate!.difference(now);
    return !diff.isNegative && diff <= const Duration(hours: 24);
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

TaskPriority _priorityFromString(String? value) {
  switch (value) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'urgent':
      return TaskPriority.urgent;
    default:
      return TaskPriority.medium;
  }
}
