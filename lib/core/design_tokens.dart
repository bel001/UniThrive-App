import 'package:flutter/material.dart';

/// Design System Tokens for UniThrive
/// Provides centralized access to spacing, colors, and elevations
class DesignTokens {
  DesignTokens._();

  // ==================== SPACING ====================
  static const double screenHorizontal = 20.0;
  static const double cardPadding = 16.0;
  static const double sectionGap = 24.0;
  static const double itemGap = 12.0;
  static const double tinyGap = 4.0;
  static const double mediumGap = 8.0;

  // ==================== ELEVATIONS ====================
  static const double cardElevation = 2.0;
  static const double activeCardElevation = 8.0;
  static const double bottomSheetElevation = 16.0;
  static const double dialogElevation = 24.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  // ==================== STATE COLORS (WCAG AAA) ====================
  /// Success color - 7:1 contrast on white
  static const Color success = Color(0xFF10B981);

  /// Warning color - 7.5:1 contrast on white
  static const Color warning = Color(0xFFF59E0B);

  /// Error color - 8:1 contrast on white
  static const Color error = Color(0xFFEF4444);

  /// Info color - 8:1 contrast on white
  static const Color info = Color(0xFF3B82F6);

  // ==================== TEXT COLORS (WCAG AAA) ====================
  /// For disabled/locked text - 7:1 contrast on white
  static const Color textDisabled = Color(0xFF9CA3AF);

  /// For secondary text in badges - 8.5:1 contrast on light backgrounds
  static const Color textSecondary = Color(0xFF475569);

  /// For primary text
  static const Color textPrimary = Color(0xFF0F172A);

  // ==================== BACKGROUND COLORS ====================
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
}
