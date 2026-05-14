import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../utils/productivity_insights.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/quick_task_form.dart';
import '../../widgets/soft_page_route.dart';
import '../../screens/tasks/task_detail_screen.dart';

enum _TaskFilter { all, today, overdue, upcoming, completed }

class TaskHistoryScreen extends StatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  _TaskFilter _filter = _TaskFilter.all;
  String _selectedProjectId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final filteredTasks = _filteredTasks(appState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de tareas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tareas'),
            Tab(text: 'Tiempo'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickTaskForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva tarea'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(context, appState, filteredTasks),
          _TimeInsightsTab(appState: appState),
        ],
      ),
    );
  }

  Widget _buildTasksTab(
    BuildContext context,
    AppState appState,
    List<Task> filteredTasks,
  ) {
    final projects = appState.projects;
    final hasTasks = appState.allTasks.isNotEmpty;

    if (!hasTasks) {
      return EmptyStates.noTasks(context, () => showQuickTaskForm(context));
    }

    if (filteredTasks.isEmpty) {
      return EmptyStateWidget(
        emoji: '🔎',
        title: 'No hay tareas con este filtro',
        subtitle:
            'Prueba otro estado, cambia de curso o crea una nueva tarea para seguir.',
        buttonText: 'CREAR TAREA',
        onButtonPressed: () => showQuickTaskForm(context),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.screenHorizontal,
        12,
        DesignTokens.screenHorizontal,
        120,
      ),
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar tareas, cursos o etiquetas',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _TaskFilter.values.map((filter) {
            return ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedProjectId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Curso o proyecto',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          selectedItemBuilder: (context) {
            return [
              const Text('Todos', maxLines: 1, overflow: TextOverflow.ellipsis),
              ...projects.map(
                (project) => Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ];
          },
          items: [
            const DropdownMenuItem(value: 'all', child: Text('Todos')),
            ...projects.map(
              (project) => DropdownMenuItem(
                value: project.id,
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) =>
              setState(() => _selectedProjectId = value ?? 'all'),
        ),
        const SizedBox(height: 18),
        ...filteredTasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TaskActionCard(
              task: task,
              projectName:
                  appState.projectById(task.projectId)?.name ?? 'Tarea rápida',
              onToggle: () => setState(() => appState.toggleTask(task.id)),
              onOpen: () => Navigator.of(context).push(
                SoftPageRoute(builder: (_) => TaskDetailScreen(task: task)),
              ),
              onReschedule: () {
                final updated = appState.rescheduleTaskSmart(task.id);
                if (updated?.dueDate != null) {
                  final due = updated!.dueDate!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Reprogramada para ${due.day}/${due.month} a las ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}.',
                      ),
                    ),
                  );
                }
                setState(() {});
              },
              onDuplicate: () {
                appState.duplicateTask(task.id);
                setState(() {});
              },
              onDelete: () {
                appState.deleteTask(task.id);
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Task> _filteredTasks(AppState appState) {
    final query = _normalize(_searchController.text);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = appState.allTasks.where((task) {
      if (_selectedProjectId != 'all' && task.projectId != _selectedProjectId) {
        return false;
      }

      final dueDate = task.dueDate;
      switch (_filter) {
        case _TaskFilter.today:
          if (dueDate == null ||
              dueDate.year != now.year ||
              dueDate.month != now.month ||
              dueDate.day != now.day) {
            return false;
          }
          break;
        case _TaskFilter.overdue:
          if (task.completed ||
              dueDate == null ||
              DateTime(
                dueDate.year,
                dueDate.month,
                dueDate.day,
              ).isAfter(today) ||
              DateTime(dueDate.year, dueDate.month, dueDate.day) == today) {
            return false;
          }
          break;
        case _TaskFilter.upcoming:
          if (task.completed ||
              dueDate == null ||
              dueDate.isBefore(now) ||
              dueDate.isAfter(now.add(const Duration(days: 3)))) {
            return false;
          }
          break;
        case _TaskFilter.completed:
          if (!task.completed) return false;
          break;
        case _TaskFilter.all:
          break;
      }

      if (query.isEmpty) return true;
      final projectName = appState.projectById(task.projectId)?.name ?? '';
      return _normalize(task.title).contains(query) ||
          _normalize(task.description ?? '').contains(query) ||
          _normalize(projectName).contains(query) ||
          task.labels.any((label) => _normalize(label).contains(query));
    }).toList();

    filtered.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      final priorityDiff = b.priority.index.compareTo(a.priority.index);
      if (priorityDiff != 0) return priorityDiff;
      final aDate = a.dueDate ?? DateTime(2100);
      final bDate = b.dueDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });
    return filtered;
  }

  String _filterLabel(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.all:
        return 'Todas';
      case _TaskFilter.today:
        return 'Hoy';
      case _TaskFilter.overdue:
        return 'Vencidas';
      case _TaskFilter.upcoming:
        return 'Próximas';
      case _TaskFilter.completed:
        return 'Completadas';
    }
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }
}

