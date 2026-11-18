import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../core/design_tokens.dart';
import '../../services/notification_service.dart';
import '../../utils/attachment_picker.dart';
import 'uni_primary_button.dart';

class QuickTaskForm extends StatefulWidget {
  final Project? initialProject;
  final Task? initialTask;

  const QuickTaskForm({super.key, this.initialProject, this.initialTask});

  @override
  State<QuickTaskForm> createState() => _QuickTaskFormState();
}

/// Categoría visible (mockup) → prefijo emoji heredado en el título.
/// Se conserva el mecanismo de prefijo para no romper títulos existentes.
class _CategoryOption {
  const _CategoryOption(this.label, this.icon, this.prefix);
  final String label;
  final IconData icon;
  final String prefix;
}

const _categoryOptions = <_CategoryOption>[
  _CategoryOption('Estudio', Icons.menu_book_outlined, '📚'),
  _CategoryOption('Proyecto', Icons.folder_outlined, '💼'),
  _CategoryOption('Personal', Icons.person_outlined, '🎨'),
  _CategoryOption('Más', Icons.add_rounded, '💡'),
];

/// Prefijos legacy que también se deben pelar al editar tareas antiguas.
const _legacyPrefixes = <String>['📚', '💼', '🎨', '🏃', '💡', '🔬'];

