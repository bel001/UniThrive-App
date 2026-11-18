import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_tokens.dart';
import '../models/subtask.dart';

class SubtaskListWidget extends StatefulWidget {
  final String taskId;
  final List<Subtask> subtasks;
  final Function(String subtaskId) onToggle;
  final Function(String subtaskId) onDelete;
  final Function(String title) onAdd;
  final Function(String subtaskId, String newTitle) onEdit;

  const SubtaskListWidget({
    super.key,
    required this.taskId,
    required this.subtasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  State<SubtaskListWidget> createState() => _SubtaskListWidgetState();
}

class _SubtaskListWidgetState extends State<SubtaskListWidget> {
  final TextEditingController _newSubtaskController = TextEditingController();
  String? _editingSubtaskId;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void dispose() {
    _newSubtaskController.dispose();
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Subtareas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (widget.subtasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.adaptiveMint(
                    context,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.subtasks.where((s) => s.completed).length}/${widget.subtasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.adaptiveMint(context),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        if (widget.subtasks.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: widget.subtasks.isEmpty
                  ? 0.0
                  : widget.subtasks.where((s) => s.completed).length /
                        widget.subtasks.length,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.adaptiveMint(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Subtask list
        ...widget.subtasks.map((subtask) {
          return _buildSubtaskItem(subtask, theme);
        }),

        // Add new subtask
        _buildAddSubtaskField(theme),
      ],
    );
  }

  Widget _buildSubtaskItem(Subtask subtask, ThemeData theme) {
    final isEditing = _editingSubtaskId == subtask.id;

    return Dismissible(
      key: Key(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar subtarea'),
            content: const Text('¿Estás seguro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => widget.onDelete(subtask.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: subtask.completed
              ? DesignTokens.success.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: subtask.completed
                ? DesignTokens.success.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: subtask.completed,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                widget.onToggle(subtask.id);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Title or edit field
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _getOrCreateEditController(subtask),
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          widget.onEdit(subtask.id, value);
                        }
                        setState(() => _editingSubtaskId = null);
                      },
                    )
                  : GestureDetector(
                      onTap: () =>
                          setState(() => _editingSubtaskId = subtask.id),
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          decoration: subtask.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: subtask.completed
                              ? Colors.grey.shade600
                              : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
            ),

            // Edit/Save button
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.check, size: 20),
                onPressed: () {
                  final controller = _editControllers[subtask.id];
                  if (controller != null && controller.text.isNotEmpty) {
                    widget.onEdit(subtask.id, controller.text);
                  }
                  setState(() => _editingSubtaskId = null);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => _showSubtaskOptions(subtask),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSubtaskField(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.mintStrong.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.add, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _newSubtaskController,
              decoration: const InputDecoration(
                hintText: 'Agregar subtarea...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  widget.onAdd(value);
                  _newSubtaskController.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 20, color: DesignTokens.mintStrong),
            onPressed: () {
              if (_newSubtaskController.text.isNotEmpty) {
                widget.onAdd(_newSubtaskController.text);
                _newSubtaskController.clear();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  TextEditingController _getOrCreateEditController(Subtask subtask) {
    if (!_editControllers.containsKey(subtask.id)) {
      _editControllers[subtask.id] = TextEditingController(text: subtask.title);
    }
    return _editControllers[subtask.id]!;
  }

  void _showSubtaskOptions(Subtask subtask) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _editingSubtaskId = subtask.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Eliminar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(subtask.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
