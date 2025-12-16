import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../models/focus_session.dart';
import '../models/support_message.dart';

class DataState extends ChangeNotifier {
  final List<Project> _projects = [];
  final List<Task> _tasks = [];
  final List<ScheduleBlock> _scheduleBlocks = [];
  final List<FocusSession> _focusHistory = [];
  final List<SupportMessage> _supportMessages = [];
  FocusSession? _currentFocusSession;
  String? _quickProjectId;

  List<Project> get projects => List.unmodifiable(_projects);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<ScheduleBlock> get scheduleBlocks => List.unmodifiable(_scheduleBlocks);
  List<FocusSession> get focusHistory => List.unmodifiable(_focusHistory);
  List<SupportMessage> get supportMessages =>
      List.unmodifiable(_supportMessages);
  FocusSession? get currentFocusSession => _currentFocusSession;

  void loadFromMap(Map<String, dynamic> map) {
    if (map['projects'] != null) {
      _projects.clear();
      for (var p in map['projects']) {
        _projects.add(Project.fromJson(p));
      }
    }
    if (map['tasks'] != null) {
      _tasks.clear();
      for (var t in map['tasks']) {
        _tasks.add(Task.fromJson(t));
      }
    }
    if (map['schedule'] != null) {
      _scheduleBlocks.clear();
      for (var s in map['schedule']) {
        _scheduleBlocks.add(ScheduleBlock.fromJson(s));
      }
    }
    if (map['focusHistory'] != null) {
      _focusHistory.clear();
      for (var f in map['focusHistory']) {
        _focusHistory.add(FocusSession.fromJson(f));
      }
    }
    if (map['supportMessages'] != null) {
      _supportMessages.clear();
      for (var m in map['supportMessages']) {
        _supportMessages.add(SupportMessage.fromJson(m));
      }
    }
    _quickProjectId = map['quickProjectId'];

    if (map['currentFocusSession'] != null) {
      _currentFocusSession = FocusSession.fromJson(map['currentFocusSession']);
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'projects': _projects.map((p) => p.toJson()).toList(),
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'schedule': _scheduleBlocks.map((s) => s.toJson()).toList(),
      'focusHistory': _focusHistory.map((f) => f.toJson()).toList(),
      'supportMessages': _supportMessages.map((m) => m.toJson()).toList(),
      'quickProjectId': _quickProjectId,
      'currentFocusSession': _currentFocusSession?.toJson(),
    };
  }

  // CRUD Operations

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    notifyListeners();
  }

  void updateProject(Project updatedProject) {
    final idx = _projects.indexWhere((p) => p.id == updatedProject.id);
    if (idx != -1) {
      _projects[idx] = updatedProject;
      notifyListeners();
    }
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void addScheduleBlock(ScheduleBlock block) {
    _scheduleBlocks.add(block);
    notifyListeners();
  }

  void updateScheduleBlock(ScheduleBlock updatedBlock) {
    final idx = _scheduleBlocks.indexWhere((b) => b.id == updatedBlock.id);
    if (idx != -1) {
      _scheduleBlocks[idx] = updatedBlock;
      notifyListeners();
    }
  }

  void deleteScheduleBlock(String blockId) {
    _scheduleBlocks.removeWhere((b) => b.id == blockId);
    notifyListeners();
  }

  void clearAll() {
    _projects.clear();
    _tasks.clear();
    _scheduleBlocks.clear();
    _focusHistory.clear();
    _currentFocusSession = null;
    notifyListeners();
  }

  void setCurrentFocusSession(FocusSession? session) {
    _currentFocusSession = session;
    notifyListeners();
  }

  void addFocusSession(FocusSession session) {
    _focusHistory.add(session);
    notifyListeners();
  }

  // ... (Other CRUD methods from AppState)

  // Helper to generate IDs if needed, or pass from outside
}
