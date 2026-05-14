import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../core/design_tokens.dart';
import '../../utils/attachment_picker.dart';

class QuickTaskForm extends StatefulWidget {
  final Project? initialProject;
  final Task? initialTask;

  const QuickTaskForm({super.key, this.initialProject, this.initialTask});

  @override
  State<QuickTaskForm> createState() => _QuickTaskFormState();
}

class _QuickTaskFormState extends State<QuickTaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _labelsController;
  late EnergyLevel _selectedEnergy;
  late TaskPriority _selectedPriority;
  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedImagePath;

  final List<String> _categories = ['📚', '💼', '🎨', '🏃', '💡', '🔬'];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(
      text: task != null ? _removeCategoryFromTitle(task.title) : '',
    );
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _labelsController = TextEditingController(
      text: task?.labels.join(', ') ?? '',
    );
    _selectedImagePath = task?.attachmentPath;
    _selectedEnergy = task?.energy ?? EnergyLevel.medium;
    _selectedPriority = task?.priority ?? TaskPriority.medium;

    if (task != null) {
      _selectedCategory = _categories.firstWhere(
        (c) => task.title.startsWith(c),
        orElse: () => '📚',
      );
    } else {
      _selectedCategory = '📚';
    }

    _selectedDate = task?.dueDate ?? DateTime.now();
  }

  String _removeCategoryFromTitle(String title) {
    for (final category in _categories) {
      if (title.startsWith(category)) {
        return title.substring(category.length).trim();
      }
    }
    return title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _labelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final isEditing = widget.initialTask != null;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusXLarge),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: DesignTokens.screenHorizontal,
            right: DesignTokens.screenHorizontal,
            top: DesignTokens.screenHorizontal,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.sectionGap),

            // Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Editar Tarea' : 'Nueva Tarea Rápida',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Input
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '¿Qué vas a lograr hoy?',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              minLines: 1,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Añadir descripción o notas...',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attachment
            if (_selectedImagePath != null)
              _AttachmentPreview(
                value: _selectedImagePath!,
                onRemove: () => setState(() => _selectedImagePath = null),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 320;
                  final actions = [
                    _AttachmentAction(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Foto',
                      onTap: _pickImage,
                    ),
                    _AttachmentAction(
                      icon: Icons.attach_file_rounded,
                      label: 'Archivo',
                      onTap: _pickFile,
                    ),
                    _AttachmentAction(
                      icon: Icons.link_rounded,
                      label: 'Link',
                      onTap: _addLink,
                    ),
                  ];
                  if (compact) {
                    return Column(
                      children: actions
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SizedBox(
                                width: double.infinity,
                                child: action,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        Expanded(child: actions[i]),
                        if (i != actions.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),

            // Category Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Energy Level
            const Text(
              'Nivel de Energía',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: EnergyLevel.values.map((level) {
                final isSelected = _selectedEnergy == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedEnergy = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF9FCFBB).withValues(alpha: 0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF9FCFBB)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt,
                              color: isSelected
                                  ? const Color(0xFF9FCFBB)
                                  : Colors.grey,
                            ),
                            Text(
                              level.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? const Color(0xFF9FCFBB)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text(
              'Prioridad',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskPriority.values.map((priority) {
                final selected = _selectedPriority == priority;
                final color = _priorityColor(priority);
                return ChoiceChip(
                  label: Text(priority.priorityLabel),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                    color: selected ? color : Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedPriority = priority),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _labelsController,
              decoration: InputDecoration(
                hintText: 'Etiquetas separadas por coma',
                prefixIcon: const Icon(Icons.sell_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(
                        () => _selectedDate = DateTime.now().add(
                          const Duration(days: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                    label: const Text(
                      'Mañana',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveTask(context, appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FCFBB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF9FCFBB).withValues(alpha: 0.4),
                ),
                child: Text(
                  isEditing ? 'GUARDAR CAMBIOS' : 'CREAR TAREA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    )));
  }

  void _saveTask(BuildContext context, AppState appState) {
    if (_titleController.text.isEmpty) return;

    final title = '$_selectedCategory ${_titleController.text}';
    final labels = _labelsController.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();

    if (widget.initialTask != null) {
      // Edit existing task
      appState.updateTask(
        taskId: widget.initialTask!.id,
        title: title,
        energy: _selectedEnergy,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        labels: labels,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        attachmentPath: _selectedImagePath,
      );
    } else {
      // Create new task
      final project =
          widget.initialProject ?? appState.getOrCreateQuickTasksProject();
      appState.addTask(
        projectId: project.id,
        title: title,
        energy: _selectedEnergy,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        labels: labels,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        attachmentPath: _selectedImagePath,
      );
    }

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final image = await AttachmentPicker.pickImage();
    if (!mounted || image == null) return;
    setState(() => _selectedImagePath = image);
  }

  Future<void> _pickFile() async {
    final file = await AttachmentPicker.pickAnyFile();
    if (!mounted || file == null) return;
    setState(() => _selectedImagePath = file);
  }

  Future<void> _addLink() async {
    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar enlace'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (!mounted || link == null || link.isEmpty) return;
    final saved = await AttachmentPicker.saveLink(link);
    setState(() => _selectedImagePath = saved);
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return const Color(0xFF0EA5E9);
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.value, required this.onRemove});

  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isLink = AttachmentPicker.isLink(value);
    final isImage = !isLink && AttachmentPicker.isImage(value);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: isImage ? EdgeInsets.zero : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(value),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Row(
                  children: [
                    Icon(isLink ? Icons.link_rounded : Icons.insert_drive_file),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AttachmentPicker.fileName(value),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showQuickTaskForm(
  BuildContext context, {
  Project? initialProject,
  Task? initialTask,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        QuickTaskForm(initialProject: initialProject, initialTask: initialTask),
  );
}
