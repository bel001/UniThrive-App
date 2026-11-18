import 'package:flutter/material.dart';

/// Barra de progreso gruesa estilo "Vivid Academic": 16px, puntas
/// redondeadas y brillo gloss en la mitad superior del relleno.
class ProgressBar extends StatelessWidget {
  final double value;
  final Color? fillColor;
  final Color? trackColor;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.fillColor,
    this.trackColor,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final track = trackColor ?? theme.colorScheme.surfaceContainerHighest;
    final fill = fillColor ?? theme.colorScheme.secondary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: clamped,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Gloss: brillo en la mitad superior, como en los mockups.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
