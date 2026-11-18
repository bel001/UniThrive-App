import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Componentes visuales compartidos del lenguaje "supervisual":
/// anillos de progreso, tarjetas métricas en gradiente y mini gráficas de
/// barras. Usados por todas las vistas principales para una identidad común.

// ==================== Anillo de progreso ====================

/// Anillo circular con porcentaje al centro.
class UniRingProgress extends StatelessWidget {
  const UniRingProgress({
    super.key,
    required this.progress,
    required this.center,
    this.size = 190,
    this.trackColor,
    this.progressColor,
  });

  final double progress;
  final Widget center;
  final double size;
  final Color? trackColor;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _UniRingPainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: trackColor ??
              (isDark
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerHighest),
          progressColor: progressColor ?? scheme.primary,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _UniRingPainter extends CustomPainter {
  _UniRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final inset = (Offset.zero & size).deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(inset, 0, math.pi * 2, false, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(inset, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_UniRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}

// ==================== Tarjeta métrica en gradiente ====================

/// Tarjeta compacta con fondo en gradiente para resaltar una métrica clave.
class UniGradientMetricCard extends StatelessWidget {
  const UniGradientMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
    this.progress,
  });

  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;
  final double? progress;

  static const fireGradient = [Color(0xFFFF9A56), Color(0xFFDC5B53)];
  static const purpleGradient = [Color(0xFF8E7BFF), Color(0xFF5F72E4)];
  static const greenGradient = [Color(0xFF34C98E), Color(0xFF0E7A53)];

  // Variantes oscuras con menos saturación para no vibrar sobre #0B1117.
  static const fireGradientDark = [Color(0xFF8B4A2B), Color(0xFF6B2A28)];
  static const purpleGradientDark = [Color(0xFF4A3D8B), Color(0xFF2E3A6B)];
  static const greenGradientDark = [Color(0xFF184A36), Color(0xFF12372A)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedGradient = isDark ? _darkGradient(gradient) : gradient;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : gradient.last.withValues(alpha: 0.32);
    return Semantics(
      label: '$value, $label',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: resolvedGradient,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  List<Color> _darkGradient(List<Color> g) {
    if (g == fireGradient) return fireGradientDark;
    if (g == purpleGradient) return purpleGradientDark;
    if (g == greenGradient) return greenGradientDark;
    return g;
  }
}

// ==================== Mini gráfica de barras ====================

/// Gráfica de barras compacta para series cortas (semana, mes).
/// La última barra se resalta con gradiente primario→terciario.
class UniMiniBarChart extends StatelessWidget {
  const UniMiniBarChart({
    super.key,
    required this.values,
    this.labels,
    this.highlightLast = true,
    this.height = 150,
    this.semanticUnit = '',
  });

  final List<int> values;
  final List<String>? labels;
  final bool highlightLast;
  final double height;
  /// Sufijo para la etiqueta semántica (p.ej. 'tareas completadas').
  final String semanticUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chartLabels =
        labels ?? List.generate(values.length, (_) => '');
    final maxValue = values.fold<int>(0, (max, value) => value > max ? value : max);
    final highlightIndex = highlightLast ? values.length - 1 : -1;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                label: '${chartLabels[i]}: ${values[i]} $semanticUnit'.trim(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        values[i] > 0 ? '${values[i]}' : '',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: maxValue == 0
                                ? 0
                                : (values[i] / maxValue)
                                    .clamp(values[i] > 0 ? 0.08 : 0, 1.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: i == highlightIndex
                                    ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [scheme.primary, scheme.tertiary],
                                      )
                                    : null,
                                color: i == highlightIndex
                                    ? null
                                    : scheme.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(chartLabels[i], style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Etiquetas L-D para una semana fija (útiles en calendario).
  static const weekLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  /// Genera etiquetas para los últimos N días (ej. últimos 7 días desde hoy).
  static List<String> lastDaysLabels(int count) {
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final now = DateTime.now();
    return List.generate(count, (i) {
      final day = now.subtract(Duration(days: count - 1 - i));
      return dayLabels[day.weekday - 1];
    });
  }
}
