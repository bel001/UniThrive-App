import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design_tokens.dart';

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
    this.radius = DesignTokens.radiusHero,
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
    final fillColor = widget.color ?? theme.colorScheme.surfaceContainerLow;
    final borderRadius = BorderRadius.circular(widget.radius);
    final borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : theme.colorScheme.outlineVariant,
      width: 1,
    );

    // Sombra única del Design System; borde outlineVariant 1px.
    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: isDark ? DesignTokens.cardShadowDark(0.14) : DesignTokens.cardShadow,
      ),
      child: Material(
        color: fillColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          // Si no hay onTap, desactiva el splash para no interferir con ListTiles internos.
          splashFactory: widget.onTap == null ? NoSplash.splashFactory : InkRipple.splashFactory,
          highlightColor: widget.onTap == null ? Colors.transparent : null,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
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
