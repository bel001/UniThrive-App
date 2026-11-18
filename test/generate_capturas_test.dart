import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uni_thrive/core/theme.dart';
import 'package:uni_thrive/models/achievement.dart';
import 'package:uni_thrive/models/alarm_schedule.dart';
import 'package:uni_thrive/models/focus_session.dart';
import 'package:uni_thrive/models/project.dart';
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
import 'package:uni_thrive/screens/supervisual/supervisual_screen.dart';
import 'package:uni_thrive/screens/tasks/task_detail_screen.dart';
import 'package:uni_thrive/screens/tasks/task_history_screen.dart';
import 'package:uni_thrive/state/app_state.dart';
import 'package:uni_thrive/widgets/voice_schedule_sheet.dart';
import 'package:uni_thrive/widgets/voice_task_sheet.dart';

Future<ByteData> _fontBytes(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}

Future<void> _loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    // ignore: avoid_print
    print('⚠ Fuente no encontrada: $path');
    return;
  }
  final loader = FontLoader(family)..addFont(_fontBytes(path));
  await loader.load();
}

Future<void> _loadRealFonts() async {
  // flutter_test usa Ahem por defecto; cargamos las fuentes reales para que
  // las capturas muestren texto e iconos en lugar de cajas.
  await _loadFont('Lexend', 'assets/fonts/Lexend-Variable.ttf');

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final materialFonts = flutterRoot == null
      ? null
      : Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  if (materialFonts != null && materialFonts.existsSync()) {
    await _loadFont(
      'MaterialIcons',
      '${materialFonts.path}/MaterialIcons-Regular.otf',
    );
  } else {
    // ignore: avoid_print
    print('⚠ No se encontró el directorio de fuentes de Flutter');
  }

  // Emojis de logros (🔥, ✅, 🎧...) con la fuente del sistema.
  const emojiPath = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';
  if (File(emojiPath).existsSync()) {
    await _loadFont('Lexend', emojiPath);
    await _loadFont('Noto Color Emoji', emojiPath);
  }
}

