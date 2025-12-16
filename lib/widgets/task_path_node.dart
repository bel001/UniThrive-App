import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../core/design_tokens.dart';

class TaskPathNode extends StatelessWidget {
  final Task task;
  final Project? project;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final bool showDragHandle;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  const TaskPathNode({
    super.key,
    required this.task,
    this.project,
    this.isActive = false,
    this.isCompleted = false,
    this.isLocked = false,
    this.showDragHandle = false,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: Text('¿Eliminar "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Path line and node
            Column(
              children: [
                _buildNode(context),
                if (!isLocked)
                  Container(
                    width: 3,
                    height: 60,
                    color: isCompleted
                        ? const Color(0xFF9FCFBB)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Task content
            Expanded(
              child: GestureDetector(
                onTap: isLocked ? null : onTap,
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.cardPadding),
                  decoration: BoxDecoration(
                    color: _getCardColor(),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusLarge,
                    ),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF9FCFBB)
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF58CC02,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: DesignTokens.cardElevation * 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getCategoryIcon(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize:
                                    18, // Increased from 16 for better readability
                                fontWeight: FontWeight.w700,
                                color: isLocked
                                    ? DesignTokens.textDisabled
                                    : const Color(
                                        0xFF0F172A,
                                      ), // Always dark text for light card backgrounds
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (showDragHandle && !isCompleted && !isLocked)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.drag_indicator,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                          if (!isLocked)
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showOptions(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      SizedBox(height: DesignTokens.itemGap),
                      Row(
                        children: [
                          _buildXPBadge(),
                          SizedBox(width: DesignTokens.itemGap),
                          _buildEnergyStars(),
                          const Spacer(),
                          if (task.dueDate != null)
                            Text(
                              _formatTime(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: DesignTokens
                                    .textSecondary, // WCAG compliant
                              ),
                            ),
                        ],
                      ),
                      // Subtask progress indicator
                      if (task.subtasks.isNotEmpty && !isCompleted) ...[
                        SizedBox(height: DesignTokens.mediumGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value:
                                task.subtasks.where((s) => s.completed).length /
                                task.subtasks.length,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF9FCFBB),
                            ),
                          ),
                        ),
                      ],
                      if (isActive && !isCompleted) ...[
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              onPressed: onToggle,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF9FCFBB),
                              ),
                              tooltip: 'Marcar como hecha',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF9FCFBB),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FCFBB).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 24),
      );
    } else if (isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9FCFBB), Color(0xFF89E219)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FCFBB).withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
      );
    } else if (isLocked) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock,
          color: DesignTokens.textDisabled, // WCAG compliant
          size: 20,
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 3),
        ),
      );
    }
  }

  Color _getCardColor() {
    if (isLocked) return DesignTokens.surfaceVariant;
    if (isCompleted) return const Color(0xFFF0FFF0);
    // Active cards get a subtle mint tint background
    if (isActive) return const Color(0xFFF0FFF8);
    return Colors.white;
  }

  Widget _getCategoryIcon() {
    // You can customize this based on project type
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1CB0F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('📚', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildXPBadge() {
    final xp = task.energy == EnergyLevel.high
        ? 25
        : (task.energy == EnergyLevel.medium ? 15 : 10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStars() {
    final count = task.energy == EnergyLevel.high
        ? 3
        : (task.energy == EnergyLevel.medium ? 2 : 1);
    return Row(
      children: List.generate(
        3,
        (index) => Icon(
          index < count ? Icons.bolt : Icons.bolt_outlined,
          size: 16,
          color: index < count ? const Color(0xFFFF6B35) : Colors.grey.shade400,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return '⏱️ ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '📅 ${time.day}/${time.month}';
  }

  void _showOptions(BuildContext context) {
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
              leading: const Icon(Icons.check_circle),
              title: const Text('Marcar completa'),
              onTap: () {
                Navigator.pop(context);
                onToggle?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