class _QuickTaskFormState extends State<QuickTaskForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _labelsController;
  late EnergyLevel _selectedEnergy;
  late TaskPriority _selectedPriority;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _reminderEnabled;
  String? _selectedImagePath;

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
      _selectedCategory = _categoryOptions
          .map((c) => c.prefix)
          .firstWhere(
            (prefix) => task.title.startsWith(prefix),
            orElse: () => '📚',
          );
    } else {
      _selectedCategory = '📚';
    }

    _selectedDate = task?.dueDate ?? DateTime.now();
    final due = task?.dueDate;
    _selectedTime = due != null
        ? TimeOfDay(hour: due.hour, minute: due.minute)
        : TimeOfDay.now();
    _reminderEnabled = true;
  }

  String _removeCategoryFromTitle(String title) {
    for (final prefix in _legacyPrefixes) {
      if (title.startsWith(prefix)) {
        return title.substring(prefix.length).trim();
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
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? DesignTokens.backgroundDark : theme.colorScheme.surface;
    final fieldBg = isDark
        ? DesignTokens.cardDarkAlt
        : theme.colorScheme.surfaceContainer;
    final titleColor = isDark
        ? DesignTokens.lilac
        : theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;
    final fieldBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : DesignTokens.divider;

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
            color: bg.withValues(alpha: 0.96),
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header: "Nueva Tarea" lila + close circular.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Tarea' : 'Nueva Tarea',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: fieldBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Título con botón mic.
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: '¿Qué hay que hacer?',
                    filled: true,
                    fillColor: fieldBg,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(6),
                      child: GestureDetector(
                        onTap: _onMicTap,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.20,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_outlined,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Descripción.
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  minLines: 1,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Añadir descripción o notas...',
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide(color: fieldBorder, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Adjuntos.
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
                            if (i != actions.length - 1)
                              const SizedBox(width: 10),
                          ],
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Categoría: carrusel horizontal.
                Text(
                  'Categoría'.toUpperCase(),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final option = _categoryOptions[index];
                      final selected =
                          _selectedCategory == option.prefix;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _selectedCategory = option.prefix,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.20,
                                  )
                                : fieldBg,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMedium,
                            ),
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : fieldBorder,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option.icon,
                                color: selected ? titleColor : muted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected ? titleColor : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Grid 2 col: Prioridad + Energía.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prioridad'.toUpperCase(),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMedium,
                              ),
                              border: Border.all(
                                color: fieldBorder,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: TaskPriority.values.map((priority) {
                                final selected =
                                    _selectedPriority == priority;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedPriority = priority,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.20)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            priority.priorityLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              color: selected
                                                  ? titleColor
                                                  : muted,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _priorityColor(context, priority),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Energía'.toUpperCase(),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMedium,
                              ),
                              border: Border.all(
                                color: fieldBorder,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: EnergyLevel.values.map((level) {
                                final selected = _selectedEnergy == level;
                                final activeColor = isDark
                                    ? DesignTokens.mintStrong
                                    : theme.colorScheme.secondary;
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedEnergy = level,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? activeColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.bolt,
                                          size: 16,
                                          color: selected
                                              ? activeColor
                                              : muted,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _energyLabel(level),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              color: selected
                                                  ? activeColor
                                                  : muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Etiquetas.
                TextField(
                  controller: _labelsController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Etiquetas separadas por coma',
                    prefixIcon: const Icon(Icons.sell_outlined),
                    filled: true,
                    fillColor: fieldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Fecha y hora: pills.
                Text(
                  'Fecha y hora'.toUpperCase(),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateTimePill(
                        icon: Icons.calendar_month_outlined,
                        label: _isToday(_selectedDate)
                            ? 'Hoy'
                            : '${_selectedDate.day}/${_selectedDate.month}',
                        onTap: _pickDate,
                        fieldBg: fieldBg,
                        borderColor: fieldBorder,
                        accent: titleColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTimePill(
                        icon: Icons.schedule_outlined,
                        label: _selectedTime.format(context),
                        onTap: _pickTime,
                        fieldBg: fieldBg,
                        borderColor: fieldBorder,
                        accent: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recordatorio + toggle.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(color: fieldBorder, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.20,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recordatorio',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              _reminderEnabled
                                  ? '30 min antes'
                                  : 'Desactivado',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (value) =>
                            setState(() => _reminderEnabled = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CTA chunky compartido.
                UniPrimaryButton(
                  label: isEditing ? 'Guardar cambios' : 'Crear Tarea',
                  onPressed: () => _saveTask(context, appState),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onMicTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usa el micrófono del teclado para dictar el título.'),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(
        () => _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _saveTask(BuildContext context, AppState appState) async {
    if (_titleController.text.trim().isEmpty) return;

    final title = '$_selectedCategory ${_titleController.text.trim()}';
    final labels = _labelsController.text
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    if (widget.initialTask != null) {
      // Editar tarea existente.
      appState.updateTask(
        taskId: widget.initialTask!.id,
        title: title,
        energy: _selectedEnergy,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        labels: labels,
        description: description,
        attachmentPath: _selectedImagePath,
        silent: !_reminderEnabled,
      );
      if (!_reminderEnabled) {
        await NotificationService.cancelTaskReminder(
          widget.initialTask!.id,
        );
      }
    } else {
      // Crear tarea nueva.
      final project =
          widget.initialProject ?? appState.getOrCreateQuickTasksProject();
      final created = appState.addTask(
        projectId: project.id,
        title: title,
        energy: _selectedEnergy,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        labels: labels,
        description: description,
        attachmentPath: _selectedImagePath,
        silent: !_reminderEnabled,
      );
      if (!_reminderEnabled) {
        await NotificationService.cancelTaskReminder(created.id);
      }
    }

    if (!context.mounted) return;
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

  String _energyLabel(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.low:
        return 'Baja';
      case EnergyLevel.medium:
        return 'Media';
      case EnergyLevel.high:
        return 'Alta';
    }
  }

  Color _priorityColor(BuildContext context, TaskPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case TaskPriority.low:
        return DesignTokens.adaptiveMint(context);
      case TaskPriority.medium:
        return isDark ? DesignTokens.lilac : scheme.primary;
      case TaskPriority.high:
        return DesignTokens.priorityPink;
      case TaskPriority.urgent:
        return scheme.error;
    }
  }
}

class _DateTimePill extends StatelessWidget {
  const _DateTimePill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.fieldBg,
    required this.borderColor,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color fieldBg;
  final Color borderColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
    );
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
