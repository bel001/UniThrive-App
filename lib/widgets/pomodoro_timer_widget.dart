import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pomodoro_session.dart';
import '../core/design_tokens.dart';
import '../state/app_state.dart';

class PomodoroTimerWidget extends StatefulWidget {
  final String taskId;
  final Function(PomodoroSession) onSessionComplete;

  const PomodoroTimerWidget({
    super.key,
    required this.taskId,
    required this.onSessionComplete,
  });

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  DateTime? _sessionStartTime;
  SettingsState? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppStateProvider.of(context).settings;
    if (_settings != settings) {
      _settings = settings;
      if (!_isRunning) {
        _totalSeconds = settings.focusDuration.inSeconds;
        _remainingSeconds = _totalSeconds;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-start timer disabled for debugging ANR
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _startTimer();
    // });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    if (!mounted) return;
    setState(() {
      _isRunning = true;
      _sessionStartTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _remainingSeconds = _totalSeconds;
        _isRunning = false;
        _sessionStartTime = null;
      });
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();
    final settings = _settings;
    if (settings?.pomodoroEndSound ?? true) {
      SystemSound.play(SystemSoundType.alert);
    }

    // Save session
    if (_sessionStartTime != null && !_isBreak) {
      final session = PomodoroSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        plannedDurationMinutes: _totalSeconds ~/ 60,
        actualDurationMinutes: (_totalSeconds - _remainingSeconds) ~/ 60,
        wasCompleted: _remainingSeconds == 0,
        isBreak: _isBreak,
      );
      widget.onSessionComplete(session);
    }

    if (mounted) {
      if (!_isBreak) {
        _completedPomodoros++;
        setState(() {
          _isBreak = true;
          // Long break every 4 pomodoros
          _totalSeconds =
              settings?.breakDuration.inSeconds ?? 5 * 60;
          _remainingSeconds = _totalSeconds;
          _isRunning = false;
        });

        // Show completion dialog
        _showCompletionDialog();
      } else {
        setState(() {
          _isBreak = false;
          _totalSeconds =
              settings?.focusDuration.inSeconds ?? 25 * 60;
          _remainingSeconds = _totalSeconds;
          _isRunning = false;
        });
      }
    }
  }

  void _skipSession() {
    if (_isBreak) {
      if (mounted) {
        setState(() {
          _isBreak = false;
          _totalSeconds = 25 * 60;
          _remainingSeconds = _totalSeconds;
          _isRunning = false;
        });
      }
    } else {
      _onTimerComplete();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Pomodoro Completado! 🎉'),
        content: Text(
          _completedPomodoros % 4 == 0
              ? '¡Has completado 4 sesiones! Toma un descanso largo de 15 minutos.'
              : '¡Buen trabajo! Toma un descanso de 5 minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer(); // Auto-start break
            },
            child: const Text('Iniciar descanso'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isBreak ? 'Descanso' : 'Pomodoro',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$_completedPomodoros/4',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Circular Timer
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    color: _isBreak
                        ? DesignTokens.info
                        : DesignTokens.adaptiveMint(context),
                  ),
                ),
                // Time text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 48,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _isBreak ? 'Descansa' : 'Enfócate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning) ...[
                // Start button
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.adaptiveMint(context),
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF002114)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ] else ...[
                // Pause button
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              // Skip button
              OutlinedButton.icon(
                onPressed: _skipSession,
                icon: const Icon(Icons.skip_next),
                label: Text(_isBreak ? 'Saltar descanso' : 'Saltar'),
              ),
              const SizedBox(width: 8),
              // Reset button
              IconButton(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reiniciar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
