import '../models/project.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../models/focus_session.dart';

class ProfileSnapshot {
  final List<Project> projects;
  final List<Task> tasks;
  final List<ScheduleBlock> scheduleBlocks;
  final FocusSession? focusSession;
  final bool hasCompletedOnboarding;
  final int streakDays;
  final DateTime? lastActiveDay;
  final String? quickProjectId;
  final List<FocusSession> focusHistory;
  final int reminderLeadMinutes;
  final int pomodoroStreakDays;
  final DateTime? lastPomodoroDay;

  const ProfileSnapshot({
    required this.projects,
    required this.tasks,
    required this.scheduleBlocks,
    required this.focusSession,
    required this.hasCompletedOnboarding,
    required this.streakDays,
    required this.lastActiveDay,
    required this.quickProjectId,
    required this.focusHistory,
    required this.reminderLeadMinutes,
    required this.pomodoroStreakDays,
    required this.lastPomodoroDay,
  });

  factory ProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return ProfileSnapshot(
      projects: ((json['projects'] as List?) ?? [])
          .map((item) => Project.fromJson(item as Map<String, dynamic>))
          .toList(),
      tasks: ((json['tasks'] as List?) ?? [])
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList(),
      scheduleBlocks: ((json['schedule'] as List?) ?? [])
          .map((item) => ScheduleBlock.fromJson(item as Map<String, dynamic>))
          .toList(),
      focusSession: json['currentFocusSession'] == null
          ? null
          : FocusSession.fromJson(json['currentFocusSession']),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      streakDays: json['streakDays'] as int? ?? 1,
      lastActiveDay: json['lastActiveDay'] != null
          ? DateTime.parse(json['lastActiveDay'] as String)
          : null,
      quickProjectId: json['quickProjectId'] as String?,
      focusHistory: ((json['focusHistory'] as List?) ?? [])
          .map((item) => FocusSession.fromJson(item as Map<String, dynamic>))
          .toList(),
      reminderLeadMinutes:
          (json['reminderLeadMinutes'] as int?)?.clamp(5, 120) ?? 15,
      pomodoroStreakDays: json['pomodoroStreakDays'] as int? ?? 0,
      lastPomodoroDay: json['lastPomodoroDay'] != null
          ? DateTime.parse(json['lastPomodoroDay'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'projects': projects.map((project) => project.toJson()).toList(),
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'schedule': scheduleBlocks.map((block) => block.toJson()).toList(),
    'currentFocusSession': focusSession?.toJson(),
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'streakDays': streakDays,
    'lastActiveDay': lastActiveDay?.toIso8601String(),
    'quickProjectId': quickProjectId,
    'focusHistory': focusHistory.map((session) => session.toJson()).toList(),
    'reminderLeadMinutes': reminderLeadMinutes,
    'pomodoroStreakDays': pomodoroStreakDays,
    'lastPomodoroDay': lastPomodoroDay?.toIso8601String(),
  };

  factory ProfileSnapshot.empty() => const ProfileSnapshot(
    projects: <Project>[],
    tasks: <Task>[],
    scheduleBlocks: <ScheduleBlock>[],
    focusSession: null,
    hasCompletedOnboarding: false,
    streakDays: 1,
    lastActiveDay: null,
    quickProjectId: null,
    focusHistory: <FocusSession>[],
    reminderLeadMinutes: 15,
    pomodoroStreakDays: 0,
    lastPomodoroDay: null,
  );
}
