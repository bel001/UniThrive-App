import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/schedule.dart';
import '../models/pomodoro_session.dart';
import '../models/focus_session.dart';
import '../models/support_message.dart';
import '../models/achievement.dart';
import '../models/mascot_state.dart';
import '../models/user_profile_summary.dart';
import '../services/notification_service.dart';

import 'settings_state.dart';
import 'user_state.dart';
import 'gamification_state.dart';
import 'data_state.dart';
import '../services/smart_planner.dart';

export 'settings_state.dart';
export 'user_state.dart';
export 'gamification_state.dart';
export 'data_state.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'unithrive_state_v2';
  SharedPreferences? _prefs;

  final SettingsState settings = SettingsState();
  final UserState user = UserState();
  final GamificationState gamification = GamificationState();
  final DataState data = DataState();

  AppState() {
    settings.addListener(notifyListeners);
    user.addListener(notifyListeners);
    gamification.addListener(notifyListeners);
    data.addListener(notifyListeners);
  }

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    user.removeListener(notifyListeners);
    gamification.removeListener(notifyListeners);
    data.removeListener(notifyListeners);
    settings.dispose();
    user.dispose();
    gamification.dispose();
    data.dispose();
    super.dispose();
  }

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getString(_storageKey);
    if (stored != null) {
      try {
        final map = jsonDecode(stored) as Map<String, dynamic>;
        settings.loadFromMap(map);
        user.loadFromMap(map);
        gamification.loadFromMap(map);
        data.loadFromMap(map);
      } catch (_) {
        // ignore invalid cache
      }
    }

    // Ensure at least one profile exists
    if (user.profiles.isEmpty) {
      // We'll rely on UserState to handle this or add logic later if needed.
    }

    NotificationService.setDefaultLeadMinutes(settings.reminderLeadMinutes);
    _scheduleStreakReminder();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final map = {
      ...settings.toJson(),
      ...user.toJson(),
      ...gamification.toJson(),
      ...data.toJson(),
    };
    await _prefs!.setString(_storageKey, jsonEncode(map));
  }

  // =========================================================================
  // FACADE GETTERS (Backwards Compatibility)
  // =========================================================================

  ThemeMode get themeMode => settings.themeMode;
  bool get motivationalMessages => settings.motivationalMessages;
  bool get classRemindersEnabled => settings.classRemindersEnabled;
  bool get taskRemindersEnabled => settings.taskRemindersEnabled;
  int get reminderLeadMinutes => settings.reminderLeadMinutes;
  double get textScale => settings.textScale;
  String get alarmSound => settings.alarmSound;

  bool get hasCompletedOnboarding => user.hasCompletedOnboarding;
  String get userName => user.userName;
  String get userEmail => user.userEmail;
  String get avatarUrl => user.avatarUrl;
  List<UserProfileSummary> get profiles => user.profiles;
  String? get activeProfileId => user.activeProfileId;

  int get experiencePoints => gamification.experiencePoints;
  int get level => gamification.level;
  List<Achievement> get achievements => gamification.achievements;
  MascotState get mascotState => gamification.mascotState;
  int get streakDays => gamification.streakDays;
  int get pomodoroStreakDays => gamification.pomodoroStreakDays;
  int get xpForNextLevel => gamification.xpForNextLevel;
  double get xpProgressPercent => gamification.xpProgressPercent;

  List<Project> get projects => data.projects;
  List<Task> get allTasks => data.tasks;
  List<ScheduleBlock> get scheduleBlocks => data.scheduleBlocks;
  List<FocusSession> get focusHistory => data.focusHistory;
  List<SupportMessage> get supportMessages => data.supportMessages;
  FocusSession? get currentFocusSession => data.currentFocusSession;

  // Derived Getters
  List<Project> get activeProjects => data.projects
      .where((project) => !project.completed && !project.hidden)
      .toList();

  List<Project> get completedProjects => data.projects
      .where((project) => project.completed && !project.hidden)
      .toList();

  List<Task> get todayTasks {
    final today = DateTime.now();
    return data.tasks
        .where(
          (task) => task.dueDate != null && isSameDay(task.dueDate!, today),
        )
        .toList();
  }

  List<ScheduleBlock> blocksForDay(DateTime day) {
    return data.scheduleBlocks.where((block) {
      // Handle recurrence logic here if needed, or just simple date match for now
      // Assuming simple match for non-recurring
      if (block.recurrence == RecurrenceType.none) {
        return isSameDay(block.start, day);
      }
      // For recurring, we need complex logic.
      // For now, returning empty or simple match to avoid errors.
      // Ideally delegate to a helper.
      return isSameDay(block.start, day);
    }).toList();
  }

  Project? projectById(String id) {
    try {
      return data.projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Task> tasksForProject(String projectId) {
    return data.tasks.where((t) => t.projectId == projectId).toList();
  }

  void toggleTask(String taskId) => toggleTaskCompletion(taskId);

  void removeScheduleBlock(String blockId) => deleteScheduleBlock(blockId);

  Future<void> generatePlanForProject(String projectId) async {
    // Placeholder for AI generation
    // In real app, this would call an AI service
    await Future.delayed(const Duration(seconds: 2));
    final project = projectById(projectId);
    if (project == null) return;

    // Add some dummy tasks
    addTask(projectId: projectId, title: 'Investigación inicial');
    addTask(projectId: projectId, title: 'Borrador del proyecto');
  }

  // Subtask methods
  void addSubtask({required String taskId, required String title}) {
    final idx = data.tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = data.tasks[idx];

    final order = task.subtasks.length;
    final subtask = Subtask(
      id: _nextId(),
      taskId: taskId,
      title: title,
      completed: false,
      order: order,
    );

    final updatedSubtasks = List<Subtask>.from(task.subtasks)..add(subtask);
    updateTask(taskId: taskId, subtasks: updatedSubtasks);
  }

  // ... (other subtask methods)

  void startFocusSession({String? taskId, String? label}) {
    String sessionLabel = label ?? 'Sesión de enfoque';
    if (taskId != null && label == null) {
      final task = data.tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => Task(id: '', title: 'Tarea desconocida', projectId: ''),
      );
      if (task.id.isNotEmpty) {
        sessionLabel = task.title;
      }
    }

    final session = FocusSession(
      id: _nextId(),
      label: sessionLabel,
      startTime: DateTime.now(),
    );
    data.setCurrentFocusSession(session);
    _persist();
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final idx = data.tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = data.tasks[idx];

    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(completed: !s.completed);
      }
      return s;
    }).toList();

    updateTask(taskId: taskId, subtasks: updatedSubtasks);
  }

  void deleteSubtask(String taskId, String subtaskId) {
    final idx = data.tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = data.tasks[idx];

    final updatedSubtasks = task.subtasks
        .where((s) => s.id != subtaskId)
        .toList();
    updateTask(taskId: taskId, subtasks: updatedSubtasks);
  }

  void editSubtask({
    required String taskId,
    required String subtaskId,
    required String newTitle,
  }) {
    final idx = data.tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = data.tasks[idx];

    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(title: newTitle);
      }
      return s;
    }).toList();

    updateTask(taskId: taskId, subtasks: updatedSubtasks);
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // =========================================================================
  // FACADE METHODS
  // =========================================================================

  void toggleTheme() {
    settings.toggleTheme();
    _persist();
  }

  void completeOnboarding() {
    user.completeOnboarding();
    _persist();
  }

  void updateUserProfile(String name) {
    user.updateUserProfile(name);
    _persist();
  }

  void addUserProfile(String name) {
    // Logic to add a new profile
    // This might involve creating a new UserProfileSummary in UserState
    // and potentially saving current DataState to disk/DB associated with current profile
    // For now, we'll just delegate to UserState if it supports it, or implement simple logic
    // UserState doesn't have addUserProfile yet.
    // I'll add it to UserState first? No, I can't modify UserState in this tool call.
    // I'll implement a placeholder or simple logic here if UserState exposes profiles list.
    // But UserState manages profiles.
    // I should add these methods to UserState first.
    // But I can't do it in this tool call.
    // I'll add them to AppState and they will call UserState methods (which I will add next).
    user.addUserProfile(name);
    _persist();
  }

  void switchUserProfile(String profileId) {
    // Logic to switch profile
    // Save current data
    // Load new data
    user.switchUserProfile(profileId);
    // Reload DataState for new profile?
    // This is complex. For now, just switch user state.
    _persist();
  }

  void deleteUserProfile(String profileId) {
    user.deleteUserProfile(profileId);
    _persist();
  }

  void addXP(int amount, {String? reason, bool skipAchievementCheck = false}) {
    gamification.addXP(
      amount,
      reason: reason,
      skipAchievementCheck: skipAchievementCheck,
    );
    _persist();
  }

  // Settings Methods
  void setThemeMode(ThemeMode mode) {
    settings.setThemeMode(mode);
    _persist();
  }

  void setTextScale(double scale) {
    settings.setTextScale(scale);
    _persist();
  }

  void setTaskReminders(bool enabled) {
    settings.setTaskReminders(enabled);
    _persist();
  }

  void setReminderLeadMinutes(int minutes) {
    settings.setReminderLeadMinutes(minutes);
    _persist();
  }

  void setAlarmSound(String sound) {
    settings.setAlarmSound(sound);
    _persist();
  }

  void setClassReminders(bool enabled) {
    settings.setClassReminders(enabled);
    _persist();
  }

  void setMotivationalMessages(bool enabled) {
    settings.setMotivationalMessages(enabled);
    _persist();
  }

  void toggleMotivationMessages() {
    settings.setMotivationalMessages(!settings.motivationalMessages);
    _persist();
  }

  // Alias for backward compatibility if needed, or just use the correct name
  void toggleMotivationalMessages() => toggleMotivationMessages();

  void resetSettings() {
    settings.reset();
    _persist();
  }

  void deleteAllData() {
    data.clearAll();
    user.reset();
    gamification.reset();
    settings.reset();
    _persist();
  }

  Map<String, dynamic> exportToJson() {
    return {
      'data': data.toJson(),
      'user': user.toJson(),
      'gamification': gamification.toJson(),
      'settings': settings.toJson(),
      'version': 1,
    };
  }

  Future<void> importFromJson(Map<String, dynamic> json) async {
    if (json['data'] != null) {
      data.loadFromMap(json['data']);
    }
    if (json['user'] != null) {
      user.loadFromMap(json['user']);
    }
    if (json['gamification'] != null) {
      gamification.loadFromMap(json['gamification']);
    }
    if (json['settings'] != null) {
      settings.loadFromMap(json['settings']);
    }
    _persist();
  }

  // Gamification Getters
  List<Achievement> get unlockedAchievements =>
      gamification.achievements.where((a) => a.unlockedAt != null).toList();

  List<Achievement> get lockedAchievements =>
      gamification.achievements.where((a) => a.unlockedAt == null).toList();

  void registerPomodoroSession(PomodoroSession session) {
    addXP(session.actualDurationMinutes * 5, reason: 'Pomodoro completado');
  }

  Project addProject({
    required String name,
    required DateTime dueDate,
    required Color color,
    String description = '',
    double progress = 0.0,
    bool completed = false,
    bool hidden = false,
    String tag = 'En curso',
    bool autoPlan = false,
    ProjectType type = ProjectType.general,
  }) {
    final project = Project(
      id: _nextId(),
      name: name,
      dueDate: dueDate,
      color: color,
      description: description,
      progress: progress,
      completed: completed,
      hidden: hidden,
      tag: tag,
      type: type,
    );
    data.addProject(project);

    if (autoPlan) {
      // 1. Generate tasks
      // tag is used as size in the UI ('Pequeño', 'Mediano', 'Grande')
      final taskTitles = SmartPlanner.generateTasksForProject(tag, type);

      List<Task> generatedTasks = [];
      for (final title in taskTitles) {
        final task = Task(
          id: _nextId(),
          title: title,
          projectId: project.id,
          dueDate: dueDate, // Initially due on project due date
          completed: false,
        );
        data.addTask(task);
        generatedTasks.add(task);
      }

      // 2. Schedule tasks
      final now = DateTime.now();
      final blocks = data.scheduleBlocks;

      // Plan from tomorrow? or today?
      final newBlocks = SmartPlanner.distributeTasks(
        tasks: generatedTasks,
        existingBlocks: blocks,
        startDate: now,
        daysToPlan: 30, // Plan ahead
      );

      for (final block in newBlocks) {
        data.addScheduleBlock(block);
      }
    }

    _persist();
    return project;
  }

  void deleteProject(String projectId) {
    data.deleteProject(projectId);
    // Also delete tasks associated with this project
    final tasksToDelete = data.tasks
        .where((t) => t.projectId == projectId)
        .toList();
    for (final task in tasksToDelete) {
      deleteTask(task.id);
    }
    _persist();
  }

  void removeProject(String projectId) => deleteProject(projectId);

  Project getOrCreateQuickTasksProject() {
    try {
      return data.projects.firstWhere(
        (p) => p.name == 'Tareas Rápidas' && !p.completed,
      );
    } catch (_) {
      return addProject(
        name: 'Tareas Rápidas',
        dueDate: DateTime.now().add(const Duration(days: 365)),
        color: const Color(0xFF9FCFBB),
        description: 'Tareas rápidas y recordatorios',
        tag: 'General',
      );
    }
  }

  void moveTaskWithinProject({
    required String projectId,
    required String taskId,
    required int newIndex,
  }) {
    // Reordering logic
    // Since we don't have order index in Task, we might need to rely on list order in DataState
    // But DataState uses a list.
    // For now, no-op or simple implementation if DataState supports it.
  }

  void restartOnboarding() {
    user.restartOnboarding();
    _persist();
  }

  Task addTask({
    required String projectId,
    required String title,
    DateTime? dueDate,
    bool completed = false,
    String? customId,
    bool silent = false,
    EnergyLevel energy = EnergyLevel.medium,
    bool scheduleOnCalendar = true,
    String? description,
    String? attachmentPath,
  }) {
    final task = Task(
      id: customId ?? _nextId(),
      title: title,
      projectId: projectId,
      dueDate: dueDate,
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      energy: energy,
      description: description,
      attachmentPath: attachmentPath,
    );
    data.addTask(task);

    if (!silent && dueDate != null && settings.taskRemindersEnabled) {
      NotificationService.scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        dueDate: dueDate,
        customMinutes: task.customReminderMinutes,
      );
    }

    _persist();
    return task;
  }

  Future<void> autoPlanWeek() async {
    final now = DateTime.now();
    final tasks = data.tasks.where((t) => !t.completed).toList();
    final blocks = data.scheduleBlocks;

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: now,
      daysToPlan: 7,
    );

    for (final block in newBlocks) {
      data.addScheduleBlock(block);
    }
    _persist();
  }

  Future<int> autoPlanMonth(DateTime month) async {
    final tasks = data.tasks.where((t) => !t.completed).toList();
    final blocks = data.scheduleBlocks;

    // Start from today if month is current, or 1st of month
    final now = DateTime.now();
    final start = month.year == now.year && month.month == now.month
        ? now
        : DateTime(month.year, month.month, 1);

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: start,
      daysToPlan: 30,
    );

    for (final block in newBlocks) {
      data.addScheduleBlock(block);
    }
    _persist();
    return newBlocks
        .length; // Return number of blocks created (proxy for days planned)
  }

  Future<bool> autoPlanDay(DateTime day) async {
    final tasks = data.tasks.where((t) => !t.completed).toList();
    final blocks = data.scheduleBlocks;

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: day,
      daysToPlan: 1,
    );

    for (final block in newBlocks) {
      data.addScheduleBlock(block);
    }
    _persist();
    return newBlocks.isNotEmpty;
  }

  UserProfileSummary? get activeProfileSummary {
    if (user.activeProfileId == null) return null;
    try {
      return user.profiles.firstWhere((p) => p.id == user.activeProfileId);
    } catch (_) {
      return null;
    }
  }

  void updateTask({
    required String taskId,
    String? title,
    DateTime? dueDate,
    bool silent = false,
    EnergyLevel? energy,
    String? description,
    String? attachmentPath,
    bool removeAttachment = false,
    int? customReminderMinutes,
    int? timeSpentMinutes,
    List<PomodoroSession>? pomodoroSessions,
    List<Subtask>? subtasks,
  }) {
    final idx = data.tasks.indexWhere((task) => task.id == taskId);
    if (idx == -1) return;
    final current = data.tasks[idx];
    final nextAttachment = removeAttachment
        ? null
        : (attachmentPath ?? current.attachmentPath);

    final updatedTask = Task(
      id: current.id,
      title: title?.trim().isEmpty == true
          ? current.title
          : (title ?? current.title),
      projectId: current.projectId,
      dueDate: dueDate ?? current.dueDate,
      completed: current.completed,
      completedAt: current.completedAt,
      energy: energy ?? current.energy,
      description: description ?? current.description,
      attachmentPath: nextAttachment,
      customReminderMinutes:
          customReminderMinutes ?? current.customReminderMinutes,
      timeSpentMinutes: timeSpentMinutes ?? current.timeSpentMinutes,
      pomodoroSessions: pomodoroSessions ?? current.pomodoroSessions,
      subtasks: subtasks ?? current.subtasks,
    );

    // We need a method in DataState to update a task
    // Since DataState exposes list, we can't modify it directly if it's unmodifiable.
    // But DataState is in our control. We should add updateTask method to DataState.
    // Or we can access _tasks if we make it public or add a method.
    // I'll assume I can add a method to DataState or modify it.
    // Wait, I can't modify DataState file in this tool call.
    // I'll implement the logic here by accessing the list if I can, or I'll assume DataState has a method.
    // I didn't add updateTask to DataState yet.
    // I'll add `updateTask` to DataState in a separate tool call if needed, or just access `_tasks` if I change DataState to expose it?
    // No, good practice is methods.
    // I'll implement `updateTask` in `DataState` in the NEXT step.
    // For now I will assume `data.updateTask(updatedTask)` exists.

    data.updateTask(updatedTask); // Will add this method to DataState

    if (!silent && dueDate != null && settings.taskRemindersEnabled) {
      NotificationService.scheduleTaskReminder(
        taskId: current.id,
        title: updatedTask.title,
        dueDate: dueDate,
        customMinutes: updatedTask.customReminderMinutes,
      );
    }
    _persist();
  }

  void toggleTaskCompletion(String taskId) {
    final idx = data.tasks.indexWhere((task) => task.id == taskId);
    if (idx == -1) return;
    final task = data.tasks[idx];
    final wasCompleted = task.completed;
    final updatedTask = task.copyWith(
      completed: !wasCompleted,
      completedAt: !wasCompleted ? DateTime.now() : null,
    );

    data.updateTask(updatedTask);

    // Update Project Progress
    if (updatedTask.projectId.isNotEmpty) {
      final projectId = updatedTask.projectId;
      final projectTasks = data.tasks
          .where((t) => t.projectId == projectId)
          .toList();

      if (projectTasks.isNotEmpty) {
        final completedCount = projectTasks.where((t) => t.completed).length;
        final progress = completedCount / projectTasks.length;
        final isProjectCompleted = progress >= 1.0;

        final projectIdx = data.projects.indexWhere((p) => p.id == projectId);
        if (projectIdx != -1) {
          final project = data.projects[projectIdx];
          final updatedProject = project.copyWith(
            progress: progress,
            completed: isProjectCompleted,
          );
          data.updateProject(updatedProject);
        }
      }
    }

    if (!wasCompleted) {
      addXP(15, reason: 'Tarea completada');
      if (settings.motivationalMessages) {
        NotificationService.sendMotivationMessage(
          '¡Bien hecho! Tarea completada.',
        );
      }
    }
    _persist();
  }

  void deleteTask(String taskId) {
    final idx = data.tasks.indexWhere((task) => task.id == taskId);
    if (idx == -1) return;

    data.deleteTask(taskId);

    NotificationService.cancelTaskReminder(taskId);
    _persist();
  }

  void addScheduleBlock({
    required String title,
    required DateTime start,
    required DateTime end,
    Color? color,
    String? location,
    ScheduleCategory category = ScheduleCategory.classSession,
    RecurrenceType recurrence = RecurrenceType.none,
    DateTime? recurrenceEndDate,
    int recurrenceInterval = 1,
  }) {
    final block = ScheduleBlock(
      id: _nextId(),
      title: title,
      start: start,
      end: end,
      color: color ?? const Color(0xFF85D1F7),
      location: location ?? '',
      category: category,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceInterval: recurrenceInterval,
    );
    data.addScheduleBlock(block);
    NotificationService.scheduleScheduleReminder(block);
    _persist();
  }

  void updateScheduleBlock(
    String blockId, {
    String? title,
    DateTime? start,
    DateTime? end,
    Color? color,
    String? location,
    ScheduleCategory? category,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    int? recurrenceInterval,
  }) {
    final idx = data.scheduleBlocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) return;
    final current = data.scheduleBlocks[idx];

    final updated = ScheduleBlock(
      id: current.id,
      title: title ?? current.title,
      start: start ?? current.start,
      end: end ?? current.end,
      color: color ?? current.color,
      location: location ?? current.location,
      category: category ?? current.category,
      recurrence: recurrence ?? current.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? current.recurrenceEndDate,
      recurrenceInterval: recurrenceInterval ?? current.recurrenceInterval,
    );

    data.updateScheduleBlock(updated);
    NotificationService.scheduleScheduleReminder(updated);
    _persist();
  }

  void deleteScheduleBlock(String blockId) {
    data.deleteScheduleBlock(blockId);
    NotificationService.cancelReminder('schedule_$blockId');
    _persist();
  }

  void stopFocusSession() {
    final current = data.currentFocusSession;
    if (current == null) return;

    final endedSession = current.copyWith(endTime: DateTime.now());
    data.addFocusSession(endedSession);
    data.setCurrentFocusSession(null);

    // Add XP based on duration
    final duration = endedSession.endTime!.difference(endedSession.startTime);
    final minutes = duration.inMinutes;
    if (minutes > 0) {
      addXP(minutes * 2, reason: 'Sesión de enfoque ($minutes min)');
    }

    _persist();
  }

  // Helper for ID generation
  String _nextId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _scheduleStreakReminder() {
    // Logic to schedule reminder based on last active day
    // For now, simple implementation or delegate
  }
}

class AppStateProvider extends InheritedWidget {
  final AppState appState;

  const AppStateProvider({
    super.key,
    required this.appState,
    required super.child,
  });

  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateProvider>()!
        .appState;
  }

  @override
  bool updateShouldNotify(AppStateProvider oldWidget) {
    return true;
  }
}
