import 'package:flutter/material.dart';

/// Design System Tokens for UniThrive — lenguaje "Vivid Academic".
/// Oscuro = Vivid Academic Night · Claro = adaptación Vivid Academic.
/// Los nombres legacy se conservan para no romper usos existentes.
class DesignTokens {
  DesignTokens._();

  // ==================== SPACING ====================
  static const double screenHorizontal = 20.0;
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

  // ==================== BORDER RADIUS (chunky) ====================
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusHero = 28.0;

  // ==================== CHUNKY / PRESSABLE ====================
  /// Grosor del borde inferior 3D de botones "presionables".
  static const double pressableDepth = 4.0;

  // ==================== SHADOWS (única) ====================
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
      ];
  static List<BoxShadow> cardShadowDark(double alpha) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: alpha),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];

  // ==================== BRAND COLORS (Vivid Academic) ====================
  /// Índigo real principal (botones, acciones).
  static const Color accent = Color(0xFF4F46E5);
  static const Color accentStrong = Color(0xFF3525CD);
  static const Color accentSoft = Color(0xFFE2DFFF);

  /// Índigo profundo para el borde inferior 3D ("chunky").
  static const Color accentDeep = Color(0xFF2A2090);

  /// Variante vibrante para fondos oscuros.
  static const Color accentVivid = Color(0xFF6366F1);

  /// Lila para titulares/énfasis sobre oscuro.
  static const Color lilac = Color(0xFFC3C0FF);
  static const Color lilacDeep = Color(0xFF1A00B2);

  /// Menta de logro/progreso.
  static const Color mint = Color(0xFF49FFBD);
  static const Color mintStrong = Color(0xFF08E1A2);
  static const Color mintGlow = Color(0xFF4ADE80);

  /// Menta adaptativa al brillo: intensa sobre oscuro, sobria sobre claro.
  static Color adaptiveMint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? mintStrong : success;
  }

  /// Coral de la mascota (ánimo preocupado).
  static const Color mascotCoral = Color(0xFFFF6B6B);

  /// Rosa de prioridad alta (vivid, legible en ambos brillos).
  static const Color priorityPink = Color(0xFFFF70A6);

  // ==================== STATE COLORS ====================
  static const Color success = Color(0xFF15803D);

  static const Color warning = Color(0xFFB45309);

  static const Color error = Color(0xFFC0392B);

  static const Color info = Color(0xFF3B82F6);

  // Dark variants (del sistema night)
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color warningDark = Color(0xFFFFB783);

  // ==================== TEXT COLORS ====================
  static const Color textDisabled = Color(0xFFA0AEC0);

  static const Color textSecondary = Color(0xFF464555);

  static const Color textPrimary = Color(0xFF191C1D);

  // ==================== BACKGROUND COLORS ====================
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDEEEF);
  static const Color divider = Color(0xFFE0E7FF);
  static const Color shadow = Color(0x140B1320);

  // ==================== DARK SURFACES (Vivid Academic Night) ====================
  static const Color backgroundDark = Color(0xFF0F0F16);
  static const Color cardDark = Color(0xFF1C1C28);
  static const Color cardDarkAlt = Color(0xFF242842);
  static const Color surfaceVariantDark = Color(0xFF2A2C38);
  static const Color dividerDark = Color(0xFF55556A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  /// Fondo de inputs oscuros.
  static const Color surfaceLowestDark = Color(0xFF0B0B10);
}
