import 'dart:math';

import 'package:flutter/material.dart';

import '../models/alarm_schedule.dart';
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
import '../services/alarm_service.dart';
import '../services/app_state_repository.dart';
import '../services/notification_service.dart';

import 'settings_state.dart';
import 'user_state.dart';
import 'gamification_state.dart';
import 'data_state.dart';
import 'alarm_state.dart';
import '../services/smart_planner.dart';
import '../utils/smart_reminders.dart';

export 'settings_state.dart';
export 'user_state.dart';
export 'gamification_state.dart';
export 'data_state.dart';
export 'alarm_state.dart';

class AppState extends ChangeNotifier {
  static const _profileSnapshotsKey = 'profileSnapshots';
  AppStateRepository? _repository;
  final Map<String, Map<String, dynamic>> _profileSnapshots = {};

  final SettingsState settings = SettingsState();
  final UserState user = UserState();
  final GamificationState gamification = GamificationState();
  final DataState data = DataState();
  final AlarmState alarms = AlarmState();

  AppState() {
    settings.addListener(notifyListeners);
    user.addListener(notifyListeners);
    gamification.addListener(notifyListeners);
    data.addListener(notifyListeners);
    alarms.addListener(notifyListeners);
  }

  @override
  void dispose() {
    settings.removeListener(notifyListeners);
    user.removeListener(notifyListeners);
    gamification.removeListener(notifyListeners);
    data.removeListener(notifyListeners);
    alarms.removeListener(notifyListeners);
    settings.dispose();
    user.dispose();
    gamification.dispose();
    data.dispose();
    alarms.dispose();
    super.dispose();
  }

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  Future<void> initialize() async {
    _repository = await AppStateRepository.create();
    final stored = _repository!.load();
    if (stored != null) {
      try {
        _loadFromStorageMap(stored);
      } catch (error) {
        debugPrint('Stored UniThrive state was ignored: $error');
      }
    }

    await AlarmService.initialize();
    user.ensureDefaultProfile();
    _ensureActiveProfileSnapshot();
    _restoreProfileSnapshot(_profileSnapshots[user.activeProfileId!]);

    NotificationService.setDefaultLeadMinutes(settings.reminderLeadMinutes);
    _scheduleStreakReminder();
    await reconcileAlarms();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_repository == null) return;
    _saveActiveProfileSnapshot();
    await _repository!.save(_buildStorageMap());
  }

  void _loadFromStorageMap(Map<String, dynamic> map) {
    settings.loadFromMap(map);
    user.loadFromMap(map);
    gamification.loadFromMap(map);
    data.loadFromMap(map);
    alarms.loadFromMap(_asMap(map['alarmsState']));
    _loadProfileSnapshots(map[_profileSnapshotsKey]);
  }

  Map<String, dynamic> _buildStorageMap() {
    return {
      ...settings.toJson(),
      ...user.toJson(),
      ...gamification.toJson(),
      ...data.toJson(),
      'alarmsState': alarms.toJson(),
      _profileSnapshotsKey: _serializeProfileSnapshots(),
    };
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
  bool get voiceAiEnabled => settings.voiceAiEnabled;
  String get voiceAiEndpointUrl => settings.voiceAiEndpointUrl;
  String get voiceAiProxyToken => settings.voiceAiProxyToken;

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
  List<AlarmSchedule> get alarmSchedules => alarms.alarms;
  AlarmSchedule? alarmById(String id) => alarms.alarmById(id);

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
    final start = DateTime(day.year, day.month, day.day);
    return blocksForRange(start, start.add(const Duration(days: 1)));
  }

  List<ScheduleBlock> blocksForRange(DateTime start, DateTime end) {
    final expanded = <ScheduleBlock>[];
    for (final block in data.scheduleBlocks) {
      expanded.addAll(_occurrencesForBlock(block, start, end));
    }
    expanded.sort((a, b) => a.start.compareTo(b.start));
    return expanded;
  }

  List<ScheduleBlock> blocksForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return blocksForRange(start, end);
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
    final project = projectById(projectId);
    if (project == null) return;
    final existingPendingTasks = tasksForProject(
      projectId,
    ).where((task) => !task.completed).toList();

    if (existingPendingTasks.isEmpty) {
      final taskTitles = SmartPlanner.generateTasksForProject(
        project.tag,
        project.type,
      );
      final now = DateTime.now();
      final totalDaysUntilDue = max(1, project.dueDate.difference(now).inDays);
      final generatedTasks = <Task>[];

      for (var index = 0; index < taskTitles.length; index++) {
        final ratio = (index + 1) / taskTitles.length;
        final dueOffset = max(1, (totalDaysUntilDue * ratio).round());
        final dueDate =
            now.add(Duration(days: dueOffset)).isAfter(project.dueDate)
            ? project.dueDate
            : now.add(Duration(days: dueOffset));

        generatedTasks.add(
          addTask(
            projectId: projectId,
            title: taskTitles[index],
            dueDate: dueDate,
            silent: true,
          ),
        );
      }
    }

    final unscheduledTasks = _pendingTasksWithoutSchedule(projectId: projectId);
    if (unscheduledTasks.isNotEmpty) {
      final planStart = DateTime.now();
      final planEnd = project.dueDate.isAfter(planStart)
          ? project.dueDate.add(const Duration(days: 1))
          : planStart.add(const Duration(days: 7));
      final planningBlocks = blocksForRange(planStart, planEnd);
      final daysToPlan = max(7, planEnd.difference(planStart).inDays);

      final newBlocks = SmartPlanner.distributeTasks(
        tasks: unscheduledTasks,
        existingBlocks: planningBlocks,
        startDate: planStart,
        daysToPlan: daysToPlan,
        idFactory: _nextId,
      );

      for (final block in newBlocks) {
        data.addScheduleBlock(block);
      }
    }

    _refreshProjectProgress(projectId);
    _persist();
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
    _saveActiveProfileSnapshot();
    final profile = user.addUserProfile(name);
    _profileSnapshots[profile.id] = _emptyProfileSnapshot();
    _persist();
  }

  void switchUserProfile(String profileId) {
    if (user.activeProfileId == profileId) return;
    _saveActiveProfileSnapshot();
    final switched = user.switchUserProfile(profileId);
    if (!switched) return;
    _restoreProfileSnapshot(_profileSnapshots[profileId]);
    reconcileAlarms();
    _persist();
  }

  void deleteUserProfile(String profileId) {
    final deleted = user.deleteUserProfile(profileId);
    if (!deleted) return;
    _profileSnapshots.remove(profileId);
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

  void setVoiceAiEnabled(bool enabled) {
    settings.setVoiceAiEnabled(enabled);
    _persist();
  }

  void updateVoiceAiConfig({
    required String endpointUrl,
    required String proxyToken,
  }) {
    settings.updateVoiceAiConfig(
      endpointUrl: endpointUrl,
      proxyToken: proxyToken,
    );
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

  Future<AlarmSchedule> createAlarm({
    required String title,
    required TimeOfDay time,
    AlarmRepeatType repeatType = AlarmRepeatType.once,
    List<int> weekDays = const [],
    DateTime? startDate,
    DateTime? endDate,
    int snoozeMinutes = 10,
    int maxSnoozes = 3,
    bool vibrate = true,
    String? soundAssetPath,
  }) async {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day);
    final requestedStart = startDate ?? defaultStart;
    final onceCandidate = DateTime(
      requestedStart.year,
      requestedStart.month,
      requestedStart.day,
      time.hour,
      time.minute,
    );
    final effectiveStartDate =
        repeatType == AlarmRepeatType.once && !onceCandidate.isAfter(now)
        ? requestedStart.add(const Duration(days: 1))
        : requestedStart;
    final alarm = AlarmSchedule(
      id: _nextId(),
      title: title.trim().isEmpty ? 'Alarma' : title.trim(),
      hour: time.hour,
      minute: time.minute,
      repeatType: repeatType,
      weekDays: weekDays,
      startDate: effectiveStartDate,
      endDate: endDate,
      snoozeMinutes: snoozeMinutes,
      maxSnoozes: maxSnoozes,
      vibrate: vibrate,
      soundAssetPath: soundAssetPath,
      createdAt: now,
      updatedAt: now,
    );
    alarms.addAlarm(alarm);
    await AlarmService.ensureExactAlarmPermission();
    await reconcileAlarms();
    await _persist();
    return alarm;
  }

  Future<void> updateAlarm(AlarmSchedule alarm) async {
    alarms.updateAlarm(alarm);
    await AlarmService.ensureExactAlarmPermission();
    await reconcileAlarms();
    await _persist();
  }

  Future<void> toggleAlarm(String alarmId, bool enabled) async {
    final alarm = alarms.alarmById(alarmId);
    if (alarm == null) return;
    alarms.updateAlarm(alarm.copyWith(enabled: enabled));
    await AlarmService.ensureExactAlarmPermission();
    await reconcileAlarms();
    await _persist();
  }

  Future<void> deleteAlarm(String alarmId) async {
    await AlarmService.stopSchedule(alarmId, alarms.nativeAlarmIdsByScheduleId);
    alarms.deleteAlarm(alarmId);
    await reconcileAlarms();
    await _persist();
  }

  Future<bool> snoozeAlarm(String alarmId) async {
    final alarm = alarms.alarmById(alarmId);
    final occurrence = alarm?.nextOccurrence();
    if (alarm == null || occurrence == null) return false;
    final accepted = alarms.registerSnooze(
      alarmId,
      occurrence,
      alarm.maxSnoozes,
    );
    if (!accepted) return false;
    final scheduled = await AlarmService.scheduleSnooze(
      schedule: alarm,
      occurrence: occurrence,
    );
    await _persist();
    return scheduled;
  }

  Future<void> stopAlarm(String alarmId) async {
    await AlarmService.stopSchedule(alarmId, alarms.nativeAlarmIdsByScheduleId);
    alarms.resetSnoozes(alarmId);
    await reconcileAlarms();
    await _persist();
  }

  Future<void> skipNextAlarmOccurrence(String alarmId) async {
    final alarm = alarms.alarmById(alarmId);
    final next = alarm?.nextOccurrence();
    if (alarm == null || next == null) return;
    final skipped = {...alarm.skippedDateKeys, AlarmSchedule.dateKey(next)};
    alarms.updateAlarm(alarm.copyWith(skippedDateKeys: skipped.toList()));
    await reconcileAlarms();
    await _persist();
  }

  Future<void> pauseAlarmUntil(String alarmId, DateTime? until) async {
    final alarm = alarms.alarmById(alarmId);
    if (alarm == null) return;
    alarms.updateAlarm(alarm.copyWith(pausedUntil: () => until));
    await reconcileAlarms();
    await _persist();
  }

  Future<void> reconcileAlarms() async {
    final nativeIds = await AlarmService.reconcile(
      schedules: alarms.alarms,
      previousNativeIds: alarms.nativeAlarmIdsByScheduleId,
    );
    alarms.replaceNativeIds(nativeIds);
  }

  Future<bool> openSystemAlarmClock({String? alarmId}) async {
    final alarm = alarmId == null ? null : alarms.alarmById(alarmId);
    return AlarmService.openSystemAlarmClock(
      title: alarm?.title,
      hour: alarm?.hour,
      minute: alarm?.minute,
    );
  }

  void deleteAllData() {
    for (final task in data.tasks) {
      NotificationService.cancelTaskReminder(task.id);
    }
    for (final block in data.scheduleBlocks) {
      NotificationService.cancelReminder('schedule_${block.id}');
    }
    for (final alarm in alarms.alarms) {
      AlarmService.stopSchedule(alarm.id, alarms.nativeAlarmIdsByScheduleId);
    }
    data.clearAll();
    alarms.clearAll();
    gamification.reset();
    user.reset();
    settings.reset();
    _profileSnapshots
      ..clear()
      ..[user.activeProfileId!] = _emptyProfileSnapshot();
    _persist();
  }

  Map<String, dynamic> exportToJson() {
    _saveActiveProfileSnapshot();
    return {
      'data': data.toJson(),
      'user': user.toJson(),
      'gamification': gamification.toJson(),
      'settings': settings.toJson(),
      'alarms': alarms.toJson(),
      'profileSnapshots': _serializeProfileSnapshots(),
      'version': 2,
    };
  }

  Future<void> importFromJson(Map<String, dynamic> json) async {
    _validateImportSnapshot(json);
    final previousAlarmIds = alarms.nativeAlarmIdsByScheduleId;
    for (final alarm in alarms.alarms) {
      await AlarmService.stopSchedule(alarm.id, previousAlarmIds);
    }

    settings.loadFromMap(_asMap(json['settings']));
    user.loadFromMap(_asMap(json['user']));
    gamification.loadFromMap(_asMap(json['gamification']));
    data.loadFromMap(_asMap(json['data']));
    alarms.loadFromMap(_asMap(json['alarms']));
    _loadProfileSnapshots(json['profileSnapshots']);
    user.ensureDefaultProfile();
    _ensureActiveProfileSnapshot();
    _restoreProfileSnapshot(_profileSnapshots[user.activeProfileId!]);
    await reconcileAlarms();
    await _persist();
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
      final taskTitles = SmartPlanner.generateTasksForProject(tag, type);
      final now = DateTime.now();
      final totalDaysUntilDue = max(1, dueDate.difference(now).inDays);
      final generatedTasks = <Task>[];

      for (var index = 0; index < taskTitles.length; index++) {
        final ratio = (index + 1) / taskTitles.length;
        final dueOffset = max(1, (totalDaysUntilDue * ratio).round());
        final plannedDueDate =
            now.add(Duration(days: dueOffset)).isAfter(dueDate)
            ? dueDate
            : now.add(Duration(days: dueOffset));
        generatedTasks.add(
          addTask(
            projectId: project.id,
            title: taskTitles[index],
            dueDate: plannedDueDate,
            silent: true,
          ),
        );
      }

      final planningBlocks = blocksForRange(
        now,
        dueDate.add(const Duration(days: 1)),
      );
      final newBlocks = SmartPlanner.distributeTasks(
        tasks: generatedTasks,
        existingBlocks: planningBlocks,
        startDate: now,
        daysToPlan: max(7, dueDate.difference(now).inDays),
        idFactory: _nextId,
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
    if (data.quickProjectId != null) {
      final quickById = projectById(data.quickProjectId!);
      if (quickById != null && !quickById.completed) {
        return quickById;
      }
    }

    final quickByName = data.projects.cast<Project?>().firstWhere(
      (project) =>
          project?.name == 'Tareas Rápidas' && project?.completed == false,
      orElse: () => null,
    );
    if (quickByName != null) {
      data.setQuickProjectId(quickByName.id);
      _persist();
      return quickByName;
    }

    final quickProject = addProject(
      name: 'Tareas Rápidas',
      dueDate: DateTime.now().add(const Duration(days: 365)),
      color: const Color(0xFF9FCFBB),
      description: 'Tareas rápidas y recordatorios',
      tag: 'General',
    );
    data.setQuickProjectId(quickProject.id);
    _persist();
    return quickProject;
  }

  void moveTaskWithinProject({
    required String projectId,
    required String taskId,
    required int newIndex,
  }) {
    data.reorderTasksWithinProject(
      projectId: projectId,
      taskId: taskId,
      newIndex: newIndex,
    );
    _persist();
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
    TaskPriority priority = TaskPriority.medium,
    List<String> labels = const [],
  }) {
    final task = Task(
      id: customId ?? _nextId(),
      title: title,
      projectId: projectId,
      dueDate: dueDate,
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      energy: energy,
      priority: priority,
      description: description,
      attachmentPath: attachmentPath,
      labels: labels,
    );
    data.addTask(task);

    if (!silent && dueDate != null && settings.taskRemindersEnabled) {
      final projectName = projectById(projectId)?.name;
      NotificationService.scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        dueDate: dueDate,
        customMinutes: task.customReminderMinutes,
        contextLabel: projectName,
        priority: task.priority,
      );
    }

    _refreshProjectProgress(projectId);
    _persist();
    return task;
  }

  Future<void> autoPlanWeek() async {
    final now = DateTime.now();
    final tasks = _pendingTasksWithoutSchedule();
    final blocks = blocksForRange(now, now.add(const Duration(days: 7)));

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: now,
      daysToPlan: 7,
      idFactory: _nextId,
    );

    for (final block in newBlocks) {
      data.addScheduleBlock(block);
    }
    _persist();
  }

  Future<int> autoPlanMonth(DateTime month) async {
    final now = DateTime.now();
    final start = month.year == now.year && month.month == now.month
        ? now
        : DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final tasks = _pendingTasksWithoutSchedule();
    final blocks = blocksForRange(start, end);

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: start,
      daysToPlan: max(1, end.difference(start).inDays),
      idFactory: _nextId,
    );

    for (final block in newBlocks) {
      data.addScheduleBlock(block);
    }
    _persist();
    return newBlocks
        .map(
          (block) =>
              DateTime(block.start.year, block.start.month, block.start.day),
        )
        .toSet()
        .length;
  }

  Future<bool> autoPlanDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final tasks = _pendingTasksWithoutSchedule();
    final blocks = blocksForRange(start, end);

    final newBlocks = SmartPlanner.distributeTasks(
      tasks: tasks,
      existingBlocks: blocks,
      startDate: start,
      daysToPlan: 1,
      idFactory: _nextId,
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
    TaskPriority? priority,
    List<String>? labels,
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
      priority: priority ?? current.priority,
      description: description ?? current.description,
      attachmentPath: nextAttachment,
      labels: labels ?? current.labels,
      customReminderMinutes:
          customReminderMinutes ?? current.customReminderMinutes,
      timeSpentMinutes: timeSpentMinutes ?? current.timeSpentMinutes,
      pomodoroSessions: pomodoroSessions ?? current.pomodoroSessions,
      subtasks: subtasks ?? current.subtasks,
    );
    data.updateTask(updatedTask);

    if (!silent &&
        updatedTask.dueDate != null &&
        settings.taskRemindersEnabled) {
      final projectName = projectById(updatedTask.projectId)?.name;
      NotificationService.scheduleTaskReminder(
        taskId: current.id,
        title: updatedTask.title,
        dueDate: updatedTask.dueDate!,
        customMinutes: updatedTask.customReminderMinutes,
        contextLabel: projectName,
        priority: updatedTask.priority,
      );
    } else if (updatedTask.dueDate == null) {
      NotificationService.cancelTaskReminder(current.id);
    }
    _persist();
  }

  Task? duplicateTask(String taskId) {
    final original = data.tasks.cast<Task?>().firstWhere(
      (task) => task?.id == taskId,
      orElse: () => null,
    );
    if (original == null) return null;

    final duplicated = addTask(
      projectId: original.projectId,
      title: '${original.title} (copia)',
      dueDate: original.dueDate?.add(const Duration(days: 1)),
      energy: original.energy,
      priority: original.priority,
      description: original.description,
      attachmentPath: original.attachmentPath,
      labels: original.labels,
    );

    if (original.subtasks.isNotEmpty) {
      updateTask(
        taskId: duplicated.id,
        subtasks: original.subtasks
            .map(
              (subtask) => Subtask(
                id: _nextId(),
                taskId: duplicated.id,
                title: subtask.title,
                completed: false,
                order: subtask.order,
              ),
            )
            .toList(),
      );
    }
    return duplicated;
  }

  ScheduleBlock? duplicateScheduleBlock(String blockId) {
    final original = data.scheduleBlocks.cast<ScheduleBlock?>().firstWhere(
      (block) => block?.id == blockId,
      orElse: () => null,
    );
    if (original == null) return null;
    final duplicatedStart = original.start.add(const Duration(days: 7));
    final duplicatedEnd = original.end.add(const Duration(days: 7));
    addScheduleBlock(
      title: '${original.title} (copia)',
      start: duplicatedStart,
      end: duplicatedEnd,
      color: original.color,
      location: original.location,
      category: original.category,
      recurrence: RecurrenceType.none,
    );
    return data.scheduleBlocks.isEmpty ? null : data.scheduleBlocks.last;
  }

  Task? rescheduleTaskSmart(String taskId) {
    final task = data.tasks.cast<Task?>().firstWhere(
      (item) => item?.id == taskId,
      orElse: () => null,
    );
    if (task == null) return null;
    final nextDueDate = _suggestNextDueDate(task);
    updateTask(taskId: taskId, dueDate: nextDueDate);
    return data.tasks.cast<Task?>().firstWhere(
      (item) => item?.id == taskId,
      orElse: () => null,
    );
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
    if (updatedTask.projectId.isNotEmpty) {
      _refreshProjectProgress(updatedTask.projectId);
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
    final projectId = data.tasks[idx].projectId;

    data.deleteTask(taskId);
    final linkedBlocks = data.scheduleBlocks
        .where((block) => block.linkedTaskId == taskId)
        .toList();
    for (final block in linkedBlocks) {
      data.deleteScheduleBlock(block.id);
      NotificationService.cancelReminder('schedule_${block.id}');
    }

    NotificationService.cancelTaskReminder(taskId);
    if (projectId.isNotEmpty) {
      _refreshProjectProgress(projectId);
    }
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
    String? recurrenceGroupId,
    List<int>? customWeekDays,
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
      recurrenceGroupId: recurrenceGroupId,
      customWeekDays: customWeekDays,
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
    String? recurrenceGroupId,
    List<int>? customWeekDays,
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
      recurrenceGroupId: recurrenceGroupId ?? current.recurrenceGroupId,
      customWeekDays: customWeekDays ?? current.customWeekDays,
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

  DateTime _suggestNextDueDate(Task task) {
    final now = DateTime.now();
    final preferred = SmartReminders.suggestBestTime(
      data.tasks.expand((item) => item.pomodoroSessions).toList(),
    );
    final baseHour = preferred?.hour ?? task.dueDate?.hour ?? 18;
    final baseMinute = preferred?.minute ?? task.dueDate?.minute ?? 0;

    final candidateBase = task.dueDate != null && task.dueDate!.isAfter(now)
        ? task.dueDate!
        : now.add(
            task.priority == TaskPriority.urgent
                ? const Duration(hours: 6)
                : const Duration(days: 1),
          );

    DateTime candidate = DateTime(
      candidateBase.year,
      candidateBase.month,
      candidateBase.day,
      baseHour,
      baseMinute,
    );

    if (!candidate.isAfter(now)) {
      candidate = candidate.add(
        task.priority == TaskPriority.urgent
            ? const Duration(hours: 6)
            : const Duration(days: 1),
      );
    }

    if (candidate.weekday == DateTime.saturday) {
      candidate = candidate.add(const Duration(days: 2));
    } else if (candidate.weekday == DateTime.sunday) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  // Helper for ID generation
  String _nextId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _loadProfileSnapshots(dynamic rawSnapshots) {
    _profileSnapshots.clear();
    if (rawSnapshots is! Map) return;
    rawSnapshots.forEach((key, value) {
      final snapshot = _asMap(value);
      if (snapshot.isNotEmpty) {
        _profileSnapshots[key.toString()] = snapshot;
      }
    });
  }

  Map<String, dynamic> _serializeProfileSnapshots() {
    return _profileSnapshots.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  void _ensureActiveProfileSnapshot() {
    final activeId = user.activeProfileId;
    if (activeId == null) return;
    _profileSnapshots.putIfAbsent(activeId, _buildCurrentProfileSnapshot);
  }

  void _saveActiveProfileSnapshot() {
    final activeId = user.activeProfileId;
    if (activeId == null) return;
    _profileSnapshots[activeId] = _buildCurrentProfileSnapshot();
  }

  Map<String, dynamic> _buildCurrentProfileSnapshot() {
    return {
      'data': data.toJson(),
      'gamification': gamification.toJson(),
      'alarms': alarms.toJson(),
      'hasCompletedOnboarding': user.hasCompletedOnboarding,
    };
  }

  Map<String, dynamic> _emptyProfileSnapshot() {
    return {
      'data': <String, dynamic>{},
      'gamification': <String, dynamic>{},
      'alarms': <String, dynamic>{},
      'hasCompletedOnboarding': false,
    };
  }

  void _restoreProfileSnapshot(Map<String, dynamic>? snapshot) {
    final safeSnapshot = snapshot ?? _emptyProfileSnapshot();
    data.loadFromMap(_asMap(safeSnapshot['data']));
    gamification.loadFromMap(_asMap(safeSnapshot['gamification']));
    alarms.loadFromMap(_asMap(safeSnapshot['alarms']));
    user.setOnboardingState(
      safeSnapshot['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  void _validateImportSnapshot(Map<String, dynamic> json) {
    final currentLeadMinutes = settings.reminderLeadMinutes;
    try {
      final tempSettings = SettingsState()
        ..loadFromMap(_asMap(json['settings']));
      final tempUser = UserState()..loadFromMap(_asMap(json['user']));
      final tempGamification = GamificationState()
        ..loadFromMap(_asMap(json['gamification']));
      final tempData = DataState()..loadFromMap(_asMap(json['data']));
      final tempAlarms = AlarmState()..loadFromMap(_asMap(json['alarms']));
      tempSettings.dispose();
      tempUser.dispose();
      tempGamification.dispose();
      tempData.dispose();
      tempAlarms.dispose();
    } finally {
      NotificationService.setDefaultLeadMinutes(currentLeadMinutes);
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Task> _pendingTasksWithoutSchedule({String? projectId}) {
    final scheduledTaskIds = data.scheduleBlocks
        .where((block) => block.linkedTaskId != null)
        .map((block) => block.linkedTaskId!)
        .toSet();

    return data.tasks
        .where(
          (task) =>
              !task.completed &&
              (projectId == null || task.projectId == projectId) &&
              !scheduledTaskIds.contains(task.id),
        )
        .toList();
  }

  void _refreshProjectProgress(String projectId) {
    final projectIdx = data.projects.indexWhere(
      (project) => project.id == projectId,
    );
    if (projectIdx == -1) return;

    final projectTasks = data.tasks
        .where((task) => task.projectId == projectId)
        .toList();
    final completedCount = projectTasks.where((task) => task.completed).length;
    final progress = projectTasks.isEmpty
        ? 0.0
        : ((completedCount / projectTasks.length) * 100).clamp(0.0, 100.0);
    final isCompleted =
        projectTasks.isNotEmpty && completedCount == projectTasks.length;

    data.updateProject(
      data.projects[projectIdx].copyWith(
        progress: progress,
        completed: isCompleted,
      ),
    );
  }

  List<ScheduleBlock> _occurrencesForBlock(
    ScheduleBlock block,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    if (block.recurrence == RecurrenceType.none) {
      return (!block.start.isBefore(rangeStart) &&
              block.start.isBefore(rangeEnd))
          ? [block]
          : const [];
    }

    final occurrences = <ScheduleBlock>[];
    final duration = block.end.difference(block.start);
    DateTime cursor = block.start;

    void addOccurrence(DateTime occurrenceStart) {
      if (_isPastRecurrenceEnd(block, occurrenceStart)) return;
      if (!occurrenceStart.isBefore(rangeStart) &&
          occurrenceStart.isBefore(rangeEnd)) {
        occurrences.add(
          block.copyWith(
            start: occurrenceStart,
            end: occurrenceStart.add(duration),
          ),
        );
      }
    }

    switch (block.recurrence) {
      case RecurrenceType.daily:
        while (cursor.isBefore(rangeStart)) {
          cursor = cursor.add(Duration(days: block.recurrenceInterval));
        }
        while (cursor.isBefore(rangeEnd)) {
          addOccurrence(cursor);
          cursor = cursor.add(Duration(days: block.recurrenceInterval));
        }
        break;
      case RecurrenceType.weekly:
        while (cursor.isBefore(rangeStart)) {
          cursor = cursor.add(Duration(days: 7 * block.recurrenceInterval));
        }
        while (cursor.isBefore(rangeEnd)) {
          addOccurrence(cursor);
          cursor = cursor.add(Duration(days: 7 * block.recurrenceInterval));
        }
        break;
      case RecurrenceType.monthly:
        while (cursor.isBefore(rangeStart)) {
          cursor = _addMonths(cursor, block.recurrenceInterval);
        }
        while (cursor.isBefore(rangeEnd)) {
          addOccurrence(cursor);
          cursor = _addMonths(cursor, block.recurrenceInterval);
        }
        break;
      case RecurrenceType.yearly:
        while (cursor.isBefore(rangeStart)) {
          cursor = _addYears(cursor, block.recurrenceInterval);
        }
        while (cursor.isBefore(rangeEnd)) {
          addOccurrence(cursor);
          cursor = _addYears(cursor, block.recurrenceInterval);
        }
        break;
      case RecurrenceType.custom:
        final weekDays = block.customWeekDays ?? [block.start.weekday];
        var dayCursor = DateTime(
          rangeStart.year,
          rangeStart.month,
          rangeStart.day,
        );
        final lastDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);

        while (!dayCursor.isAfter(lastDay)) {
          final candidate = DateTime(
            dayCursor.year,
            dayCursor.month,
            dayCursor.day,
            block.start.hour,
            block.start.minute,
            block.start.second,
            block.start.millisecond,
            block.start.microsecond,
          );
          final daysSinceStart = candidate
              .difference(
                DateTime(block.start.year, block.start.month, block.start.day),
              )
              .inDays;
          final weekOffset = daysSinceStart >= 0 ? daysSinceStart ~/ 7 : -1;
          final isMatchingInterval =
              weekOffset >= 0 && weekOffset % block.recurrenceInterval == 0;

          if (!candidate.isBefore(block.start) &&
              weekDays.contains(candidate.weekday) &&
              isMatchingInterval) {
            addOccurrence(candidate);
          }
          dayCursor = dayCursor.add(const Duration(days: 1));
        }
        break;
      case RecurrenceType.none:
        break;
    }

    return occurrences;
  }

  bool _isPastRecurrenceEnd(ScheduleBlock block, DateTime occurrenceStart) {
    final recurrenceEndDate = block.recurrenceEndDate;
    if (recurrenceEndDate == null) return false;
    final inclusiveEnd = DateTime(
      recurrenceEndDate.year,
      recurrenceEndDate.month,
      recurrenceEndDate.day,
      23,
      59,
      59,
      999,
      999,
    );
    return occurrenceStart.isAfter(inclusiveEnd);
  }

  DateTime _addMonths(DateTime source, int monthsToAdd) {
    final targetMonth = source.month + monthsToAdd;
    final year = source.year + ((targetMonth - 1) ~/ 12);
    final month = ((targetMonth - 1) % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = min(source.day, lastDayOfTargetMonth);

    return DateTime(
      year,
      month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  DateTime _addYears(DateTime source, int yearsToAdd) {
    final year = source.year + yearsToAdd;
    final lastDayOfTargetMonth = DateTime(year, source.month + 1, 0).day;
    final day = min(source.day, lastDayOfTargetMonth);

    return DateTime(
      year,
      source.month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
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
