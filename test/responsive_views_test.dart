import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uni_thrive/core/theme.dart';
import 'package:uni_thrive/models/pomodoro_session.dart';
import 'package:uni_thrive/screens/achievements/achievements_screen.dart';
import 'package:uni_thrive/screens/alarms/alarm_screen.dart';
import 'package:uni_thrive/screens/calendar/calendar_screen.dart';
import 'package:uni_thrive/screens/focus/focus_session_screen.dart';
import 'package:uni_thrive/screens/focus/focus_timer_screen.dart';
import 'package:uni_thrive/screens/home/dashboard_screen.dart';
import 'package:uni_thrive/screens/notifications/notification_center_screen.dart';
import 'package:uni_thrive/screens/onboarding/welcome_screen.dart';
import 'package:uni_thrive/screens/profile/profile_screen.dart';
import 'package:uni_thrive/screens/projects/project_detail_screen.dart';
import 'package:uni_thrive/screens/projects/projects_screen.dart';
import 'package:uni_thrive/screens/root/root_shell.dart';
import 'package:uni_thrive/screens/settings/settings_screen.dart';
import 'package:uni_thrive/screens/stats/statistics_screen.dart';
import 'package:uni_thrive/screens/tasks/task_detail_screen.dart';
import 'package:uni_thrive/screens/tasks/task_history_screen.dart';
import 'package:uni_thrive/state/app_state.dart';
import 'package:uni_thrive/widgets/voice_schedule_sheet.dart';
import 'package:uni_thrive/widgets/voice_task_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('RootShell navega tabs sin overflows en tamaños compactos', (
    tester,
  ) async {
    await _runAcrossViewports(tester, (viewport) async {
      final appState = _seedAppState();

      await _pumpResponsiveScreen(
        tester,
        appState: appState,
        viewport: viewport,
        child: const RootShell(),
      );
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, 'RootShell ${viewport.label}');

      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, 'Calendar tab ${viewport.label}');

      await tester.tap(find.text('Proyectos'));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, 'Projects tab ${viewport.label}');

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, 'Profile tab ${viewport.label}');
    });
  });

  testWidgets(
    'Calendar abre hoja de bloque sin overflows en tamaños compactos',
    (tester) async {
      await _runAcrossViewports(tester, (viewport) async {
        final appState = _seedAppState();
        await _pumpResponsiveScreen(
          tester,
          appState: appState,
          viewport: viewport,
          child: const CalendarScreen(),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        _expectNoLayoutException(tester, 'Calendar sheet ${viewport.label}');
        await _dismissTopRoute(tester);
        _expectNoLayoutException(
          tester,
          'Calendar sheet close ${viewport.label}',
        );
      });
    },
  );

  testWidgets('Projects abre creación sin overflows en tamaños compactos', (
    tester,
  ) async {
    await _runAcrossViewports(tester, (viewport) async {
      final appState = _seedAppState();
      await _pumpResponsiveScreen(
        tester,
        appState: appState,
        viewport: viewport,
        child: const ProjectsScreen(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      _expectNoLayoutException(tester, 'Projects sheet ${viewport.label}');
      await _dismissTopRoute(tester);
      _expectNoLayoutException(
        tester,
        'Projects sheet close ${viewport.label}',
      );
    });
  });

  final screenCases = <_ScreenCase>[
    _ScreenCase(label: 'Dashboard', builder: (_) => const DashboardScreen()),
    _ScreenCase(
      label: 'VoiceTaskSheet',
      builder: (_) => Scaffold(body: VoiceTaskSheet()),
    ),
    _ScreenCase(
      label: 'VoiceScheduleSheet',
      builder: (_) => Scaffold(
        body: VoiceScheduleSheet(referenceDay: DateTime(2026, 4, 20)),
      ),
    ),
    _ScreenCase(label: 'AlarmScreen', builder: (_) => const AlarmScreen()),
    _ScreenCase(label: 'Calendar', builder: (_) => const CalendarScreen()),
    _ScreenCase(label: 'Projects', builder: (_) => const ProjectsScreen()),
    _ScreenCase(label: 'Profile', builder: (_) => const ProfileScreen()),
    _ScreenCase(label: 'Settings', builder: (_) => const SettingsScreen()),
    _ScreenCase(label: 'Welcome', builder: (_) => const WelcomeScreen()),
    _ScreenCase(
      label: 'Achievements',
      builder: (_) => const AchievementsScreen(),
    ),
    _ScreenCase(
      label: 'Notifications',
      builder: (_) => const NotificationCenterScreen(),
    ),
    _ScreenCase(label: 'Statistics', builder: (_) => const StatisticsScreen()),
    _ScreenCase(
      label: 'TaskHistory',
      builder: (_) => const TaskHistoryScreen(),
    ),
    _ScreenCase(
      label: 'TaskDetail',
      builder: (appState) => TaskDetailScreen(task: appState.allTasks.first),
    ),
    _ScreenCase(
      label: 'ProjectDetail',
      builder: (appState) =>
          ProjectDetailScreen(project: appState.projects.first),
    ),
    _ScreenCase(
      label: 'FocusSession',
      builder: (_) => const FocusSessionScreen(
        taskLabel:
            'Preparar una presentación bastante larga para validar el layout en pantallas compactas',
      ),
    ),
    _ScreenCase(
      label: 'FocusTimer',
      builder: (_) => const FocusTimerScreen(
        focusLabel:
            'Sesión extensa para comprobar que el temporizador no rompe la interfaz',
      ),
      settle: false,
    ),
  ];

  final dialogCases = <_DialogCase>[
    _DialogCase(
      label: 'Settings reminder dialog',
      builder: (appState) => SettingsReminderLeadDialog(appState: appState),
    ),
    _DialogCase(
      label: 'Settings sound dialog',
      builder: (appState) => SettingsAlarmSoundDialog(appState: appState),
    ),
    _DialogCase(
      label: 'Settings voice AI dialog',
      builder: (appState) => SettingsVoiceAiDialog(appState: appState),
    ),
    _DialogCase(
      label: 'Settings reset dialog',
      builder: (appState) => SettingsResetDialog(appState: appState),
    ),
    _DialogCase(
      label: 'Settings delete data dialog',
      builder: (appState) => SettingsDeleteAllDataDialog(appState: appState),
    ),
  ];

  for (final screenCase in screenCases) {
    testWidgets(
      '${screenCase.label} se adapta en portrait, landscape y texto grande',
      (tester) async {
        await _runAcrossViewports(tester, (viewport) async {
          final appState = _seedAppState();

          await _pumpResponsiveScreen(
            tester,
            appState: appState,
            viewport: viewport,
            child: screenCase.builder(appState),
          );

          if (screenCase.settle) {
            await tester.pumpAndSettle();
          } else {
            await tester.pump();
          }

          _expectNoLayoutException(
            tester,
            '${screenCase.label} ${viewport.label}',
          );
        });
      },
    );
  }

  for (final dialogCase in dialogCases) {
    testWidgets(
      '${dialogCase.label} se adapta en portrait, landscape y texto grande',
      (tester) async {
        await _runAcrossViewports(tester, (viewport) async {
          final appState = _seedAppState();

          await _pumpResponsiveScreen(
            tester,
            appState: appState,
            viewport: viewport,
            child: _DialogHost(dialog: dialogCase.builder(appState)),
          );
          await tester.pumpAndSettle();

          _expectNoLayoutException(
            tester,
            '${dialogCase.label} ${viewport.label}',
          );
        });
      },
    );
  }
}

const _viewportCases = <_ViewportCase>[
  _ViewportCase(
    label: 'iPhone SE portrait',
    size: Size(320, 568),
    textScale: 1.2,
  ),
  _ViewportCase(
    label: 'iPhone SE landscape',
    size: Size(568, 320),
    textScale: 1.1,
  ),
  _ViewportCase(
    label: 'iPhone Plus portrait',
    size: Size(390, 844),
    textScale: 1.3,
  ),
];

Future<void> _runAcrossViewports(
  WidgetTester tester,
  Future<void> Function(_ViewportCase viewport) body,
) async {
  for (final viewport in _viewportCases) {
    await body(viewport);
  }
}

Future<void> _pumpResponsiveScreen(
  WidgetTester tester, {
  required AppState appState,
  required _ViewportCase viewport,
  required Widget child,
}) async {
  tester.view.physicalSize = viewport.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    AppStateProvider(
      appState: appState,
      child: MaterialApp(
        theme: UniThriveTheme.light,
        darkTheme: UniThriveTheme.dark,
        builder: (context, widget) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(viewport.textScale),
            ),
            child: widget ?? const SizedBox.shrink(),
          );
        },
        home: child,
      ),
    ),
  );
}

