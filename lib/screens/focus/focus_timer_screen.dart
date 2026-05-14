import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_primary_button.dart';

class FocusTimerScreen extends StatefulWidget {
  final String focusLabel;

  const FocusTimerScreen({super.key, required this.focusLabel});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

enum _TimerPhase { focus, breakTime }

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late Duration _remaining;
  late Duration _total;
  _TimerPhase _phase = _TimerPhase.focus;
  Timer? _ticker;
  bool _isRunning = true;
  bool _sessionStarted = false;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    _startPhase(_TimerPhase.focus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState ??= AppStateProvider.of(context);
    if (!_sessionStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _sessionStarted) return;
        _appState!.startFocusSession(label: widget.focusLabel);
        _sessionStarted = true;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_appState?.currentFocusSession?.isActive ?? false) {
      _appState!.stopFocusSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocus = _phase == _TimerPhase.focus;
    final phaseColor = isFocus
        ? theme.colorScheme.primary
        : DesignTokens.success;
    final phaseBackground = isFocus
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.72)
        : const Color(0xFFDDF3E8);

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
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 8),
                    UniCard(
                      radius: 34,
                      color: phaseBackground,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PhasePill(
                            icon: isFocus
                                ? Icons.bolt_rounded
                                : Icons.spa_rounded,
                            label: isFocus ? 'Enfoque activo' : 'Descanso',
                            color: phaseColor,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            isFocus
                                ? 'Sostén la atención sin ruido alrededor.'
                                : 'Respira, baja el ritmo y prepara el siguiente bloque.',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isFocus
                                ? 'Estás trabajando en “${widget.focusLabel}”. Mantén esta sesión limpia y continua.'
                                : 'Tu foco ya hizo trabajo. Usa este momento para soltar tensión y volver mejor.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    UniCard(
                      radius: 34,
                      child: Column(
                        children: [
                          _buildTimerRing(phaseColor: phaseColor),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final stacked = innerConstraints.maxWidth < 340;
                              final stats = [
                                _SessionStat(
                                  label: 'Fase',
                                  value: isFocus ? 'Enfoque' : 'Descanso',
                                ),
                                _SessionStat(
                                  label: 'Duración',
                                  value: _formatDuration(_total),
                                ),
                              ];

                              if (stacked) {
                                return Column(
                                  children: [
                                    for (var i = 0; i < stats.length; i++) ...[
                                      stats[i],
                                      if (i != stats.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: stats[0]),
                                  const SizedBox(width: 10),
                                  Expanded(child: stats[1]),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    UniPrimaryButton(
                      label: _isRunning ? 'Pausar sesión' : 'Reanudar sesión',
                      backgroundColor: phaseColor,
                      icon: _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: _toggleTimer,
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _finishSession,
                        child: const Text('Finalizar sesión'),
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

  Widget _buildTimerRing({required Color phaseColor}) {
    final theme = Theme.of(context);
    final progress = 1 - (_remaining.inSeconds / _total.inSeconds);
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = (screenWidth - 132).clamp(170.0, 240.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SizedBox(
        height: ringSize,
        width: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: ringSize,
              width: ringSize,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(phaseColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formattedTime,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 42),
                ),
                const SizedBox(height: 8),
                Text(
                  _phase == _TimerPhase.focus
                      ? 'Tiempo restante'
                      : 'Pausa consciente',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startPhase(_TimerPhase phase) {
    _phase = phase;
    _total = phase == _TimerPhase.focus
        ? Constants.focusDuration
        : Constants.breakDuration;
    _remaining = _total;
    _restartTicker();
    setState(() {});
  }

  void _restartTicker() {
    _ticker?.cancel();
    if (!_isRunning) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds == 0) {
        timer.cancel();
        if (_phase == _TimerPhase.focus) {
          _startPhase(_TimerPhase.breakTime);
        } else {
          _finishSession();
        }
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _restartTicker();
      } else {
        _ticker?.cancel();
      }
    });
  }

  void _finishSession() {
    _appState?.stopFocusSession();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _formattedTime {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final hours = _remaining.inHours;
    final prefix = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    return '$prefix$minutes:$seconds';
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
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

class _SessionStat extends StatelessWidget {
  const _SessionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 60) {
    return '$totalMinutes min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) {
    return '$hours h';
  }
  return '$hours h $minutes min';
}
