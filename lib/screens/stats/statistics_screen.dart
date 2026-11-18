import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_supervisual.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tasks = appState.allTasks;
    final completedTasks = tasks.where((task) => task.completed).length;
    final activeTasks = tasks.length - completedTasks;
    final overdueTasks = tasks.where((task) => task.isOverdue).length;
    final dueSoonTasks = tasks.where((task) => task.isDueSoon).length;
    final completionRate = tasks.isEmpty
        ? 0.0
        : (completedTasks / tasks.length);

    final totalFocusMinutes = appState.focusHistory.fold<int>(
      0,
      (sum, session) => sum + session.elapsed.inMinutes,
    );
    final trackedMinutes = tasks.fold<int>(
      0,
      (sum, task) => sum + task.timeSpentMinutes,
    );
    final activeProjects = appState.activeProjects.length;
    final unlockedAchievements = appState.achievements
        .where((achievement) => achievement.unlockedAt != null)
        .length;
    final courseBreakdown = <String, int>{};
    for (final task in tasks) {
      final name =
          appState.projectById(task.projectId)?.name ?? 'Tareas rápidas';
      courseBreakdown[name] = (courseBreakdown[name] ?? 0) + 1;
    }
    final topCourse = courseBreakdown.entries.isEmpty
        ? null
        : (courseBreakdown.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
    final nextTask =
        tasks.where((task) => !task.completed && task.dueDate != null).toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenHorizontal,
                12,
                DesignTokens.screenHorizontal,
                132,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Estadísticas', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Una lectura rápida de tu ritmo, foco y progreso académico.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  UniCard(
                    radius: 32,
                    color: scheme.primaryContainer.withValues(alpha: 0.72),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Semantics(
                              label:
                                  '${(completionRate * 100).round()}% de tareas completadas',
                              child: UniRingProgress(
                                progress: completionRate,
                                size: 110,
                                progressColor: scheme.primary,
                                trackColor: scheme.onPrimaryContainer
                                    .withValues(alpha: 0.14),
                                center: Text(
                                  '${(completionRate * 100).round()}%',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'de tareas completadas',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tasks.isEmpty
                                        ? 'Empieza creando tareas para ver tu progreso crecer.'
                                        : '$completedTasks terminadas de ${tasks.length} registradas.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onPrimaryContainer.withValues(
                                        alpha: 0.76,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricPill(
                              icon: Icons.local_fire_department_outlined,
                              label: '${appState.streakDays} días de racha',
                            ),
                            _MetricPill(
                              icon: Icons.workspace_premium_outlined,
                              label: 'Nivel ${appState.level}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Pulso general', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      final itemWidth = compact
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.schedule_rounded,
                              label: 'Tiempo enfocado',
                              value: _formatMinutes(totalFocusMinutes),
                              subtitle: 'Sesiones finalizadas',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.timer_outlined,
                              label: 'Tiempo registrado',
                              value: _formatMinutes(trackedMinutes),
                              subtitle: 'Pomodoros y trabajo acumulado',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.folder_copy_outlined,
                              label: 'Proyectos activos',
                              value: '$activeProjects',
                              subtitle: 'Frentes abiertos ahora',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.task_alt_rounded,
                              label: 'Pendientes',
                              value: '$activeTasks',
                              subtitle: 'Tareas aún por resolver',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Vencidas',
                              value: '$overdueTasks',
                              subtitle: 'Requieren reprogramación',
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              icon: Icons.schedule_rounded,
                              label: 'Próximas 24h',
                              value: '$dueSoonTasks',
                              subtitle: 'Para no perder el ritmo',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _HistoryChartCard(
                    completedTasks: tasks
                        .where((task) => task.completedAt != null)
                        .map((task) => task.completedAt!)
                        .toList(),
                    focusSessions: appState.focusHistory
                        .map(
                          (session) => MapEntry(
                            session.startTime,
                            session.elapsed.inMinutes,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  Text('Momento actual', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  UniCard(
                    radius: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightRow(
                          icon: Icons.flag_outlined,
                          title: 'Próxima entrega',
                          subtitle: nextTask.isEmpty
                              ? 'Sin entregas inmediatas'
                              : nextTask.first.title,
                          trailing: nextTask.isEmpty
                              ? 'Libre'
                              : _friendlyDeadline(nextTask.first.dueDate!),
                        ),
                        const Divider(height: 28),
                        _HighlightRow(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Logros desbloqueados',
                          subtitle:
                              'Has convertido constancia en progreso medible.',
                          trailing: '$unlockedAchievements',
                        ),
                        const Divider(height: 28),
                        _HighlightRow(
                          icon: Icons.school_outlined,
                          title: 'Curso más activo',
                          subtitle: topCourse == null
                              ? 'Todavía no hay suficientes datos por curso.'
                              : 'Tienes más movimiento reciente en ${topCourse.key}.',
                          trailing: topCourse?.value.toString() ?? '0',
                        ),
                        const Divider(height: 28),
                        _HighlightRow(
                          icon: Icons.bolt_outlined,
                          title: 'XP acumulada',
                          subtitle:
                              'A ${appState.xpForNextLevel} XP del siguiente nivel.',
                          trailing: '${appState.experiencePoints}',
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return UniCard(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 290;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: stacked ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!stacked) ...[
                  const SizedBox(width: 12),
                  Text(trailing, style: theme.textTheme.titleSmall),
                ],
              ],
            ),
            if (stacked) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(trailing, style: theme.textTheme.titleSmall),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMinutes(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0 min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) {
    return '$minutes min';
  }
  if (minutes == 0) {
    return '$hours h';
  }
  return '$hours h $minutes min';
}

class _HistoryChartCard extends StatefulWidget {
  const _HistoryChartCard({
    required this.completedTasks,
    required this.focusSessions,
  });

  final List<DateTime> completedTasks;
  final List<MapEntry<DateTime, int>> focusSessions;

  @override
  State<_HistoryChartCard> createState() => _HistoryChartCardState();
}

enum _HistoryMetric { tasks, focus }

enum _HistoryRange { week, month }

class _HistoryChartCardState extends State<_HistoryChartCard> {
  _HistoryMetric _metric = _HistoryMetric.tasks;
  _HistoryRange _range = _HistoryRange.week;

  List<({String label, int value})> _buildBuckets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isTasks = _metric == _HistoryMetric.tasks;

    if (_range == _HistoryRange.week) {
      return List.generate(7, (index) {
        final day = today.subtract(Duration(days: 6 - index));
        const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        var value = 0;
        if (isTasks) {
          value = widget.completedTasks
              .where(
                (date) =>
                    date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day,
              )
              .length;
        } else {
          value = widget.focusSessions
              .where(
                (entry) =>
                    entry.key.year == day.year &&
                    entry.key.month == day.month &&
                    entry.key.day == day.day,
              )
              .fold(0, (sum, entry) => sum + entry.value);
        }
        return (
          label: dayLabels[day.weekday - 1],
          value: value,
        );
      });
    }

    // Mes: 4 semanas hacia atrás desde hoy.
    return List.generate(4, (index) {
      final start = today
          .subtract(Duration(days: 7 * (4 - index) + today.weekday - 1));
      final end = start.add(const Duration(days: 7));
      var value = 0;
      if (isTasks) {
        value = widget.completedTasks
            .where((date) => !date.isBefore(start) && date.isBefore(end))
            .length;
      } else {
        value = widget.focusSessions
            .where((entry) => !entry.key.isBefore(start) && entry.key.isBefore(end))
            .fold(0, (sum, entry) => sum + entry.value);
      }
      return (label: 'S${index + 1}', value: value);
    });
  }

  String _unitLabel(int value) {
    if (_metric == _HistoryMetric.tasks) return '$value';
    if (value < 60) return '${value}m';
    return '${value ~/ 60}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final buckets = _buildBuckets();
    final maxValue = buckets.fold<int>(
      0,
      (max, bucket) => bucket.value > max ? bucket.value : max,
    );

    return UniCard(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu histórico', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Actividad de tareas completadas y minutos de foco.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SegmentedButton<_HistoryMetric>(
            segments: const [
              ButtonSegment(
                value: _HistoryMetric.tasks,
                label: Text('Tareas'),
                icon: Icon(Icons.task_alt_rounded),
              ),
              ButtonSegment(
                value: _HistoryMetric.focus,
                label: Text('Foco'),
                icon: Icon(Icons.bolt_rounded),
              ),
            ],
            selected: {_metric},
            onSelectionChanged: (selection) =>
                setState(() => _metric = selection.first),
          ),
          const SizedBox(height: 10),
          SegmentedButton<_HistoryRange>(
            segments: const [
              ButtonSegment(value: _HistoryRange.week, label: Text('Semana')),
              ButtonSegment(value: _HistoryRange.month, label: Text('Mes')),
            ],
            selected: {_range},
            onSelectionChanged: (selection) =>
                setState(() => _range = selection.first),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final bucket in buckets)
                  Expanded(
                    child: Semantics(
                      label:
                          '${bucket.label}: ${_unitLabel(bucket.value)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              maxValue > 0 ? _unitLabel(bucket.value) : '',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: maxValue == 0
                                      ? 0
                                      : (bucket.value / maxValue).clamp(
                                          bucket.value > 0 ? 0.06 : 0,
                                          1.0,
                                        ),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(
                                        alpha: bucket.value > 0 ? 0.85 : 0.15,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(bucket.label,
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyDeadline(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = target.difference(today).inDays;

  if (difference == 0) {
    return 'Hoy';
  }
  if (difference == 1) {
    return 'Mañana';
  }
  return '${date.day}/${date.month}';
}
