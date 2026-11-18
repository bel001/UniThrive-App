import 'dart:math';
import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

class CelebrationAnimation extends StatefulWidget {
  final Widget child;
  final bool show;

  const CelebrationAnimation({
    super.key,
    required this.child,
    this.show = false,
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Confetti> _confettiPieces = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.show) {
      _initConfetti();
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _confettiPieces.clear();
      }
    });
  }

  @override
  void didUpdateWidget(CelebrationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _initConfetti();
      _controller.forward(from: 0);
    }
  }

  void _initConfetti() {
    final random = Random();
    _confettiPieces.clear();
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(
        _Confetti(
          x: random.nextDouble(),
          y: -0.1,
          color: _randomColor(random),
          rotation: random.nextDouble() * 2 * pi,
          velocity: 0.5 + random.nextDouble() * 0.5,
          swing: random.nextDouble() * 0.5 - 0.25,
        ),
      );
    }
  }

  Color _randomColor(Random random) {
    final colors = [
      const Color(0xFFFFB300),
      const Color(0xFFFF6B6B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFFEB3B),
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      confetti: _confettiPieces,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Confetti {
  final double x;
  final double y;
  final Color color;
  final double rotation;
  final double velocity;
  final double swing;

  _Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.rotation,
    required this.velocity,
    required this.swing,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;

      final y = piece.y + (progress * piece.velocity * 1.2);
      if (y > 1.1) continue;

      final x = piece.x + (sin(progress * 4 * pi) * piece.swing * 0.2);
      final rotation = piece.rotation + (progress * 4 * pi);

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: 10, height: 6);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

void showCelebrationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? emoji,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _CelebrationDialog(title: title, message: message, emoji: emoji),
  );
}

class _CelebrationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? emoji;

  const _CelebrationDialog({
    required this.title,
    required this.message,
    this.emoji,
  });

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationAnimation(
      show: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.emoji != null)
                Text(widget.emoji!, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.adaptiveMint(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '¡Genial!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
