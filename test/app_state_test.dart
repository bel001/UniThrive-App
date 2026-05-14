import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_thrive/models/schedule.dart';
import 'package:uni_thrive/state/app_state.dart';

void main() {
  AppState buildState() {
    final appState = AppState();
    appState.user.ensureDefaultProfile();
    return appState;
  }

  test('expande recurrencias semanales al consultar otro dia', () {
    final appState = buildState();
    final start = DateTime(2026, 4, 6, 9);
    final end = DateTime(2026, 4, 6, 11);

    appState.addScheduleBlock(
      title: 'Álgebra',
      start: start,
      end: end,
      recurrence: RecurrenceType.weekly,
    );

    final nextWeekBlocks = appState.blocksForDay(DateTime(2026, 4, 13));

    expect(nextWeekBlocks, hasLength(1));
    expect(nextWeekBlocks.first.title, 'Álgebra');
    expect(nextWeekBlocks.first.start, DateTime(2026, 4, 13, 9));
    expect(nextWeekBlocks.first.end, DateTime(2026, 4, 13, 11));
  });

  test('expande recurrencias personalizadas con varios dias', () {
    final appState = buildState();
    final start = DateTime(2026, 4, 20, 8);
    final end = DateTime(2026, 4, 20, 10);

    appState.addScheduleBlock(
      title: 'Física II',
      start: start,
      end: end,
      recurrence: RecurrenceType.custom,
      customWeekDays: const [DateTime.monday, DateTime.wednesday],
    );

    final wednesdayBlocks = appState.blocksForDay(DateTime(2026, 4, 22));

    expect(wednesdayBlocks, hasLength(1));
    expect(wednesdayBlocks.first.title, 'Física II');
    expect(wednesdayBlocks.first.start, DateTime(2026, 4, 22, 8));
    expect(wednesdayBlocks.first.end, DateTime(2026, 4, 22, 10));
  });

  test('cambiar de perfil aísla proyectos y tareas', () {
    final appState = buildState();
    final originalProfileId = appState.activeProfileId!;

    final originalProject = appState.addProject(
      name: 'Perfil A',
      dueDate: DateTime(2026, 5, 10),
      color: Colors.blue,
    );
    appState.addTask(
      projectId: originalProject.id,
      title: 'Tarea perfil A',
      dueDate: DateTime(2026, 5, 1),
    );

    appState.addUserProfile('Carlos');
    final secondProfileId = appState.profiles.last.id;

    appState.switchUserProfile(secondProfileId);

    expect(appState.projects, isEmpty);
    expect(appState.allTasks, isEmpty);

    final secondProject = appState.addProject(
      name: 'Perfil B',
      dueDate: DateTime(2026, 6, 10),
      color: Colors.green,
    );
    appState.addTask(
      projectId: secondProject.id,
      title: 'Tarea perfil B',
      dueDate: DateTime(2026, 6, 1),
    );

    appState.switchUserProfile(originalProfileId);

    expect(
      appState.projects.map((project) => project.name),
      contains('Perfil A'),
    );
    expect(
      appState.projects.map((project) => project.name),
      isNot(contains('Perfil B')),
    );
    expect(
      appState.allTasks.map((task) => task.title),
      contains('Tarea perfil A'),
    );
    expect(
      appState.allTasks.map((task) => task.title),
      isNot(contains('Tarea perfil B')),
    );
  });

  test('reordena tareas dentro del proyecto', () {
    final appState = buildState();
    final project = appState.addProject(
      name: 'Proyecto orden',
      dueDate: DateTime(2026, 5, 10),
      color: Colors.orange,
    );

    final first = appState.addTask(projectId: project.id, title: 'Primera');
    final second = appState.addTask(projectId: project.id, title: 'Segunda');
    appState.addTask(projectId: project.id, title: 'Tercera');

    appState.moveTaskWithinProject(
      projectId: project.id,
      taskId: second.id,
      newIndex: 0,
    );

    final titles = appState
        .tasksForProject(project.id)
        .map((task) => task.title);

    expect(titles, ['Segunda', 'Primera', 'Tercera']);
    expect(first.projectId, project.id);
  });
}
