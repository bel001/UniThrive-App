import 'package:flutter/material.dart';

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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji with optional circle background
            if (showCircle)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF9FCFBB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 60)),
                ),
              )
            else
              Text(emoji, style: const TextStyle(fontSize: 80)),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
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

            // Optional button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FCFBB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF9FCFBB).withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
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
