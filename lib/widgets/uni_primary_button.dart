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
    this.backgroundColor = const Color(0xFF7DB8A4),
    this.foregroundColor = const Color(0xFF101828),
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor,
              Color.lerp(backgroundColor, Colors.black, 0.1) ?? backgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
            child: DefaultTextStyle(
              style: theme.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                  ) ??
                  TextStyle(color: foregroundColor),
              child: IconTheme(
                data: IconThemeData(color: foregroundColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
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
