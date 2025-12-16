import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../core/design_tokens.dart';
import '../../utils/productivity_insights.dart';

class TaskHistoryScreen extends StatelessWidget {
  const TaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Get tasks with time spent
    final tasksWithTime =
        appState.allTasks.where((t) => t.timeSpentMinutes > 0).toList()
          ..sort((a, b) => b.timeSpentMinutes.compareTo(a.timeSpentMinutes));

    final totalMinutes = tasksWithTime.fold<int>(
      0,
      (sum, task) => sum + task.timeSpentMinutes,
    );

    final totalSessions = tasksWithTime.fold<int>(
      0,
      (sum, task) => sum + task.pomodoroSessions.length,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Tiempo'), elevation: 0),
      body: tasksWithTime.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              slivers: [
                // Statistics Card
                SliverToBoxAdapter(
                  child: _buildStatisticsCard(
                    context,
                    theme,
                    totalMinutes,
                    totalSessions,
                    tasksWithTime.length,
                  ),
                ),

                // Productivity Insights Card
                SliverToBoxAdapter(
                  child: _buildProductivityInsights(context, theme, appState),
                ),

                // Tasks List
                SliverPadding(
                  padding: EdgeInsets.all(DesignTokens.screenHorizontal),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = tasksWithTime[index];
                      return _buildTaskTimeCard(context, theme, task);
                    }, childCount: tasksWithTime.length),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Sin historial aún',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el temporizador Pomodoro para comenzar a registrar tu tiempo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    ThemeData theme,
    int totalMinutes,
    int totalSessions,
    int tasksCount,
  ) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF9FCFBB),
              const Color(0xFF9FCFBB).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FCFBB).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Estadísticas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer,
                  label: 'Tiempo Total',
                  value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                ),
                _buildStatItem(
                  icon: Icons.done_all,
                  label: 'Sesiones',
                  value: '$totalSessions',
                ),
                _buildStatItem(
                  icon: Icons.task_alt,
                  label: 'Tareas',
                  value: '$tasksCount',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTimeCard(BuildContext context, ThemeData theme, Task task) {
    final hours = task.timeSpentMinutes ~/ 60;
    final minutes = task.timeSpentMinutes % 60;
    final sessionsCount = task.pomodoroSessions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: const Color(0xFF9FCFBB).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: task.completed ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: DesignTokens.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9FCFBB),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9FCFBB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$sessionsCount sesión${sessionsCount != 1 ? 'es' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9FCFBB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityInsights(
    BuildContext context,
    ThemeData theme,
    AppState appState,
  ) {
    // Recopilar todas las sesiones Pomodoro
    final allSessions = appState.allTasks
        .expand((task) => task.pomodoroSessions)
        .toList();

    // Early return si no hay suficientes datos
    if (allSessions.isEmpty || allSessions.length < 2) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> insights;
    try {
      insights = ProductivityInsights.analyze(allSessions);
    } catch (e) {
      debugPrint('Error analyzing insights: $e');
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenHorizontal,
        8,
        DesignTokens.screenHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1CB0F6),
              const Color(0xFF1CB0F6).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1CB0F6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Insights de Productividad',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Best Day & Hour
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    icon: Icons.calendar_today,
                    label: 'Mejor Día',
                    value: insights['bestDayOfWeek'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    icon: Icons.access_time,
                    label: 'Mejor Hora',
                    value: insights['bestHourOfDay'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Average & Streak
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    icon: Icons.trending_up,
                    label: 'Promedio/Día',
                    value:
                        '${insights['averageSessionsPerDay'].toStringAsFixed(1)}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightItem(
                    icon: Icons.local_fire_department,
                    label: 'Racha',
                    value: '${insights['currentStreak']} días',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
