import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../models/subtask.dart';
import '../projects/project_detail_screen.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/pomodoro_timer_widget.dart';
import '../../widgets/uni_card.dart';
import '../../core/design_tokens.dart';
import '../../widgets/uni_primary_button.dart';
import '../../widgets/progress_bar.dart';
import '../../utils/attachment_picker.dart';
import '../focus/focus_session_screen.dart';
import 'task_history_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _descriptionController;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Get fresh task data
    final currentTask = appState.allTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );

    final project = appState.projectById(currentTask.projectId);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPomodoroTimer(context, appState, currentTask),
        icon: const Icon(Icons.timer),
        label: const Text('Pomodoro'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 88,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: scheme.onSurface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareTask(currentTask, project),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, appState, currentTask);
                  } else if (value == 'duplicate') {
                    final copy = appState.duplicateTask(currentTask.id);
                    if (copy != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tarea duplicada para seguir avanzando.',
                          ),
                        ),
                      );
                    }
                  } else if (value == 'reschedule') {
                    final updated = appState.rescheduleTaskSmart(
                      currentTask.id,
                    );
                    if (updated != null && updated.dueDate != null) {
                      final dueDate = updated.dueDate!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tarea reprogramada para ${dueDate.day}/${dueDate.month} a las ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}.',
                          ),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all_rounded),
                        SizedBox(width: 8),
                        Text('Duplicar tarea'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reschedule',
                    child: Row(
                      children: [
                        Icon(Icons.event_repeat_rounded),
                        SizedBox(width: 8),
                        Text('Reprogramar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar tarea',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 72,
                bottom: 16,
                end: 20,
              ),
              title: Text(
                'Detalle de tarea',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero: chip de categoría/estado + título + subtítulo
                _buildHero(context, appState, currentTask, project),
                const SizedBox(height: 16),

                // Agenda / etiquetas en chips con dot
                _buildTaskSignals(context, currentTask),
                const SizedBox(height: 16),

                // Bento 2 columnas: Tiempo + datos
                _buildBentoGrid(context, appState, currentTask),
                const SizedBox(height: 24),

                // Tiempo dedicado / Pomodoro
                _buildTimeTrackingSection(context, appState, currentTask),
                const SizedBox(height: 24),

                // Descripción
                _buildDescription(context, appState, currentTask),
                const SizedBox(height: 24),

                // Subtareas con checkbox custom + dimming
                _TaskSubtaskSection(
                  subtasks: currentTask.subtasks,
                  onToggle: (subtaskId) =>
                      appState.toggleSubtask(currentTask.id, subtaskId),
                  onDelete: (subtaskId) =>
                      appState.deleteSubtask(currentTask.id, subtaskId),
                  onAdd: (title) =>
                      appState.addSubtask(taskId: currentTask.id, title: title),
                  onEdit: (subtaskId, newTitle) => appState.editSubtask(
                    taskId: currentTask.id,
                    subtaskId: subtaskId,
                    newTitle: newTitle,
                  ),
                ),
                const SizedBox(height: 24),

                // Adjuntos
                if (currentTask.attachments.isNotEmpty) ...[
                  _buildAttachment(context, appState, currentTask),
                  const SizedBox(height: 12),
                ],
                _buildAddAttachmentButton(context, appState, currentTask),
                const SizedBox(height: 24),

                // Acciones: CTA chunky + secundarios
                _buildCompleteButton(context, appState, currentTask),
                const SizedBox(height: 12),
                _buildSecondaryActions(context, appState, currentTask),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryFromTitle(String title) {
    final categories = ['📚', '💼', '🎨', '🏃', '💡', '🔬'];
    for (final cat in categories) {
      if (title.startsWith(cat)) return cat;
    }
    return '📝';
  }

  String _getTitleWithoutCategory(String title) {
    final categories = ['📚', '💼', '🎨', '🏃', '💡', '🔬'];
    for (final cat in categories) {
      if (title.startsWith(cat)) {
        return title.substring(cat.length).trim();
      }
    }
    return title;
  }

  Widget _buildHero(
    BuildContext context,
    AppState appState,
    Task task,
    Project? project,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark
        ? DesignTokens.lilac
        : theme.colorScheme.primary;
    final category = _getCategoryFromTitle(task.title);
    final statusLabel = task.completed
        ? 'Completada'
        : task.isOverdue
            ? 'Vencida'
            : task.isDueSoon
                ? 'Próxima'
                : 'Pendiente';
    final subtitle = [
      if (project != null) project.name,
      if (task.dueDate != null)
        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
    ].join(' · ');

    return UniCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      task.priority.priorityLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (task.completed
                          ? DesignTokens.mintStrong
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: task.completed
                            ? DesignTokens.mintStrong
                            : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _editTitle(context, appState, task),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _getTitleWithoutCategory(task.title),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: project != null
                  ? () {
                      Navigator.of(context).push(
                        SoftPageRoute(
                          builder: (_) =>
                              ProjectDetailScreen(project: project),
                        ),
                      );
                    }
                  : null,
              child: Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final copy = appState.duplicateTask(task.id);
              if (copy != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tarea duplicada para seguir avanzando.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            label: const Text('Duplicar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, appState, task),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Eliminar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    final minutes = task.customReminderMinutes;
    final reminderLabel = minutes == null
        ? 'Por defecto'
        : '$minutes min antes';
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _buildStatCard(
          context: context,
          icon: Icons.calendar_today_rounded,
          label: 'Fecha límite',
          value: task.dueDate != null
              ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
              : 'Sin fecha',
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _editDueDate(context, task),
        ),
        _buildStatCard(
          context: context,
          icon: Icons.notifications_outlined,
          label: 'Recordatorio',
          value: reminderLabel,
          color: DesignTokens.mintStrong,
          onTap: () => _editReminder(context, task),
        ),
        _buildStatCard(
          context: context,
          icon: Icons.flag_outlined,
          label: 'Prioridad',
          value: task.priority.priorityLabel,
          color: _getPriorityColor(context, task.priority),
          onTap: () => _editPriority(context, task),
        ),
        _buildStatCard(
          context: context,
          icon: Icons.bolt_rounded,
          label: 'Energía',
          value: task.energy.name.toUpperCase(),
          color: _getEnergyColor(context, task.energy),
          onTap: () => _editEnergy(context, task),
        ),
      ],
    );
  }

  Widget _buildTaskSignals(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final chips = <Widget>[
      _SignalChip(
        icon: Icons.flag_rounded,
        label: task.priority.priorityLabel,
        color: _getPriorityColor(context, task.priority),
      ),
      if (task.isOverdue)
        _SignalChip(
          icon: Icons.warning_amber_rounded,
          label: 'Vencida',
          color: theme.colorScheme.error,
        )
      else if (task.isDueSoon)
        _SignalChip(
          icon: Icons.schedule_rounded,
          label: 'Próxima',
          color: theme.brightness == Brightness.dark
              ? DesignTokens.warningDark
              : DesignTokens.warning,
        ),
      ...task.labels.map(
        (label) => _SignalChip(
          icon: Icons.sell_outlined,
          label: label,
          color: theme.colorScheme.primary,
        ),
      ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bookmarks_outlined,
              size: 20,
              color: DesignTokens.lilac.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text('Etiquetas', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: chips),
      ],
    );
  }

  Widget _buildTimeTrackingSection(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    final theme = Theme.of(context);
    final workSessions = task.pomodoroSessions
        .where((s) => !s.isBreak)
        .toList();
    final totalMinutes = task.timeSpentMinutes;

    String formatMinutes(int minutes) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (hours == 0) return '${mins}m';
      return '${hours}h ${mins}m';
    }

    String sessionLabel(int minutes, bool completed) {
      final base = formatMinutes(minutes);
      return completed ? base : '$base · incompleta';
    }

    return UniCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.mintStrong.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: DesignTokens.mintStrong,
                ),
              ),
              Text(
                'Tiempo dedicado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${formatMinutes(totalMinutes)} · ${workSessions.length} sesiones',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          UniPrimaryButton(
            label: 'Empezar tiempo de concentración',
            icon: Icons.play_circle_fill_rounded,
            onPressed: () {
              Navigator.of(context).push(
                SoftPageRoute(
                  builder: (_) => FocusSessionScreen(
                    taskLabel: _getTitleWithoutCategory(task.title),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 360;
              if (stackButtons) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showPomodoroTimer(context, appState, task),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar Pomodoro'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showTasksTimeHistory(context, appState),
                        icon: const Icon(Icons.history),
                        label: const Text('Ver historial'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showPomodoroTimer(context, appState, task),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Pomodoro'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTasksTimeHistory(context, appState),
                      icon: const Icon(Icons.history),
                      label: const Text('Ver historial'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (workSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Últimas sesiones',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: workSessions
                  .take(4)
                  .map(
                    (s) => Chip(
                      label: Text(
                        sessionLabel(s.actualDurationMinutes, s.wasCompleted),
                      ),
                      avatar: const Icon(Icons.access_time, size: 16),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return UniCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnergyColor(BuildContext context, EnergyLevel energy) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (energy) {
      case EnergyLevel.low:
        return scheme.secondary;
      case EnergyLevel.medium:
        return isDark ? DesignTokens.warningDark : DesignTokens.warning;
      case EnergyLevel.high:
        return scheme.error;
    }
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case TaskPriority.low:
        return scheme.secondary;
      case TaskPriority.medium:
        return scheme.primary;
      case TaskPriority.high:
        return isDark ? DesignTokens.warningDark : DesignTokens.warning;
      case TaskPriority.urgent:
        return scheme.error;
    }
  }

  Widget _buildDescription(BuildContext context, AppState appState, Task task) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (!_isEditingDescription)
              TextButton.icon(
                onPressed: () => setState(() => _isEditingDescription = true),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isEditingDescription)
          Column(
            children: [
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Agrega detalles, notas o pasos...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _descriptionController.text = task.description ?? '';
                      setState(() => _isEditingDescription = false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      appState.updateTask(
                        taskId: task.id,
                        description: _descriptionController.text,
                      );
                      setState(() => _isEditingDescription = false);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          )
        else
          UniCard(
            radius: 24,
            child: Text(
              task.description?.isEmpty ?? true
                  ? 'Sin descripción. Toca "Editar" para agregar una.'
                  : task.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: task.description?.isEmpty ?? true
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachment(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.attachments.length == 1
              ? 'Adjunto'
              : 'Adjuntos (${task.attachments.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final path in task.attachments) ...[
          _AttachmentCard(
            value: path,
            onDelete: () {
              final remaining = task.attachments.where((a) => a != path)
                  .toList();
              appState.updateTask(
                taskId: task.id,
                attachments: remaining,
                removeAttachment: remaining.isEmpty,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAddAttachmentButton(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return UniPrimaryButton(
      label: 'Agregar adjunto',
      icon: Icons.attach_file_rounded,
      onPressed: () => _pickTaskAttachment(context, appState, task),
    );
  }

  Widget _buildCompleteButton(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return UniPrimaryButton(
      label: task.completed
          ? 'Marcar como pendiente'
          : 'Marcar como completada',
      icon: task.completed ? Icons.undo_rounded : Icons.check_circle_rounded,
      onPressed: () {
        HapticFeedback.mediumImpact();
        appState.toggleTask(task.id);
        Navigator.pop(context);
      },
    );
  }

  void _editTitle(BuildContext context, AppState appState, Task task) {
    final controller = TextEditingController(
      text: _getTitleWithoutCategory(task.title),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar título'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Título de la tarea'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final category = _getCategoryFromTitle(task.title);
                appState.updateTask(
                  taskId: task.id,
                  title: '$category ${controller.text}',
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _editDueDate(BuildContext context, Task task) async {
    final appState = AppStateProvider.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: task.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      appState.updateTask(taskId: task.id, dueDate: date);
    }
  }

  void _editEnergy(BuildContext context, Task task) {
    final appState = AppStateProvider.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nivel de energía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EnergyLevel.values.map((level) {
            final isSelected = task.energy == level;
            return ListTile(
              title: Text(level.name.toUpperCase()),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              onTap: () {
                appState.updateTask(taskId: task.id, energy: level);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editPriority(BuildContext context, Task task) {
    final appState = AppStateProvider.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prioridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) {
            final isSelected = task.priority == priority;
            return ListTile(
              title: Text(priority.priorityLabel),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? _getPriorityColor(context, priority)
                    : Colors.grey,
              ),
              onTap: () {
                appState.updateTask(taskId: task.id, priority: priority);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _shareTask(Task task, Project? project) async {
    final text =
        '''
🎯 ${_getTitleWithoutCategory(task.title)}

${task.description?.isNotEmpty ?? false ? '📝 ${task.description}\n' : ''}
${project != null ? '📁 Proyecto: ${project.name}\n' : ''}
${task.dueDate != null ? '📅 Fecha: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}\n' : ''}
⚡ Energía: ${task.energy.name.toUpperCase()}

Creado con UniThrive
''';

    await Share.share(text);
    // Copia de respaldo al portapapeles por comodidad.
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea compartida y copiada al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Estás seguro de eliminar "${_getTitleWithoutCategory(task.title)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.deleteTask(task.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editReminder(BuildContext context, Task task) {
    final appState = AppStateProvider.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Configurar Recordatorio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Usar configuración por defecto'),
                onTap: () {
                  appState.updateTask(
                    taskId: task.id,
                    customReminderMinutes: null, // Reset to default
                  );
                  Navigator.pop(context);
                },
                trailing: task.customReminderMinutes == null
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : null,
              ),
              const Divider(),
              ...[5, 10, 15, 30, 60, 120].map((min) {
                return ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text('$min minutos antes'),
                  onTap: () {
                    appState.updateTask(
                      taskId: task.id,
                      customReminderMinutes: min,
                    );
                    Navigator.pop(context);
                  },
                  trailing: task.customReminderMinutes == min
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                      : null,
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPomodoroTimer(BuildContext context, AppState appState, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: PomodoroTimerWidget(
            taskId: task.id,
            onSessionComplete: (session) {
              // Add session to task
              final updatedSessions = [...task.pomodoroSessions, session];
              final totalMinutes =
                  task.timeSpentMinutes + session.actualDurationMinutes;

              appState.updateTask(
                taskId: task.id,
                timeSpentMinutes: totalMinutes,
                pomodoroSessions: updatedSessions,
              );
              appState.registerPomodoroSession(session);
            },
          ),
        ),
      ),
    );
  }

  void _showTasksTimeHistory(BuildContext context, AppState appState) {
    // Navega al historial global de tiempo para ver métricas agregadas.
    Navigator.of(
      context,
    ).push(SoftPageRoute(builder: (_) => const TaskHistoryScreen()));
  }

  Future<void> _pickTaskAttachment(
    BuildContext context,
    AppState appState,
    Task task,
  ) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Adjuntar foto'),
              onTap: () async {
                final path = await AttachmentPicker.pickImage();
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('Adjuntar archivo'),
              onTap: () async {
                final path = await AttachmentPicker.pickAnyFile();
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: const Text('Guardar enlace'),
              onTap: () async {
                final controller = TextEditingController();
                final link = await showDialog<String>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Agregar enlace'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'https://...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(controller.text.trim()),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                );
                if (!sheetContext.mounted) return;
                Navigator.of(
                  sheetContext,
                ).pop(link == null || link.isEmpty ? null : link);
              },
            ),
          ],
        ),
      ),
    );
    if (value != null && value.isNotEmpty) {
      appState.updateTask(
        taskId: task.id,
        attachments: [...task.attachments, value],
      );
    }
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.cardDarkAlt : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : DesignTokens.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.value, required this.onDelete});

  final String value;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (AttachmentPicker.isLink(value)) {
      return UniCard(
        radius: 24,
        child: Row(
          children: [
            const Icon(Icons.link_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
              },
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: 'Eliminar adjunto',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    if (AttachmentPicker.isImage(value)) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.file(
              File(value),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Eliminar adjunto',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      );
    }

    return UniCard(
      radius: 24,
      child: Row(
        children: [
          Icon(
            AttachmentPicker.isPdf(value)
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AttachmentPicker.fileName(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Ruta copiada')));
            },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Eliminar adjunto',
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtareas estilo Vivid Academic Night: mismo checkbox custom redondeado
/// de 30px con check menta y dimming 0.55 que project_detail_screen.
/// Solo UI local; la lógica de estado vive en AppState y entra por
/// callbacks para no cambiar comportamiento.
class _TaskSubtaskSection extends StatefulWidget {
  final List<Subtask> subtasks;
  final void Function(String subtaskId) onToggle;
  final void Function(String subtaskId) onDelete;
  final void Function(String title) onAdd;
  final void Function(String subtaskId, String newTitle) onEdit;

  const _TaskSubtaskSection({
    required this.subtasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  State<_TaskSubtaskSection> createState() => _TaskSubtaskSectionState();
}

class _TaskSubtaskSectionState extends State<_TaskSubtaskSection> {
  final TextEditingController _newController = TextEditingController();

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final done = widget.subtasks.where((s) => s.completed).length;
    final total = widget.subtasks.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Subtareas', style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.mintStrong.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$done/$total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? DesignTokens.mint
                        : DesignTokens.success,
                  ),
                ),
              ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          ProgressBar(
            value: progress,
            fillColor: DesignTokens.mintStrong,
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 12),
        for (final subtask in widget.subtasks)
          Opacity(
            opacity: subtask.completed ? 0.55 : 1.0,
            child: Card(
              color: isDark ? DesignTokens.cardDarkAlt : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? DesignTokens.lilac.withValues(alpha: 0.20)
                      : DesignTokens.divider,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onToggle(subtask.id);
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: subtask.completed
                              ? DesignTokens.mintStrong
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: subtask.completed
                                ? DesignTokens.mintStrong
                                : theme.colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: subtask.completed
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Color(0xFF002114),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _editSubtaskTitle(context, subtask),
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: subtask.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar subtarea',
                      onPressed: () => widget.onDelete(subtask.id),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        UniCard(
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newController,
                  decoration: const InputDecoration(
                    hintText: 'Agregar subtarea...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: _submit,
                ),
              ),
              IconButton(
                tooltip: 'Agregar subtarea',
                onPressed: () => _submit(_newController.text),
                icon: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: DesignTokens.mintStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _newController.clear();
  }

  Future<void> _editSubtaskTitle(
    BuildContext context,
    Subtask subtask,
  ) async {
    final controller = TextEditingController(text: subtask.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar subtarea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la subtarea'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    if (confirmed == true && text.isNotEmpty && text != subtask.title) {
      widget.onEdit(subtask.id, text);
    }
  }
}
