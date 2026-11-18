import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
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
  static const Color duolingoGreen = DesignTokens.success;
  static const Color duolingoGold = DesignTokens.warning;
  static const Color duolingoOrange = DesignTokens.warning;
  static const Color duolingoBlue = DesignTokens.info;
  static const Color primary = UniThriveTheme.primary;

  // Adaptive gradients
  static List<Color> getPurpleGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [DesignTokens.lilac, DesignTokens.accentVivid]
        : [DesignTokens.lilac, DesignTokens.accent];
  }

  static List<Color> getGreenGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [DesignTokens.mint, DesignTokens.mintStrong]
        : [DesignTokens.mintStrong, DesignTokens.success];
  }

  static List<Color> getGoldGradient(BuildContext context) {
    return [DesignTokens.warningDark, DesignTokens.warning];
  }

  // State colors
  static Color getSuccessColor(BuildContext context) {
    return DesignTokens.success;
  }

  static Color getWarningColor(BuildContext context) {
    return DesignTokens.warning;
  }

  static Color getInfoColor(BuildContext context) {
    return DesignTokens.info;
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
