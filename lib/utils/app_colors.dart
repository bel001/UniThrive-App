import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppColors {
  // Get theme-aware colors
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
  }

  static Color getShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);
  }

  // Duolingo colors (theme-independent)
  static const Color duolingoGreen = UniThriveTheme.duolingoGreen;
  static const Color duolingoGold = UniThriveTheme.duolingoGold;
  static const Color duolingoOrange = UniThriveTheme.duolingoOrange;
  static const Color duolingoBlue = UniThriveTheme.duolingoBlue;
  static const Color primary = UniThriveTheme.primary;

  // Adaptive gradients
  static List<Color> getPurpleGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [const Color(0xFF9FCFBB), const Color(0xFF7FB5A0)]
        : [const Color(0xFF9FCFBB), const Color(0xFFB8E0D0)];
  }

  static List<Color> getGreenGradient(BuildContext context) {
    return [duolingoGreen, const Color(0xFF89E219)];
  }

  static List<Color> getGoldGradient(BuildContext context) {
    return [duolingoGold, const Color(0xFFFFA500)];
  }

  // State colors
  static Color getSuccessColor(BuildContext context) {
    return duolingoGreen;
  }

  static Color getWarningColor(BuildContext context) {
    return duolingoOrange;
  }

  static Color getInfoColor(BuildContext context) {
    return duolingoBlue;
  }

  // Surface variations
  static Color getSurfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  static Color getDisabledColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);
  }
}
