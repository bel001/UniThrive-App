import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../models/schedule.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/quick_task_form.dart';
import '../../widgets/global_search_sheet.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_primary_button.dart';
import '../../widgets/voice_schedule_sheet.dart';
import '../../widgets/voice_task_sheet.dart';
import '../alarms/alarm_screen.dart';
import '../tasks/task_history_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../stats/statistics_screen.dart';
import '../achievements/achievements_screen.dart';
import '../focus/focus_timer_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appState,
          builder: (context, _) {
            final todayTasks = _getTodayTasks(appState);
            final upcomingTasks = _getUpcomingTasks(appState);
            final overdueTasks = _getOverdueTasks(appState);
            final todayBlocks = appState.blocksForDay(DateTime.now());
            final completedToday = todayTasks
                .where((task) => task.completed)
                .length;

            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 450));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.screenHorizontal,
                  12,
                  DesignTokens.screenHorizontal,
                  128,
                ),
                children: [
                  _DashboardHeader(
                    appState: appState,
                    onSearch: () => showGlobalSearchSheet(context),
                    onOpenTaskCenter: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const TaskHistoryScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _QuickActionStrip(
                    onQuickTask: () => showQuickTaskForm(context),
                    onNewClass: () => showVoiceScheduleSheet(
                      context,
                      referenceDay: DateTime.now(),
                    ),
                    onVoiceTask: () => showVoiceTaskSheet(context),
                    onSearch: () => showGlobalSearchSheet(context),
                    onAlarm: () => Navigator.of(
                      context,
                    ).push(SoftPageRoute(builder: (_) => const AlarmScreen())),
                    onFocus: () => Navigator.of(context).push(
                      SoftPageRoute(
                        builder: (_) => const FocusTimerScreen(
                          focusLabel: 'Sesión rápida',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _TodayCard(
                    appState: appState,
                    completedToday: completedToday,
                    todayTasks: todayTasks,
                    todayBlocks: todayBlocks,
                    onQuickTask: () => showQuickTaskForm(context),
                    onVoiceTask: () => showVoiceTaskSheet(context),
                    onViewUpcoming: () => _showTasksSheet(
                      context,
                      appState: appState,
                      title: 'Próximas tareas',
                      tasks: upcomingTasks,
                    ),
                    onStreakTap: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const StatisticsScreen()),
                    ),
                    onLevelTap: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const AchievementsScreen()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DailySummaryCard(
                    todayTasks: todayTasks,
                    todayBlocks: todayBlocks,
                    overdueCount: overdueTasks.length,
                  ),
                  if (overdueTasks.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _OverdueCard(
                      overdueTasks: overdueTasks,
                      onTap: () => _showTasksSheet(
                        context,
                        appState: appState,
                        title: 'Tareas vencidas',
                        tasks: overdueTasks,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _TaskSection(
                    title: 'Hoy',
                    subtitle: todayTasks.isEmpty
                        ? 'Sin pendientes programadas.'
                        : 'Tu agenda inmediata.',
                    tasks: todayTasks.take(4).toList(),
                    emptyMessage:
                        'Tu día está despejado. Puedes crear una tarea rápida o dejarlo así.',
                    actionLabel: 'Ver todo hoy',
                    onAction: () => _showTasksSheet(
                      context,
                      appState: appState,
                      title: 'Tareas de hoy',
                      tasks: todayTasks,
                    ),
                    onToggle: appState.toggleTask,
                    onOpen: (task) => _showTaskDetail(context, task),
                    projectNameForTask: (task) =>
                        appState.projectById(task.projectId)?.name ??
                        'Tarea rápida',
                  ),
                  const SizedBox(height: 24),
                  _TaskSection(
                    title: 'Próximo',
                    subtitle: upcomingTasks.isEmpty
                        ? 'No hay tareas en las próximas 72 horas.'
                        : 'Lo siguiente para que no te tome por sorpresa.',
                    tasks: upcomingTasks.take(4).toList(),
                    emptyMessage:
                        'No hay nada urgente en el corto plazo. Buen momento para avanzar con calma.',
                    actionLabel: 'Ver próximas',
                    onAction: () => _showTasksSheet(
                      context,
                      appState: appState,
                      title: 'Próximas tareas',
                      tasks: upcomingTasks,
                    ),
                    onToggle: appState.toggleTask,
                    onOpen: (task) => _showTaskDetail(context, task),
                    projectNameForTask: (task) =>
                        appState.projectById(task.projectId)?.name ??
                        'Tarea rápida',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Task> _getTodayTasks(AppState appState) {
    final now = DateTime.now();
    return appState.allTasks.where((task) {
      final dueDate = task.dueDate;
      return dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).toList()..sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return (a.dueDate ?? now).compareTo(b.dueDate ?? now);
    });
  }

  List<Task> _getUpcomingTasks(AppState appState) {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 3));
    return appState.allTasks
        .where(
          (task) =>
              !task.completed &&
              task.dueDate != null &&
              task.dueDate!.isAfter(now) &&
              task.dueDate!.isBefore(horizon),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Task> _getOverdueTasks(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appState.allTasks
        .where(
          (task) =>
              !task.completed &&
              task.dueDate != null &&
              DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ).isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  void _showTaskDetail(BuildContext context, Task task) {
    Navigator.of(
      context,
    ).push(SoftPageRoute(builder: (_) => TaskDetailScreen(task: task)));
  }

  Future<void> _showTasksSheet(
    BuildContext context, {
    required AppState appState,
    required String title,
    required List<Task> tasks,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No hay tareas para mostrar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final projectName =
                              appState.projectById(task.projectId)?.name ??
                              'Tarea rápida';

                          return _TaskRowCard(
                            task: task,
                            projectName: projectName,
                            onToggle: () {
                              appState.toggleTask(task.id);
                              setSheetState(() {});
                            },
                            onTap: () {
                              Navigator.of(context).pop();
                              _showTaskDetail(sheetContext, task);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AppState appState;
  final VoidCallback onSearch;
  final VoidCallback onOpenTaskCenter;

  const _DashboardHeader({
    required this.appState,
    required this.onSearch,
    required this.onOpenTaskCenter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _capitalize(
      DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now()),
    );
    final firstName = appState.userName.trim().isEmpty
        ? 'Usuario'
        : appState.userName.trim().split(' ').first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text('Hola, $firstName', style: theme.textTheme.displayLarge),
              const SizedBox(height: 6),
              Text(
                'Tu espacio de estudio para avanzar con calma.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Buscar en la app',
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Centro de tareas',
          onPressed: onOpenTaskCenter,
          icon: const Icon(Icons.checklist_rounded),
        ),
        const SizedBox(width: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/mascot/mascot_happy.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  firstName.characters.first.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final AppState appState;
  final int completedToday;
  final List<Task> todayTasks;
  final List<ScheduleBlock> todayBlocks;
  final VoidCallback onQuickTask;
  final VoidCallback onVoiceTask;
  final VoidCallback onViewUpcoming;
  final VoidCallback onStreakTap;
  final VoidCallback onLevelTap;

  const _TodayCard({
    required this.appState,
    required this.completedToday,
    required this.todayTasks,
    required this.todayBlocks,
    required this.onQuickTask,
    required this.onVoiceTask,
    required this.onViewUpcoming,
    required this.onStreakTap,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = todayTasks.isEmpty
        ? 0.0
        : completedToday / todayTasks.length;
    final pendingTasks = todayTasks.where((task) => !task.completed).toList();
    final nextTask = pendingTasks.isEmpty ? null : pendingTasks.first;
    final nextClass = todayBlocks.isEmpty ? null : todayBlocks.first;
    final summary = todayTasks.isEmpty
        ? 'No tienes tareas para hoy. Puedes dejar el día ligero o empezar con una rápida.'
        : completedToday == todayTasks.length
        ? 'Cerraste todo lo de hoy. Muy buena señal.'
        : 'Te quedan ${todayTasks.length - completedToday} tareas. Sigue con la siguiente importante.';

    return UniCard(
      radius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PillLabel(
                icon: Icons.sunny,
                label: 'Hoy',
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todayTasks.isEmpty
                      ? 'Agenda libre'
                      : '$completedToday/${todayTasks.length} completadas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            todayTasks.isEmpty
                ? 'Un panel limpio para empezar.'
                : 'Tu día en una sola vista.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Racha',
                  value: '${appState.streakDays} días',
                  tone: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.primary,
                  onTap: onStreakTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Nivel',
                  value: 'Nv ${appState.level}',
                  tone: theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.onSurface,
                  onTap: onLevelTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Siguiente tarea',
                  value: nextTask?.dueDate != null
                      ? DateFormat('HH:mm').format(nextTask!.dueDate!)
                      : 'Libre',
                  tone: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              nextClass == null
                  ? 'No hay clases registradas hoy. Si sales de una clase, puedes dictarla desde el calendario.'
                  : 'Próxima clase: ${nextClass.title} a las ${DateFormat('HH:mm').format(nextClass.start)}.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = constraints.maxWidth < 260;
              if (stackActions) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: UniPrimaryButton(
                            label: 'Nueva tarea',
                            icon: Icons.add_rounded,
                            onPressed: onQuickTask,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _VoiceActionButton(onPressed: onVoiceTask),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onViewUpcoming,
                        child: const Text('Ver próximas'),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: UniPrimaryButton(
                      label: 'Nueva tarea',
                      icon: Icons.add_rounded,
                      onPressed: onQuickTask,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _VoiceActionButton(onPressed: onVoiceTask),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewUpcoming,
                      child: const Text('Ver próximas'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip({
    required this.onQuickTask,
    required this.onNewClass,
    required this.onVoiceTask,
    required this.onSearch,
    required this.onAlarm,
    required this.onFocus,
  });

  final VoidCallback onQuickTask;
  final VoidCallback onNewClass;
  final VoidCallback onVoiceTask;
  final VoidCallback onSearch;
  final VoidCallback onAlarm;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionTile(
        icon: Icons.add_task_rounded,
        label: 'Nueva tarea',
        onTap: onQuickTask,
      ),
      _ActionTile(
        icon: Icons.school_rounded,
        label: 'Nueva clase',
        onTap: onNewClass,
      ),
      _ActionTile(
        icon: Icons.mic_rounded,
        label: 'Dictar tarea',
        onTap: onVoiceTask,
      ),
      _ActionTile(
        icon: Icons.search_rounded,
        label: 'Buscar',
        onTap: onSearch,
      ),
      _ActionTile(
        icon: Icons.alarm_add_rounded,
        label: 'Alarma',
        onTap: onAlarm,
      ),
      _ActionTile(
        icon: Icons.timer_rounded,
        label: 'Modo Foco',
        onTap: onFocus,
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.todayTasks,
    required this.todayBlocks,
    required this.overdueCount,
  });

  final List<Task> todayTasks;
  final List<ScheduleBlock> todayBlocks;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UniCard(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del día', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PillLabel(
                icon: Icons.task_alt_rounded,
                label: '${todayTasks.length} tareas',
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
              ),
              _PillLabel(
                icon: Icons.calendar_month_rounded,
                label: '${todayBlocks.length} bloques',
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
              ),
              _PillLabel(
                icon: Icons.warning_amber_rounded,
                label: '$overdueCount vencidas',
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _VoiceActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton.filledTonal(
        tooltip: 'Dictar tarea',
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.primary,
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.mic_rounded),
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final List<Task> overdueTasks;
  final VoidCallback onTap;

  const _OverdueCard({required this.overdueTasks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.priority_high_rounded,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Necesita atención',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${overdueTasks.length} tarea${overdueTasks.length == 1 ? '' : 's'} vencida${overdueTasks.length == 1 ? '' : 's'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.error),
          ],
        ),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Task> tasks;
  final String emptyMessage;
  final String actionLabel;
  final VoidCallback onAction;
  final ValueChanged<String> onToggle;
  final ValueChanged<Task> onOpen;
  final String Function(Task task) projectNameForTask;

  const _TaskSection({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.emptyMessage,
    required this.actionLabel,
    required this.onAction,
    required this.onToggle,
    required this.onOpen,
    required this.projectNameForTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
        const SizedBox(height: 14),
        if (tasks.isEmpty)
          _EmptyTaskState(message: emptyMessage)
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return SizedBox(
                  width: 300, // Ancho fijo para las tarjetas en carrusel
                  child: _TaskRowCard(
                    task: task,
                    projectName: projectNameForTask(task),
                    onToggle: () => onToggle(task.id),
                    onTap: () => onOpen(task),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TaskRowCard extends StatelessWidget {
  final Task task;
  final String projectName;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TaskRowCard({
    required this.task,
    required this.projectName,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueText = task.dueDate == null
        ? 'Sin hora'
        : DateFormat('HH:mm').format(task.dueDate!);
    final energyColor = switch (task.energy) {
      EnergyLevel.low => theme.colorScheme.secondary,
      EnergyLevel.medium => theme.colorScheme.tertiary,
      EnergyLevel.high => theme.colorScheme.error,
    };
    final priorityColor = switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => theme.colorScheme.primary,
      TaskPriority.high => Colors.orange,
      TaskPriority.urgent => theme.colorScheme.error,
    };

    return Dismissible(
      key: ValueKey('dash_task_${task.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false; // Don't actually dismiss, just toggle the checkbox visually
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Icon(
          task.completed ? Icons.remove_done_rounded : Icons.check_circle_rounded,
          color: theme.colorScheme.onPrimary,
          size: 32,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Checkbox.adaptive(
                value: task.completed,
                onChanged: (_) => onToggle(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(projectName, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PillLabel(
                          icon: Icons.schedule_rounded,
                          label: dueText,
                          backgroundColor: task.isOverdue
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: task.isOverdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        _PillLabel(
                          icon: Icons.flag_outlined,
                          label: task.priority.priorityLabel,
                          backgroundColor: priorityColor.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: priorityColor,
                        ),
                        _PillLabel(
                          icon: Icons.bolt_rounded,
                          label: task.energyLabel,
                          backgroundColor: energyColor.withValues(alpha: 0.12),
                          foregroundColor: energyColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _EmptyTaskState extends StatelessWidget {
  final String message;

  const _EmptyTaskState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final Color textColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.tone,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _PillLabel({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