void _expectNoLayoutException(WidgetTester tester, String label) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: label);
}

Future<void> _dismissTopRoute(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

AppState _seedAppState() {
  final appState = AppState();
  appState.updateUserProfile('Rodrigo');
  appState.completeOnboarding();

  final now = DateTime.now();
  final project = appState.addProject(
    name:
        'Proyecto universitario con un nombre bastante largo para probar ajustes responsivos',
    dueDate: now.add(const Duration(days: 7)),
    color: const Color(0xFF7DB8A4),
    description: 'Proyecto de prueba para layouts compactos.',
    tag: 'Entrega final',
  );

  final task = appState.addTask(
    projectId: project.id,
    title:
        '📚 Preparar una entrega con un título largo para validar el detalle y las tarjetas',
    dueDate: now.add(const Duration(hours: 6)),
    description:
        'Descripción extensa para asegurarnos de que los textos largos no generen overflows en vistas compactas.',
  );

  appState.updateTask(
    taskId: task.id,
    timeSpentMinutes: 95,
    pomodoroSessions: [
      PomodoroSession(
        id: 'pomodoro-1',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 35)),
        plannedDurationMinutes: 25,
        actualDurationMinutes: 25,
        wasCompleted: true,
      ),
      PomodoroSession(
        id: 'pomodoro-2',
        startTime: now.subtract(const Duration(hours: 1, minutes: 20)),
        endTime: now.subtract(const Duration(hours: 1)),
        plannedDurationMinutes: 25,
        actualDurationMinutes: 20,
      ),
    ],
  );

  appState.addTask(
    projectId: project.id,
    title:
        '💼 Revisar bibliografía secundaria con una descripción suficientemente larga para estresar tarjetas',
    dueDate: now.add(const Duration(days: 1, hours: 2)),
    description:
        'Segundo elemento de prueba para listas, próximos recordatorios y estados compactos.',
  );

  appState.addScheduleBlock(
    title: 'Clase de laboratorio con nombre largo para validar el calendario',
    start: now.add(const Duration(hours: 2)),
    end: now.add(const Duration(hours: 4)),
    location: 'Pabellón Norte · Aula 402',
  );

  return appState;
}

class _ViewportCase {
  final String label;
  final Size size;
  final double textScale;

  const _ViewportCase({
    required this.label,
    required this.size,
    required this.textScale,
  });
}

class _ScreenCase {
  final String label;
  final Widget Function(AppState appState) builder;
  final bool settle;

  const _ScreenCase({
    required this.label,
    required this.builder,
    this.settle = true,
  });
}

class _DialogCase {
  final String label;
  final Widget Function(AppState appState) builder;

  const _DialogCase({required this.label, required this.builder});
}

class _DialogHost extends StatefulWidget {
  final Widget dialog;

  const _DialogHost({required this.dialog});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  var _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) {
      return;
    }

    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(context: context, builder: (_) => widget.dialog);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }
}
