import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../projects/project_detail_screen.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/subtask_list_widget.dart';
import '../../widgets/pomodoro_timer_widget.dart';
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
        backgroundColor: const Color(0xFF9FCFBB),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF9FCFBB),
            foregroundColor: Colors.white,
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
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar tarea',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _getCategoryFromTitle(currentTask.title),
                style: const TextStyle(fontSize: 32),
              ),
              centerTitle: true,
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                _buildEditableTitle(context, appState, currentTask),
                const SizedBox(height: 24),

                // Project badge
                if (project != null) ...[
                  _buildProjectBadge(context, project),
                  const SizedBox(height: 24),
                ],

                // Quick stats
                _buildQuickStats(currentTask),
                const SizedBox(height: 24),

                // Time tracking & Pomodoro access
                _buildTimeTrackingSection(context, appState, currentTask),
                const SizedBox(height: 24),

                // Reminder Selector
                _buildReminderSelector(context, appState, currentTask),
                const SizedBox(height: 24),

                // Description
                _buildDescription(context, appState, currentTask),
                const SizedBox(height: 24),

                // Subtasks
                SubtaskListWidget(
                  taskId: currentTask.id,
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

                // Attachment
                if (currentTask.attachmentPath != null) ...[
                  _buildAttachment(currentTask),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildAddAttachmentButton(context, appState, currentTask),
                  const SizedBox(height: 24),
                ],

                // Complete button
                _buildCompleteButton(context, appState, currentTask),
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

  Widget _buildEditableTitle(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return GestureDetector(
      onTap: () => _editTitle(context, appState, task),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getTitleWithoutCategory(task.title),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.edit, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectBadge(BuildContext context, Project project) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          SoftPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              project.color.withValues(alpha: 0.2),
              project.color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: project.color.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder, color: project.color, size: 20),
            const SizedBox(width: 8),
            Text(
              project.name,
              style: TextStyle(
                color: project.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: project.color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(Task task) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Fecha límite',
            value: task.dueDate != null
                ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                : 'Sin fecha',
            color: const Color(0xFF9FCFBB),
            onTap: () => _editDueDate(context, task),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt,
            label: 'Energía',
            value: task.energy.name.toUpperCase(),
            color: _getEnergyColor(task.energy),
            onTap: () => _editEnergy(context, task),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeTrackingSection(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    final theme = Theme.of(context);
    final workSessions =
        task.pomodoroSessions.where((s) => !s.isBreak).toList();
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 8),
              const Text(
                'Tiempo dedicado',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${formatMinutes(totalMinutes)} · ${workSessions.length} sesiones',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                SoftPageRoute(
                  builder: (_) => FocusSessionScreen(
                    taskLabel: _getTitleWithoutCategory(task.title),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('Empezar tiempo de concentración'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9FCFBB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPomodoroTimer(context, appState, task),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Pomodoro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9FCFBB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTasksTimeHistory(context, appState),
                  icon: const Icon(Icons.history),
                  label: const Text('Ver historial'),
                ),
              ),
            ],
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
                        sessionLabel(
                          s.actualDurationMinutes,
                          s.wasCompleted,
                        ),
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
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
                Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEnergyColor(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.low:
        return Colors.green;
      case EnergyLevel.medium:
        return Colors.orange;
      case EnergyLevel.high:
        return Colors.red;
    }
  }

  Widget _buildDescription(BuildContext context, AppState appState, Task task) {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9FCFBB),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.description?.isEmpty ?? true
                  ? 'Sin descripción. Toca "Editar" para agregar una.'
                  : task.description!,
              style: TextStyle(
                color: task.description?.isEmpty ?? true
                    ? Colors.grey.shade500
                    : Colors.grey.shade800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachment(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adjunto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            task.attachmentPath!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, size: 48)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final path = await AttachmentPicker.pickImage();
        if (path != null) {
          appState.updateTask(taskId: task.id, attachmentPath: path);
        }
      },
      icon: const Icon(Icons.attach_file),
      label: const Text('Agregar imagen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCompleteButton(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          appState.toggleTask(task.id);
          Navigator.pop(context);
        },
        icon: Icon(task.completed ? Icons.undo : Icons.check_circle),
        label: Text(
          task.completed ? 'MARCAR COMO PENDIENTE' : 'MARCAR COMO COMPLETADA',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: task.completed
              ? Colors.grey.shade400
              : const Color(0xFF9FCFBB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: task.completed
              ? Colors.transparent
              : const Color(0xFF9FCFBB).withValues(alpha: 0.4),
        ),
      ),
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
              backgroundColor: const Color(0xFF9FCFBB),
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
                color: isSelected ? const Color(0xFF9FCFBB) : Colors.grey,
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

  void _shareTask(Task task, Project? project) {
    final text =
        '''
🎯 ${_getTitleWithoutCategory(task.title)}

${task.description?.isNotEmpty ?? false ? '📝 ${task.description}\n' : ''}
${project != null ? '📁 Proyecto: ${project.name}\n' : ''}
${task.dueDate != null ? '📅 Fecha: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}\n' : ''}
⚡ Energía: ${task.energy.name.toUpperCase()}

Creado con UniThrive
''';

    // Use share_plus for sharing
    // Share.share(text);

    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea copiada al portapapeles'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSelector(
    BuildContext context,
    AppState appState,
    Task task,
  ) {
    final minutes = task.customReminderMinutes;
    final text = minutes == null
        ? 'Recordatorio por defecto'
        : 'Recordar $minutes min antes';

    return GestureDetector(
      onTap: () => _editReminder(context, task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).disabledColor,
              size: 20,
            ),
          ],
        ),
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
                    ? const Icon(Icons.check, color: Colors.green)
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
                      ? const Icon(Icons.check, color: Colors.green)
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
    Navigator.of(context).push(
      SoftPageRoute(builder: (_) => const TaskHistoryScreen()),
    );
  }
}
