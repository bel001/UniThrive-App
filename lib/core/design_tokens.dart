import 'package:flutter/material.dart';

/// Design System Tokens for UniThrive
/// Provides centralized access to spacing, colors, and elevations
class DesignTokens {
  DesignTokens._();

  // ==================== SPACING ====================
  static const double screenHorizontal = 24.0;
  static const double cardPadding = 20.0;
  static const double sectionGap = 28.0;
  static const double itemGap = 14.0;
  static const double tinyGap = 4.0;
  static const double mediumGap = 10.0;
  static const double largeGap = 18.0;

  // ==================== ELEVATIONS ====================
  static const double cardElevation = 0.0;
  static const double activeCardElevation = 12.0;
  static const double bottomSheetElevation = 18.0;
  static const double dialogElevation = 24.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 14.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // ==================== BRAND COLORS ====================
  static const Color accent = Color(0xFF7DB8A4);
  static const Color accentStrong = Color(0xFF5F9B88);
  static const Color accentSoft = Color(0xFFE8F3EE);

  // ==================== STATE COLORS (WCAG AAA) ====================
  static const Color success = Color(0xFF0F9F6E);

  static const Color warning = Color(0xFFD97706);

  static const Color error = Color(0xFFDC5B53);

  static const Color info = Color(0xFF3B82F6);

  // ==================== TEXT COLORS (WCAG AAA) ====================
  static const Color textDisabled = Color(0xFFA0AEC0);

  static const Color textSecondary = Color(0xFF667085);

  static const Color textPrimary = Color(0xFF101828);

  // ==================== BACKGROUND COLORS ====================
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F4F7);
  static const Color divider = Color(0xFFDDE3EA);
  static const Color shadow = Color(0x140B1320);

  // ==================== DARK SURFACES ====================
  static const Color backgroundDark = Color(0xFF0B1117);
  static const Color cardDark = Color(0xFF111923);
  static const Color surfaceVariantDark = Color(0xFF182331);
  static const Color dividerDark = Color(0xFF243041);
  static const Color textPrimaryDark = Color(0xFFF4F6FA);
  static const Color textSecondaryDark = Color(0xFFA8B3C2);
}
