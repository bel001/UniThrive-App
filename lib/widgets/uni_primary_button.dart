import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Botón principal estilo "Vivid Academic": sólido con borde inferior 3D
/// de 4px que simula un botón físico presionable.
class UniPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? deepColor;
  final IconData? icon;
  final bool expand;

  const UniPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.deepColor,
    this.icon,
    this.expand = true,
  });

  @override
  State<UniPrimaryButton> createState() => _UniPrimaryButtonState();
}

class _UniPrimaryButtonState extends State<UniPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    final fg = widget.foregroundColor ?? Colors.white;
    final deep =
        widget.deepColor ??
        (isDark ? DesignTokens.accentDeep : DesignTokens.accentDeep);
    final radius = BorderRadius.circular(DesignTokens.radiusLarge);

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      decoration: BoxDecoration(color: deep, borderRadius: radius),
      padding: EdgeInsets.only(bottom: _pressed ? 0 : DesignTokens.pressableDepth),
      child: Material(
        color: bg,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 22,
            ),
            child: DefaultTextStyle(
              style:
                  theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ) ??
                  TextStyle(color: fg),
              textAlign: TextAlign.center,
              child: IconTheme(
                data: IconThemeData(color: fg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon!, size: 22),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.expand) return button;

    // Only stretch to the available width when the parent has a bounded width.
    // This avoids throwing BoxConstraints errors when the button is placed in
    // unconstrained layouts (e.g. inside overlays or intrinsic measurements).
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return button;
        return SizedBox(width: constraints.maxWidth, child: button);
      },
    );
  }
}
