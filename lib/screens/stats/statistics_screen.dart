import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_card.dart';

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
    final completionRate = tasks.isEmpty ? 0 : (completedTasks / tasks.length);

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
                        Text(
                          '${(completionRate * 100).round()}%',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 48,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
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
