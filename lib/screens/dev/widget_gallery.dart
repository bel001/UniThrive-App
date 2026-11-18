import 'package:flutter/material.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_primary_button.dart';
import '../../widgets/uni_supervisual.dart';

/// Galería interna para QA visual — no expuesta en navegación producción.
/// Muestra todos los tokens y widgets del Design System en un solo scroll.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Galería UI — QA')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text('Tokens', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TokenChip(label: 'radiusSmall 14', color: theme.colorScheme.primaryContainer),
              _TokenChip(label: 'radiusMedium 18', color: theme.colorScheme.secondaryContainer),
              _TokenChip(label: 'radiusLarge 24', color: theme.colorScheme.tertiaryContainer),
              _TokenChip(label: 'radiusXLarge 32', color: theme.colorScheme.surfaceContainerHighest),
              _TokenChip(label: 'radiusHero 28', color: theme.colorScheme.surfaceContainerHigh),
            ],
          ),
          const SizedBox(height: 28),
          Text('UniCard', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          UniCard(child: Text('UniCard estándar — borde outlineVariant 1px, sombra DesignTokens.cardShadow', style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 12),
          UniCard(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6), child: Text('Variante primaryContainer', style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 28),
          Text('UniRingProgress', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              UniRingProgress(progress: 0.25, size: 90, center: Text('25%', style: theme.textTheme.titleSmall)),
              UniRingProgress(progress: 0.68, size: 110, center: Text('68%', style: theme.textTheme.titleMedium)),
              UniRingProgress(progress: 1.0, size: 130, center: const Icon(Icons.check_rounded)),
            ],
          ),
          const SizedBox(height: 28),
          Text('UniGradientMetricCard', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: UniGradientMetricCard(icon: Icons.local_fire_department_rounded, value: '12', label: 'días racha', gradient: UniGradientMetricCard.fireGradient)),
              SizedBox(width: 12),
              Expanded(child: UniGradientMetricCard(icon: Icons.bolt_rounded, value: '4h', label: 'enfoque', gradient: UniGradientMetricCard.greenGradient, progress: 0.6)),
            ],
          ),
          const SizedBox(height: 28),
          Text('UniMiniBarChart', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          UniCard(child: UniMiniBarChart(values: const [2, 4, 1, 5, 3, 0, 6], labels: UniMiniBarChart.lastDaysLabels(7), semanticUnit: 'tareas')),
          const SizedBox(height: 28),
          Text('Botones', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          UniPrimaryButton(label: 'Primario', icon: Icons.add_rounded, onPressed: () {}),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () {}, child: const Text('Secundario outline')),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.auto_graph_rounded), label: const Text('Tonal')),
          const SizedBox(height: 28),
          Text('Motion', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('PageTransition: Cupertino 220ms easeOutCubic — AnimatedSwitcher 220ms — AnimatedScale 150ms en UniCard onTap', style: theme.textTheme.bodySmall),
          const SizedBox(height: 28),
          Text('Accesibilidad', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('Semantics en anillos y métricas, textScale 1.0–1.3 sin overflow, contraste AA (success #0E7A53)', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
