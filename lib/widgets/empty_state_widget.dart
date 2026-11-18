import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

/// Reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showCircle;

  const EmptyStateWidget({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.showCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 430 || constraints.maxWidth < 360;
        final circleSize = compact ? 96.0 : 120.0;
        final emojiSize = compact ? 48.0 : 60.0;
        final freeEmojiSize = compact ? 64.0 : 80.0;
        final titleSize = compact ? 22.0 : 26.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isInfinite 
                  ? 300 
                  : constraints.maxHeight,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCircle)
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: DesignTokens.adaptiveMint(
                          context,
                        ).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: emojiSize),
                        ),
                      ),
                    )
                  else
                    Text(emoji, style: TextStyle(fontSize: freeEmojiSize)),
                  SizedBox(height: compact ? 18 : 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (buttonText != null && onButtonPressed != null) ...[
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: onButtonPressed,
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: Text(
                        buttonText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.adaptiveMint(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: DesignTokens.adaptiveMint(
                          context,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Predefined empty states
class EmptyStates {
  static Widget noTasks(BuildContext context, VoidCallback onAdd) {
    return EmptyStateWidget(
      emoji: '🎯',
      title: 'Sin tareas para hoy',
      subtitle: '¡Perfecto momento para planificar!',
      buttonText: 'CREAR PRIMERA TAREA',
      onButtonPressed: onAdd,
    );
  }

  static Widget noProjects(BuildContext context, VoidCallback onAdd) {
    return EmptyStateWidget(
      emoji: '📁',
      title: 'Sin proyectos',
      subtitle: 'Organiza tu trabajo en proyectos',
      buttonText: 'CREAR PROYECTO',
      onButtonPressed: onAdd,
    );
  }

  static Widget noAchievements(BuildContext context, {String? message}) {
    return EmptyStateWidget(
      emoji: '🏆',
      title: 'Sin logros aún',
      subtitle: message ?? 'Completa tareas para desbloquear logros',
      showCircle: true,
    );
  }

  static Widget noSearch(BuildContext context) {
    return const EmptyStateWidget(
      emoji: '🔍',
      title: 'Sin resultados',
      subtitle: 'Intenta con otros términos',
      showCircle: false,
    );
  }

  static Widget noSchedule(BuildContext context) {
    return const EmptyStateWidget(
      emoji: '📅',
      title: 'Horario vacío',
      subtitle: 'Agrega bloques de clases o estudio',
      showCircle: true,
    );
  }

  static Widget error(BuildContext context, String message) {
    return EmptyStateWidget(
      emoji: '⚠️',
      title: 'Algo salió mal',
      subtitle: message,
      showCircle: false,
    );
  }
}
