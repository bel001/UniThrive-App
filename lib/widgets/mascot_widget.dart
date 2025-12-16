import 'package:flutter/material.dart';
import '../models/mascot_state.dart';

class MascotWidget extends StatefulWidget {
  final MascotState state;
  final double size;
  final bool showMessage;

  const MascotWidget({
    super.key,
    required this.state,
    this.size = 120,
    this.showMessage = true,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void didUpdateWidget(MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.mood != widget.state.mood) {
      // Trigger bounce animation on mood change
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getMascotAssetPath() {
    switch (widget.state.mood) {
      case MascotMood.happy:
        return 'assets/mascot/mascot_happy.png';
      case MascotMood.excited:
        return 'assets/mascot/mascot_excited.png';
      case MascotMood.encouraging:
        return 'assets/mascot/mascot_encouraging.png';
      case MascotMood.celebrating:
        return 'assets/mascot/mascot_celebrating.png';
      case MascotMood.thinking:
        return 'assets/mascot/mascot_happy.png'; // fallback
      case MascotMood.sleeping:
        return 'assets/mascot/mascot_happy.png'; // fallback
      case MascotMood.sad:
        return 'assets/mascot/mascot_encouraging.png'; // fallback
      case MascotMood.worried:
        return 'assets/mascot/mascot_encouraging.png'; // fallback
    }
  }

  Color _getMoodColor() {
    switch (widget.state.mood) {
      case MascotMood.happy:
      case MascotMood.excited:
        return const Color(0xFF9FCFBB);
      case MascotMood.encouraging:
        return const Color(0xFF4CAF50);
      case MascotMood.celebrating:
        return const Color(0xFFFFB300);
      case MascotMood.thinking:
        return const Color(0xFF2196F3);
      case MascotMood.sleeping:
        return const Color(0xFF9E9E9E);
      case MascotMood.sad:
        return const Color(0xFF607D8B);
      case MascotMood.worried:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getMoodColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                _getMascotAssetPath(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to emoji if image fails to load
                  return Center(
                    child: Text(
                      '🦉',
                      style: TextStyle(fontSize: widget.size * 0.6),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.showMessage && widget.state.message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getMoodColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getMoodColor().withValues(alpha: 0.3),
                width: 2,
              ),
            ),
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
      ],
    );
  }
}

class MascotAvatar extends StatelessWidget {
  final MascotMood mood;
  final double size;

  const MascotAvatar({super.key, this.mood = MascotMood.happy, this.size = 40});

  String _getAssetPath() {
    switch (mood) {
      case MascotMood.happy:
        return 'assets/mascot/mascot_happy.png';
      case MascotMood.excited:
        return 'assets/mascot/mascot_excited.png';
      case MascotMood.encouraging:
        return 'assets/mascot/mascot_encouraging.png';
      case MascotMood.celebrating:
        return 'assets/mascot/mascot_celebrating.png';
      default:
        return 'assets/mascot/mascot_happy.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset(
          _getAssetPath(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text('🦉', style: TextStyle(fontSize: size * 0.6)),
            );
          },
        ),
      ),
    );
  }
}
