import 'package:flutter/material.dart';

class UniPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final bool expand;

  const UniPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF9FCFBB),
    this.foregroundColor = Colors.white,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon!, size: 20), const SizedBox(width: 8)],
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );

    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        textStyle: const TextStyle(letterSpacing: 0.2),
      ),
      onPressed: onPressed,
      child: child,
    );

    if (!expand) return button;

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