class _TaskActionCard extends StatelessWidget {
  const _TaskActionCard({
    required this.task,
    required this.projectName,
    required this.onToggle,
    required this.onOpen,
    required this.onReschedule,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Task task;
  final String projectName;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onReschedule;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueLabel = task.dueDate == null
        ? 'Sin fecha'
        : '${task.dueDate!.day}/${task.dueDate!.month} · ${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}';
    final priorityColor = switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.blue,
      TaskPriority.high => Colors.orange,
      TaskPriority.urgent => Colors.red,
    };

    return Dismissible(
      key: ValueKey(task.id),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: task.completed ? Colors.orange : Colors.green,
        icon: task.completed ? Icons.undo_rounded : Icons.check_rounded,
        label: task.completed ? 'Reabrir' : 'Completar',
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Color(0xFF1D4ED8),
        icon: Icons.more_horiz_rounded,
        label: 'Acciones',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        final action = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event_repeat_rounded),
                  title: const Text('Reprogramar'),
                  onTap: () => Navigator.of(sheetContext).pop('reschedule'),
                ),
                ListTile(
                  leading: const Icon(Icons.copy_all_rounded),
                  title: const Text('Duplicar'),
                  onTap: () => Navigator.of(sheetContext).pop('duplicate'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop('delete'),
                ),
              ],
            ),
          ),
        );
        if (action == 'reschedule') {
          onReschedule();
        } else if (action == 'duplicate') {
          onDuplicate();
        } else if (action == 'delete') {
          onDelete();
        }
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
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
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: dueLabel,
                            color: task.isOverdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          _InfoChip(
                            icon: Icons.flag_outlined,
                            label: task.priority.priorityLabel,
                            color: priorityColor,
                          ),
                          if (task.labels.isNotEmpty)
                            _InfoChip(
                              icon: Icons.sell_outlined,
                              label: task.labels.first,
                              color: theme.colorScheme.primary,
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

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeInsightsTab extends StatelessWidget {
  const _TimeInsightsTab({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksWithTime =
        appState.allTasks.where((t) => t.timeSpentMinutes > 0).toList()
          ..sort((a, b) => b.timeSpentMinutes.compareTo(a.timeSpentMinutes));

    if (tasksWithTime.isEmpty) {
      return EmptyStateWidget(
        emoji: '⏱️',
        title: 'Sin historial aún',
        subtitle:
            'Usa el temporizador Pomodoro para empezar a registrar tiempo y recibir insights.',
        buttonText: 'CREAR TAREA',
        onButtonPressed: () => showQuickTaskForm(context),
      );
    }

    final totalMinutes = tasksWithTime.fold<int>(
      0,
      (sum, task) => sum + task.timeSpentMinutes,
    );
    final totalSessions = tasksWithTime.fold<int>(
      0,
      (sum, task) => sum + task.pomodoroSessions.length,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenHorizontal,
            12,
            DesignTokens.screenHorizontal,
            120,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TimeSummaryCard(
                totalMinutes: totalMinutes,
                totalSessions: totalSessions,
                tasksCount: tasksWithTime.length,
              ),
              const SizedBox(height: 16),
              _InsightsCard(appState: appState),
              const SizedBox(height: 16),
              Text('Tareas con más tiempo', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              ...tasksWithTime.map((task) => _TimedTaskTile(task: task)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TimeSummaryCard extends StatelessWidget {
  const _TimeSummaryCard({
    required this.totalMinutes,
    required this.totalSessions,
    required this.tasksCount,
  });

  final int totalMinutes;
  final int totalSessions;
  final int tasksCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9FCFBB),
            const Color(0xFF9FCFBB).withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiempo invertido',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SummaryMetric(
                label: 'Tiempo total',
                value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
              ),
              _SummaryMetric(label: 'Sesiones', value: '$totalSessions'),
              _SummaryMetric(label: 'Tareas', value: '$tasksCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final analysis = ProductivityInsights.analyze(
      appState.allTasks.expand((task) => task.pomodoroSessions).toList(),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insight actual',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Mejor día: ${analysis['bestDayOfWeek']} · Mejor hora: ${analysis['bestHourOfDay']} · Racha productiva: ${analysis['currentStreak']}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TimedTaskTile extends StatelessWidget {
  const _TimedTaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final hours = task.timeSpentMinutes ~/ 60;
    final minutes = task.timeSpentMinutes % 60;
    final timeLabel = hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            task.completed
                ? Icons.task_alt_rounded
                : Icons.pending_actions_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '$timeLabel · ${task.pomodoroSessions.length} sesiones',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