ThemeData _captureTheme() {
  final base = UniThriveTheme.dark;
  const fallback = ['Noto Color Emoji'];
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamilyFallback: fallback),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamilyFallback: fallback,
    ),
  );
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await _loadRealFonts();

  final capturesDir = Directory('capturas');
  if (!capturesDir.existsSync()) capturesDir.createSync(recursive: true);

  // Limpia solo los generados por este test (mantiene el 00_dashboard_actual de ADB)
  for (final f in capturesDir.listSync().whereType<File>()) {
    if (f.path.contains(RegExp(r'/(0[1-9]|[1-9][0-9])_'))) {
      try { f.deleteSync(); } catch (_) {}
    }
  }

  AppState seed() {
    final s = AppState();
    s.updateUserProfile('Rodrigo');
    s.completeOnboarding();
    s.setThemeMode(ThemeMode.dark);
    s.addUserProfile('Ana');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final calc = s.addProject(
      name: 'Cálculo I — Derivadas',
      dueDate: now.add(const Duration(days: 7)),
      color: const Color(0xFF7DB8A4),
      description: 'Guía 4, límites y continuidad',
      tag: 'Curso',
      type: ProjectType.study,
    );
    final tesis = s.addProject(
      name: 'Tesis — Capítulo 2',
      dueDate: now.add(const Duration(days: 14)),
      color: const Color(0xFF8E7BFF),
      description: 'Marco teórico y entrevistas',
      tag: 'Proyecto',
      type: ProjectType.essay,
    );
    s.addProject(
      name: 'Biología celular',
      dueDate: now.subtract(const Duration(days: 10)),
      color: const Color(0xFF49FFBD),
      description: 'Laboratorio y prácticas',
      tag: 'Curso',
      completed: true,
      progress: 100,
      type: ProjectType.study,
    );
    final historia = s.addProject(
      name: 'Historia del Arte',
      dueDate: now.add(const Duration(days: 21)),
      color: const Color(0xFFFFB86B),
      description: 'Ensayo comparativo',
      tag: 'Curso',
      type: ProjectType.essay,
    );

    final guia = s.addTask(
      projectId: calc.id,
      title: 'Resolver guía 4 — límites',
      dueDate: today.add(const Duration(hours: 20)),
      description: 'Ejercicios 1-20',
    );
    s.addSubtask(taskId: guia.id, title: 'Ejercicios 1-10');
    s.addSubtask(taskId: guia.id, title: 'Ejercicios 11-20');
    final ensayo = s.addTask(
      projectId: calc.id,
      title: 'Entregar ensayo de historia',
      dueDate: today.add(const Duration(hours: 22)),
      description: 'Borrador final',
    );
    s.addTask(
      projectId: tesis.id,
      title: 'Preparar exposición',
      dueDate: now.add(const Duration(days: 2, hours: 3)),
      description: 'Diapositivas y guion',
    );
    s.addTask(
      projectId: historia.id,
      title: 'Leer capítulo 3',
      dueDate: now.add(const Duration(days: 4)),
      description: 'Renacimiento y barroco',
    );
    s.toggleTaskCompletion(ensayo.id);

    s.addScheduleBlock(
      title: 'Física II',
      start: today.add(const Duration(hours: 9)),
      end: today.add(const Duration(hours: 11)),
      location: 'Aula B203',
    );
    s.addScheduleBlock(
      title: 'Cálculo I',
      start: today.add(const Duration(hours: 14)),
      end: today.add(const Duration(hours: 16)),
      location: 'Aula A101',
    );
    s.addScheduleBlock(
      title: 'Laboratorio de Química',
      start: today.add(const Duration(days: 1, hours: 10)),
      end: today.add(const Duration(days: 1, hours: 12)),
      location: 'Laboratorio 3',
    );
    s.addScheduleBlock(
      title: 'Historia del Arte',
      start: today.add(const Duration(days: 2, hours: 8)),
      end: today.add(const Duration(days: 2, hours: 10)),
      location: 'Aula C204',
    );

    void addAlarm(
      String title,
      int hour,
      int minute,
      AlarmRepeatType repeatType,
      List<int> weekDays,
    ) {
      s.alarms.addAlarm(
        AlarmSchedule(
          id: 'alarm_${title.toLowerCase().replaceAll(' ', '_')}',
          title: title,
          hour: hour,
          minute: minute,
          repeatType: repeatType,
          weekDays: weekDays,
          startDate: today,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    addAlarm(
      'Cálculo I',
      7,
      0,
      AlarmRepeatType.weekly,
      const [1, 3, 5],
    );
    addAlarm('Gimnasio', 6, 30, AlarmRepeatType.weekly, const [2, 4]);
    addAlarm('Lectura', 22, 0, AlarmRepeatType.daily, const []);

    final unlockedIds = {
      'streak_5',
      'tasks_10',
      'focus_5h',
      'projects_3',
    };
    final achievementsJson = PredefinedAchievements.all.map((achievement) {
      final json = achievement.toJson();
      if (unlockedIds.contains(achievement.id)) {
        json['unlocked'] = true;
        json['unlockedAt'] = now
            .subtract(const Duration(days: 1))
            .toIso8601String();
        json['currentProgress'] = achievement.requiredValue;
      } else if (achievement.id == 'streak_10') {
        json['currentProgress'] = 6;
      } else if (achievement.id == 'tasks_50') {
        json['currentProgress'] = 6;
      } else if (achievement.id == 'focus_25h') {
        json['currentProgress'] = 135;
      } else if (achievement.id == 'pomo_streak_3') {
        json['currentProgress'] = 2;
      }
      return json;
    }).toList();

    s.gamification.loadFromMap({
      'experiencePoints': 430,
      'level': 5,
      'streakDays': 6,
      'pomodoroStreakDays': 3,
      'lastActiveDay': now.toIso8601String(),
      'lastPomodoroDay': now.toIso8601String(),
      'achievements': achievementsJson,
    });

    s.data.addFocusSession(
      FocusSession(
        id: 'focus_demo_1',
        label: 'Resolver guía 4 — límites',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(
          const Duration(hours: 2, minutes: 15),
        ),
      ),
    );
    s.data.addFocusSession(
      FocusSession(
        id: 'focus_demo_2',
        label: 'Lectura de tesis',
        startTime: now.subtract(const Duration(hours: 6)),
        endTime: now.subtract(
          const Duration(hours: 5, minutes: 25),
        ),
      ),
    );
    s.data.addFocusSession(
      FocusSession(
        id: 'focus_demo_3',
        label: 'Repaso de Cálculo',
        startTime: now.subtract(const Duration(days: 1, hours: 2)),
        endTime: now.subtract(
          const Duration(days: 1, hours: 1, minutes: 5),
        ),
      ),
    );

    return s;
  }

  final cases = <MapEntry<String, Widget Function(AppState)>>[
    MapEntry('01_dashboard', (_) => const DashboardScreen()),
    MapEntry('02_supervisual', (_) => const SupervisualScreen()),
    MapEntry('03_calendar', (_) => const CalendarScreen()),
    MapEntry('04_projects', (_) => const ProjectsScreen()),
    MapEntry('05_profile', (_) => const ProfileScreen()),
    MapEntry('06_settings', (_) => const SettingsScreen()),
    MapEntry('07_statistics', (_) => const StatisticsScreen()),
    MapEntry('08_achievements', (_) => const AchievementsScreen()),
    MapEntry('09_task_history', (_) => const TaskHistoryScreen()),
    MapEntry('10_alarm', (_) => const AlarmScreen()),
    MapEntry('11_notifications', (_) => const NotificationCenterScreen()),
    MapEntry('12_focus_timer', (_) => const FocusTimerScreen(focusLabel: 'Sesión demo')),
    MapEntry('13_focus_session', (_) => const FocusSessionScreen(taskLabel: 'Resolver guía 4 — límites')),
    MapEntry('14_welcome', (_) => const WelcomeScreen()),
    MapEntry('15_root_shell', (_) => const RootShell()),
    MapEntry('16_task_detail', (s) => TaskDetailScreen(task: s.allTasks.first)),
    MapEntry('17_project_detail', (s) => ProjectDetailScreen(project: s.projects.first)),
    MapEntry('18_voice_task', (_) => Scaffold(body: VoiceTaskSheet())),
    MapEntry('19_voice_schedule', (_) => Scaffold(body: VoiceScheduleSheet(referenceDay: DateTime.now()))),
  ];

  for (final entry in cases) {
    testWidgets('captura ${entry.key}', (t) async {
      final appState = seed();
      const logical = Size(430, 932);
      t.view.physicalSize = Size(logical.width * 3, logical.height * 3);
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      final key = GlobalKey();
      await t.pumpWidget(
        AppStateProvider(
          appState: appState,
          child: MaterialApp(
            theme: _captureTheme(),
            darkTheme: _captureTheme(),
            themeMode: ThemeMode.dark,
            home: SizedBox(
              width: logical.width,
              height: logical.height,
              child: RepaintBoundary(key: key, child: entry.value(appState)),
            ),
          ),
        ),
      );
      await t.pumpAndSettle(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 200));

      // Precarga las mascotas para que no salgan mientras se captura.
      await t.runAsync(() async {
        final context = t.element(find.byType(MaterialApp));
        for (final asset in const [
          'assets/mascot/mascot_happy.png',
          'assets/mascot/mascot_excited.png',
          'assets/mascot/mascot_encouraging.png',
          'assets/mascot/mascot_celebrating.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await t.pump(const Duration(milliseconds: 120));

      if (entry.key == '12_focus_timer') {
        await t.pump(const Duration(seconds: 78));
      }
      if (entry.key == '16_task_detail') {
        await t.drag(
          find.byType(CustomScrollView),
          const Offset(0, -85),
        );
        await t.pumpAndSettle(const Duration(milliseconds: 300));
      }
      if (entry.key == '18_voice_task') {
        await t.enterText(
          find.byType(TextField).first,
          'Resolver guía 4 — límites',
        );
        await t.pump(const Duration(milliseconds: 120));
      }
      if (entry.key == '19_voice_schedule') {
        await t.enterText(find.byType(TextField).at(0), 'Física II');
        await t.enterText(
          find.byType(TextField).at(1),
          'Aula B203',
        );
        await t.pump(const Duration(milliseconds: 120));
      }

      // Consume overflows pre-existentes (igual que responsive_views_test) para no fallar la captura
      t.takeException();

      await t.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2.0);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final file = File('capturas/${entry.key}.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        // ignore: avoid_print
        print('✓ ${file.path} (${img.width}x${img.height})');
      });
      // Limpia cualquier overflow residual
      t.takeException();
    });
  }
}
