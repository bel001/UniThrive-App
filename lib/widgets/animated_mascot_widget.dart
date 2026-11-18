import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/design_tokens.dart';
import '../models/mascot_state.dart';

/// Animated mascot with bounce, floating, and scale animations
class AnimatedMascotWidget extends StatefulWidget {
  final MascotState state;
  final double size;
  final bool showMessage;
  final bool enableFloating;

  const AnimatedMascotWidget({
    super.key,
    required this.state,
    this.size = 120,
    this.showMessage = true,
    this.enableFloating = true,
  });

  @override
  State<AnimatedMascotWidget> createState() => _AnimatedMascotWidgetState();
}

class _AnimatedMascotWidgetState extends State<AnimatedMascotWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation (on mood change)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Floating animation (continuous)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse animation (for celebrating mood)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController.forward();
    _updateAnimationsForMood();
  }

  @override
  void didUpdateWidget(AnimatedMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.mood != widget.state.mood) {
      _bounceController.reset();
      _bounceController.forward();
      _updateAnimationsForMood();
    }
  }

  void _updateAnimationsForMood() {
    if (widget.state.mood == MascotMood.celebrating ||
        widget.state.mood == MascotMood.excited) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getMascotEmoji() {
    switch (widget.state.mood) {
      case MascotMood.happy:
        return '🦉';
      case MascotMood.excited:
        return '🎉';
      case MascotMood.encouraging:
        return '💪';
      case MascotMood.celebrating:
        return '🏆';
      case MascotMood.thinking:
        return '🤔';
      case MascotMood.sleeping:
        return '😴';
      case MascotMood.sad:
        return '😢';
      case MascotMood.worried:
        return '😰';
    }
  }

  Color _getMoodColor() {
    switch (widget.state.mood) {
      case MascotMood.happy:
      case MascotMood.excited:
        return DesignTokens.mintStrong;
      case MascotMood.encouraging:
        return DesignTokens.success;
      case MascotMood.celebrating:
        return DesignTokens.warning;
      case MascotMood.thinking:
        return DesignTokens.info;
      case MascotMood.sleeping:
        return DesignTokens.textDisabled;
      case MascotMood.sad:
        return DesignTokens.dividerDark;
      case MascotMood.worried:
        return DesignTokens.mascotCoral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated mascot
        AnimatedBuilder(
          animation: Listenable.merge([
            _bounceController,
            _floatController,
            _pulseController,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: widget.enableFloating
                  ? Offset(0, _floatAnimation.value)
                  : Offset.zero,
              child: Transform.scale(
                scale:
                    _bounceAnimation.value *
                    (1.0 + _pulseAnimation.value * 0.1),
                child: Transform.rotate(
                  angle: widget.state.mood == MascotMood.celebrating
                      ? math.sin(_floatController.value * 2 * math.pi) * 0.1
                      : 0,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getMoodColor().withValues(alpha: 0.2),
                          _getMoodColor().withValues(alpha: 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow:
                          widget.state.mood == MascotMood.celebrating ||
                              widget.state.mood == MascotMood.excited
                          ? [
                              BoxShadow(
                                color: _getMoodColor().withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _getMascotEmoji(),
                        style: TextStyle(fontSize: widget.size * 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Message bubble
        if (widget.showMessage && widget.state.message.isNotEmpty) ...[
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Opacity(
                opacity: _bounceController.value,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _getMoodColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getMoodColor().withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getMessageIcon(), size: 18, color: _getMoodColor()),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getMoodColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  IconData _getMessageIcon() {
    switch (widget.state.mood) {
      case MascotMood.excited:
      case MascotMood.celebrating:
        return Icons.celebration;
      case MascotMood.encouraging:
        return Icons.psychology;
      case MascotMood.thinking:
        return Icons.lightbulb_outline;
      case MascotMood.worried:
        return Icons.warning_amber;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}
