import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../widgets/uni_card.dart';
import '../../utils/attachment_picker.dart';
import '../../widgets/uni_primary_button.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final tasks = appState.tasksForProject(project.id);
    final latestProject = appState.projectById(project.id) ?? project;
    final completed = tasks.where((task) => task.completed).length;
    final total = tasks.length;
    return Scaffold(
      appBar: AppBar(title: Text(latestProject.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildProgressCard(
            context,
            latestProject,
            completed: completed,
            total: total,
            onGenerate: () => appState.generatePlanForProject(project.id),
          ),
          const SizedBox(height: 20),
          const Text(
            'El checklist maestro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Column(
              children: [
                const Text(
                  'Aún no hay pasos aquí. Genera un plan inteligente para comenzar.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => appState.generatePlanForProject(project.id),
                  child: const Text('Generar plan'),
                ),
              ],
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                appState.moveTaskWithinProject(
                  projectId: project.id,
                  taskId: tasks[oldIndex].id,
                  newIndex: newIndex,
                );
              },
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _ChecklistRow(
                  key: ValueKey(task.id),
                  task: task,
                  index: index,
                  onChanged: () => appState.toggleTask(task.id),
                  onEdit: () => _editTaskTitle(context, appState, task),
                  onDelete: () => _confirmDeleteStep(context, appState, task),
                );
              },
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _promptAddStep(context, appState),
            child: const Text('Agregar paso'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    Project project, {
    required int completed,
    required int total,
    required VoidCallback onGenerate,
  }) {
    return UniCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso general',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (project.progress / 100).clamp(0.0, 1.0),
            color: project.color,
            backgroundColor: Colors.grey.shade200,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${project.progress.toInt()}% del plan cumplido',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Entrega: ${project.dueDate.format()}',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            total == 0
                ? 'Aún no hay pasos. Genera tu plan inteligente.'
                : '$completed de $total pasos completados. ¡Sigue así!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            UniPrimaryButton(
              expand: false,
              label: 'Generar plan',
              onPressed: onGenerate,
            ),
        ],
      ),
    );
  }

  Future<void> _promptAddStep(BuildContext context, AppState appState) async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String? attachmentPath;
    EnergyLevel selectedEnergy = EnergyLevel.medium;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuevo paso',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'Título del paso',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Notas o contexto adicional',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await AttachmentPicker.pickImage();
                        if (!context.mounted) return;
                        if (picked != null) {
                          setSheetState(() => attachmentPath = picked);
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        attachmentPath == null
                            ? 'Adjuntar imagen'
                            : 'Cambiar imagen',
                      ),
                    ),
                    if (attachmentPath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(attachmentPath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Nivel de energía',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: EnergyLevel.values.map((level) {
                        final label = switch (level) {
                          EnergyLevel.low => 'Baja',
                          EnergyLevel.medium => 'Media',
                          EnergyLevel.high => 'Alta',
                        };
                        return ChoiceChip(
                          label: Text(label),
                          selected: selectedEnergy == level,
                          onSelected: (_) {
                            setSheetState(() => selectedEnergy = level);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    UniPrimaryButton(
                      label: 'Guardar',
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        appState.addTask(
                          projectId: project.id,
                          title: titleController.text.trim(),
                          dueDate: project.dueDate,
                          energy: selectedEnergy,
                          description: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          attachmentPath: attachmentPath,
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editTaskTitle(
    BuildContext context,
    AppState appState,
    Task task,
  ) async {
    final controller = TextEditingController(text: task.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar paso'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Actualiza el nombre del paso',
            ),
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
        );
      },
    );
    final text = controller.text.trim();
    if (confirmed == true && text.isNotEmpty && text != task.title) {
      appState.updateTask(taskId: task.id, title: text);
    }
  }

  Future<void> _confirmDeleteStep(
    BuildContext context,
    AppState appState,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar paso'),
          content: Text(
            '¿Seguro que deseas eliminar "${task.title}" del checklist?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      appState.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Paso eliminado.')));
      }
    }
  }
}

class _ChecklistRow extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ChecklistRow({
    super.key,
    required this.task,
    required this.index,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(value: task.completed, onChanged: (_) => onChanged()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Text(
                    task.dueLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (task.attachmentPath != null)
                    TextButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(
                            child: Image.file(
                              File(task.attachmentPath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Ver adjunto'),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.more_vert),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on DateTime {
  String format() =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
}
