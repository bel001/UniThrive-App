import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../state/app_state.dart';
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
    final isFocus = _phase == _TimerPhase.focus;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = isFocus ? 'Enfoque' : 'Descanso';
    final bgColor = isDark
        ? const Color(0xFF050714)
        : (isFocus ? const Color(0xFFF6F4FF) : const Color(0xFFE6F6F0));
    final panelColor = isDark ? const Color(0xFF11142A) : Colors.white;
    final accent = isFocus
        ? (isDark ? const Color(0xFFB8A9FF) : const Color(0xFF6C4DFF))
        : (isDark ? const Color(0xFF7CE0A0) : const Color(0xFF16A34A));
    final secondaryText = isDark
        ? Colors.white70
        : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        title: Text(title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          if (isFocus)
            Text(
              'Enfoque: ${widget.focusLabel}',
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Buen trabajo, tómate un descanso consciente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildTimerRing(
            isFocus: isFocus,
            isDark: isDark,
            accent: accent,
            panelColor: panelColor,
            secondary: secondaryText,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: UniPrimaryButton(
              label: _isRunning ? 'Pausar' : 'Reanudar',
              backgroundColor: accent,
              onPressed: _toggleTimer,
            ),
          ),
          TextButton(
            onPressed: _finishSession,
            child: Text(
              'Finalizar sesión',
              style: TextStyle(color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRing({
    required bool isFocus,
    required bool isDark,
    required Color accent,
    required Color panelColor,
    required Color secondary,
  }) {
    final progress = 1 - (_remaining.inSeconds / _total.inSeconds);
    final trackColor = isFocus
        ? (isDark ? const Color(0xFF2D2750) : const Color(0xFFDCD5FF))
        : (isDark ? const Color(0xFF1B3B2A) : const Color(0xFFCDEEDB));
    final timeColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(36),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
      ),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 220,
              width: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFocus ? 'Tiempo restante' : 'Descanso activo',
                  style: TextStyle(
                    color: secondary,
                    fontWeight: FontWeight.w600,
                  ),
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
    _total = phase == _TimerPhase.focus ? Constants.focusDuration : Constants.breakDuration;
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
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = _remaining.inHours;
    final prefix = hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : '';
    return '$prefix$minutes:$seconds';
  }
}
