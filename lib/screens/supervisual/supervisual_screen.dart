import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../models/schedule.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_supervisual.dart';
import '../achievements/achievements_screen.dart';
import '../focus/focus_timer_screen.dart';
import '../stats/statistics_screen.dart';

/// Panel "supervisual": una sola pantalla con el estado completo del usuario
/// expresado en visualizaciones (anillo de progreso, métricas en gradiente,
/// gráfica semanal y próximos eventos).
class SupervisualScreen extends StatelessWidget {
  const SupervisualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final todayTasks = appState.allTasks
        .where((task) => task.dueDate != null && _isSameDay(task.dueDate!, now))
        .toList();
    final completedToday = todayTasks.where((task) => task.completed).length;
    final todayProgress = todayTasks.isEmpty
        ? 0.0
        : completedToday / todayTasks.length;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appState,
          builder: (context, _) {
            final nextClass = _nextBlockToday(appState.blocksForDay(now), now);
            final nextTask = _nextTask(appState.allTasks);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenHorizontal,
                12,
                DesignTokens.screenHorizontal,
                32,
              ),
              children: [
                // Header con gradiente decorativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            ]
                          : [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
                    border: isDark
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panel supervisual',
                                  style: theme.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat("EEEE d 'de' MMMM", 'es').format(now),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Mensaje motivacional contextual
                      _MotivationalBanner(
                        progress: todayProgress,
                        completedToday: completedToday,
                        totalToday: todayTasks.length,
                        streakDays: appState.streakDays,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _DayRingCard(progress: todayProgress, completed: completedToday, total: todayTasks.length),
                const SizedBox(height: 16),
                _MetricRow(appState: appState),
                const SizedBox(height: 24),
                Text('Tu semana', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _WeekChart(completedByDay: _completedByDay(appState)),
                const SizedBox(height: 24),
                Text('A continuación', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _NextUpCard(nextClass: nextClass, nextTask: nextTask),
                const SizedBox(height: 24),
                Text('Acciones rápidas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _QuickActions(appState: appState),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static ScheduleBlock? _nextBlockToday(List<ScheduleBlock> blocks, DateTime now) {
    ScheduleBlock? best;
    for (final block in blocks) {
      if (!block.start.isAfter(now)) continue;
      if (best == null || block.start.isBefore(best.start)) best = block;
    }
    return best;
  }

  static Task? _nextTask(List<Task> tasks) {
    final pending = tasks
        .where((task) => !task.completed && task.dueDate != null && task.dueDate!.isAfter(DateTime.now()))
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return pending.first;
  }

  static List<int> _completedByDay(AppState appState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      return appState.allTasks
          .where(
            (task) =>
                task.completedAt != null &&
                task.completedAt!.year == day.year &&
                task.completedAt!.month == day.month &&
                task.completedAt!.day == day.day,
          )
          .length;
    });
  }
}

// ==================== Banner motivacional ====================

class _MotivationalBanner extends StatelessWidget {
  const _MotivationalBanner({
    required this.progress,
    required this.completedToday,
    required this.totalToday,
    required this.streakDays,
  });

  final double progress;
  final int completedToday;
  final int totalToday;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _getMessage();
    return Row(
      children: [
        Icon(
          _getIcon(),
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getMessage() {
    if (totalToday == 0) {
      if (streakDays > 3) {
        return '¡$streakDays días de racha! Aprovecha para planear tu semana.';
      }
      return 'Día libre. Buen momento para organizar lo que viene.';
    }
    if (progress >= 1.0) {
      return '¡Día completo! Cerraste todas tus tareas. 🎉';
    }
    if (progress >= 0.7) {
      return '¡Casi! Te faltan ${totalToday - completedToday} para cerrar el día.';
    }
    if (progress >= 0.3) {
      return 'Vas por buen camino. Sigue con la siguiente tarea.';
    }
    return 'El día acaba de empezar. Una tarea a la vez.';
  }

  IconData _getIcon() {
    if (totalToday == 0) return Icons.wb_sunny_outlined;
    if (progress >= 1.0) return Icons.emoji_events_rounded;
    if (progress >= 0.7) return Icons.trending_up_rounded;
    if (progress >= 0.3) return Icons.directions_run_rounded;
    return Icons.flag_outlined;
  }
}

// ==================== Anillo del día ====================

class _DayRingCard extends StatelessWidget {
  const _DayRingCard({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Semantics(
            label:
                'Progreso de hoy: $completed de $total tareas completadas',
            child: UniRingProgress(
              progress: progress,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'de tu día',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            total == 0
                ? 'Sin tareas para hoy. ¡Momento perfecto para planear!'
                : completed == total
                    ? '¡Día completo! Completaste tus $total tareas.'
                    : '$completed de $total tareas completadas hoy.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Métricas ====================

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final focusMinutes = appState.focusHistory.fold<int>(
      0,
      (sum, session) => sum + session.elapsed.inMinutes,
    );
    final unlocked = appState.achievements
        .where((achievement) => achievement.unlockedAt != null)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        Widget card(Widget child) => SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 3,
              child: child,
            );

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            card(
              UniGradientMetricCard(
                icon: Icons.local_fire_department_rounded,
                value: '${appState.streakDays}',
                label: 'días de racha',
                gradient: UniGradientMetricCard.fireGradient,
              ),
            ),
            card(
              UniGradientMetricCard(
                icon: Icons.workspace_premium_rounded,
                value: 'Nivel ${appState.level}',
                label:
                    '${appState.xpProgressPercent.round()}% al siguiente nivel',
                gradient: UniGradientMetricCard.purpleGradient,
                progress: appState.xpProgressPercent / 100,
              ),
            ),
            card(
              UniGradientMetricCard(
                icon: Icons.bolt_rounded,
                value: _formatHours(focusMinutes),
                label: 'enfocadas · $unlocked logros',
                gradient: UniGradientMetricCard.greenGradient,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }
}

// ==================== Gráfica semanal ====================

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.completedByDay});

  final List<int> completedByDay;

  @override
  Widget build(BuildContext context) {
    return UniCard(
      radius: DesignTokens.radiusLarge,
      child: UniMiniBarChart(
        values: completedByDay,
        labels: UniMiniBarChart.lastDaysLabels(completedByDay.length),
        semanticUnit: 'tareas completadas',
      ),
    );
  }
}

// ==================== Próximos eventos ====================

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.nextClass, required this.nextTask});

  final ScheduleBlock? nextClass;
  final Task? nextTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('HH:mm');

    return UniCard(
      radius: DesignTokens.radiusLarge,
      child: Column(
        children: [
          if (nextClass != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: nextClass!.color.withValues(alpha: 0.18),
                child: Icon(Icons.school_rounded, color: nextClass!.color),
              ),
              title: Text(
                nextClass!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  '${formatter.format(nextClass!.start)}–${formatter.format(nextClass!.end)}',
                  if (nextClass!.location.isNotEmpty) nextClass!.location,
                  _timeUntil(nextClass!.start),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(Icons.event_available_rounded)),
              title: Text('Sin más clases hoy'),
              subtitle: Text('Disfruta el tiempo libre o adelanta tareas'),
            ),
          const Divider(),
          if (nextTask != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.flag_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                nextTask!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Entrega: ${DateFormat("EEE d MMM, HH:mm", 'es').format(nextTask!.dueDate!)} · ${_timeUntil(nextTask!.dueDate!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(Icons.task_alt_rounded)),
              title:Text('Sin entregas próximas'),
              subtitle: Text('Todo bajo control'),
            ),
        ],
      ),
    );
  }

  /// Returns a relative time label like "en 2h", "en 30min", "mañana".
  String _timeUntil(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return 'pasado';
    if (diff.inMinutes < 60) return 'en ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'en ${diff.inHours}h';
    if (diff.inDays == 1) return 'mañana';
    return 'en ${diff.inDays}d';
  }
}

// ==================== Acciones rápidas ====================

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        Widget btn(IconData icon, String label, VoidCallback onTap) => FilledButton.tonalIcon(
              onPressed: onTap,
              icon: Icon(icon),
              label: Text(label),
            );
        if (compact) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: btn(Icons.insights_rounded, 'Estadísticas', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const StatisticsScreen())))),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: btn(Icons.emoji_events_rounded, 'Logros', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const AchievementsScreen())))),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: btn(Icons.timer_rounded, 'Enfocar', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const FocusTimerScreen(focusLabel: 'Sesión rápida'))))),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: btn(Icons.insights_rounded, 'Estadísticas', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const StatisticsScreen())))),
            const SizedBox(width: 12),
            Expanded(child: btn(Icons.emoji_events_rounded, 'Logros', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const AchievementsScreen())))),
            const SizedBox(width: 12),
            Expanded(child: btn(Icons.timer_rounded, 'Enfocar', () => Navigator.of(context).push(SoftPageRoute(builder: (_) => const FocusTimerScreen(focusLabel: 'Sesión rápida'))))),
          ],
        );
      },
    );
  }
}
