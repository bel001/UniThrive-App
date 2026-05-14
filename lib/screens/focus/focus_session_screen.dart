import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_primary_button.dart';
import 'focus_timer_screen.dart';

class FocusSessionScreen extends StatefulWidget {
  final String taskLabel;

  const FocusSessionScreen({super.key, required this.taskLabel});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  late List<_PrepStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      const _PrepStep(
        title: 'Material preparado',
        subtitle: 'Ten abierto el documento, recurso o cuaderno correcto.',
      ),
      const _PrepStep(
        title: 'Distracciones silenciadas',
        subtitle: 'Quita ruido visual y baja notificaciones no esenciales.',
      ),
      const _PrepStep(
        title: 'Meta clara',
        subtitle: 'Define qué debe quedar listo al terminar esta sesión.',
      ),
    ];
  }

  bool get _readyToStart => _steps.every((step) => step.checked);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenHorizontal,
                12,
                DesignTokens.screenHorizontal,
                24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 8),
                    UniCard(
                      radius: 34,
                      color: scheme.primaryContainer.withValues(alpha: 0.72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopChip(
                            icon: Icons.self_improvement_rounded,
                            label: 'Modo enfoque',
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Prepara una sesión sólida antes de empezar.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Vamos a dedicar ${Constants.focusDuration.inMinutes} minutos a “${widget.taskLabel}”. Deja listo el contexto y arranca con intención.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _InfoPill(
                                icon: Icons.timer_outlined,
                                label:
                                    '${Constants.focusDuration.inMinutes} min de foco',
                              ),
                              const _InfoPill(
                                icon: Icons.flag_outlined,
                                label: '1 objetivo claro',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    UniCard(
                      radius: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checklist de activación',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pequeños pasos para entrar enfocado, no solo ocupado.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          ..._steps.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key == _steps.length - 1 ? 0 : 12,
                              ),
                              child: _FocusChecklistTile(
                                step: entry.value,
                                onChanged: (value) =>
                                    _toggleStep(entry.key, value ?? false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    IgnorePointer(
                      ignoring: !_readyToStart,
                      child: Opacity(
                        opacity: _readyToStart ? 1 : 0.45,
                        child: UniPrimaryButton(
                          label: 'Empezar sesión',
                          backgroundColor: scheme.primary,
                          icon: Icons.play_arrow_rounded,
                          onPressed: _launchFocusTimer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(
                          _readyToStart
                              ? 'Todavía no, vuelvo luego'
                              : 'Completa los pasos para activarla',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleStep(int index, bool checked) {
    setState(() {
      _steps[index] = _steps[index].copyWith(checked: checked);
    });
  }

  void _launchFocusTimer() {
    Navigator.of(context).pushReplacement(
      SoftPageRoute(
        builder: (_) => FocusTimerScreen(focusLabel: widget.taskLabel),
      ),
    );
  }
}

class _FocusChecklistTile extends StatelessWidget {
  const _FocusChecklistTile({required this.step, required this.onChanged});

  final _PrepStep step;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.05,
            child: Checkbox(
              value: step.checked,
              onChanged: onChanged,
              activeColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(step.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepStep {
  final String title;
  final String subtitle;
  final bool checked;

  const _PrepStep({
    required this.title,
    required this.subtitle,
    this.checked = false,
  });

  _PrepStep copyWith({bool? checked}) => _PrepStep(
    title: title,
    subtitle: subtitle,
    checked: checked ?? this.checked,
  );
}
