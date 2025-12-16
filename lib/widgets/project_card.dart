import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/project.dart';
import '../core/design_tokens.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: isDark ? Colors.white70 : DesignTokens.textSecondary,
    );

    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact(); // Consistent tactile feedback
              onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(DesignTokens.sectionGap),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: titleStyle),
            const SizedBox(height: 6),
            Text(
              'Entrega: ${project.dueDate.format()} · ${project.tag}',
              style: secondaryStyle,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (project.progress / 100).clamp(0.0, 1.0),
              color: project.color,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              minHeight: 6,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${project.progress.toInt()}% completado',
                  style: secondaryStyle,
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar proyecto',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.more_horiz,
                    color: isDark ? Colors.white54 : Colors.grey.shade400,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on DateTime {
  String format() =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
}
