import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class UniCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  const UniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.margin = EdgeInsets.zero,
    this.radius = 28,
    this.onTap,
  });

  @override
  State<UniCard> createState() => _UniCardState();
}

class _UniCardState extends State<UniCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    HapticFeedback.lightImpact();
    widget.onTap!();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (widget.onTap == null) {
      return card;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: card,
      ),
    );
  }
}
