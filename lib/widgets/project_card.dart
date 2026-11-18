import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design_tokens.dart';
import '../models/project.dart';
import 'progress_bar.dart';

/// Tarjeta de proyecto estilo "Vivid Academic".
/// [rowLayout] = false → card bento para grid (mockup proyectos 1).
/// [rowLayout] = true → fila horizontal para lista (mockup proyectos 2).
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool rowLayout;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
    this.rowLayout = false,
  });

  static IconData iconForType(ProjectType type) => switch (type) {
        ProjectType.essay => Icons.history_edu_rounded,
        ProjectType.presentation => Icons.slideshow_rounded,
        ProjectType.development => Icons.code_rounded,
        ProjectType.study => Icons.science_rounded,
        ProjectType.creative => Icons.palette_rounded,
        ProjectType.general => Icons.folder_copy_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('project_${project.id}'),
      direction: DismissDirection.endToStart, // Solo borrar deslizando izquierda
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && onDelete != null) {
          final shouldDelete = await _confirmDelete(context);
          if (shouldDelete) {
            onDelete!();
            return true;
          }
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onError,
          size: 32,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? DesignTokens.cardDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.primary.withValues(alpha: 0.20)
                    : DesignTokens.divider,
                width: theme.brightness == Brightness.dark ? 1 : 2,
              ),
            ),
            child: rowLayout
                ? _RowContent(
                    project: project,
                    onDelete: onDelete,
                  )
                : _GridContent(
                    project: project,
                    onDelete: onDelete,
                  ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar proyecto'),
          content: Text('¿Seguro que deseas borrar "${project.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}

class _GridContent extends StatelessWidget {
  final Project project;
  final VoidCallback? onDelete;

  const _GridContent({required this.project, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: project.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                ProjectCard.iconForType(project.type),
                color: project.color,
                size: 30,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _DueBadge(project: project),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          project.description.isEmpty ? project.tag : project.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progreso', style: theme.textTheme.labelMedium),
            Text(
              '${project.progress.toInt()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: project.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(
          value: project.progress / 100,
          fillColor: project.color,
        ),
        if (onDelete != null)
          Align(
            alignment: Alignment.centerRight,
            child: _CardMenu(onDelete: onDelete!),
          ),
      ],
    );
  }
}

class _RowContent extends StatelessWidget {
  final Project project;
  final VoidCallback? onDelete;

  const _RowContent({required this.project, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: project.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            ProjectCard.iconForType(project.type),
            color: project.color,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                project.description.isEmpty ? project.tag : project.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ProgressBar(
                value: project.progress / 100,
                fillColor: project.color,
                height: 12,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _DueBadge(project: project),
            if (onDelete != null) _CardMenu(onDelete: onDelete!),
          ],
        ),
      ],
    );
  }
}

/// Badge "Vence en 3d" / "Vencido" como en los mockups.
class _DueBadge extends StatelessWidget {
  final Project project;

  const _DueBadge({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      project.dueDate.year,
      project.dueDate.month,
      project.dueDate.day,
    );
    final days = due.difference(today).inDays;
    final overdue = days < 0 && project.progress < 100;

    final String label;
    if (project.progress >= 100) {
      label = 'Completado';
    } else if (overdue) {
      label = 'Vencido';
    } else if (days == 0) {
      label = 'Vence hoy';
    } else if (days == 1) {
      label = 'Vence mañana';
    } else if (days < 7) {
      label = 'Vence en ${days}d';
    } else {
      label = 'Vence en ${days ~/ 7}sem';
    }

    final Color fg;
    final Color bg;
    if (overdue) {
      fg = theme.colorScheme.error;
      bg = theme.colorScheme.error.withValues(alpha: 0.14);
    } else if (project.progress >= 100) {
      fg = theme.colorScheme.secondary;
      bg = theme.colorScheme.secondary.withValues(alpha: 0.14);
    } else {
      fg = theme.colorScheme.onSurfaceVariant;
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          label,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onDelete;

  const _CardMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onSelected: (value) {
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'delete',
            child: Text('Eliminar proyecto'),
          ),
        ],
      ),
    );
  }
}
