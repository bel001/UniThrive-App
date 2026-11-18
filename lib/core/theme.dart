import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

class UniThriveTheme {
  UniThriveTheme._();

  // Legacy alias kept to avoid breaking older utility code.
  static const Color primary = DesignTokens.accent;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme : _lightScheme;
    final textTheme = _textTheme(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Lexend',
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      dividerColor: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: scheme.surface,
        barBackgroundColor: scheme.surface.withValues(alpha: 0.86),
        textTheme: CupertinoTextThemeData(
          primaryColor: scheme.primary,
          navTitleTextStyle: textTheme.titleLarge,
          textStyle: textTheme.bodyMedium,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? DesignTokens.cardDark : DesignTokens.cardBackground,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : DesignTokens.divider,
            width: isDark ? 1 : 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? DesignTokens.surfaceLowestDark
            : DesignTokens.backgroundLight,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? DesignTokens.cardDarkAlt
            : DesignTokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: BorderSide(
            color: isDark
                ? DesignTokens.dividerDark
                : DesignTokens.divider,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? DesignTokens.cardDarkAlt
            : DesignTokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXLarge),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
        thickness: 0.8,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? DesignTokens.cardDarkAlt
            : const Color(0xFF1E293B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        contentPadding: EdgeInsets.zero,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.secondary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      chipTheme: scheme.brightness == Brightness.dark
          ? ChipThemeData(
              backgroundColor: DesignTokens.cardDark,
              selectedColor: scheme.primary.withValues(alpha: 0.20),
              labelStyle: textTheme.labelMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: DesignTokens.dividerDark),
              ),
            )
          : ChipThemeData(
              backgroundColor: Colors.white,
              selectedColor: DesignTokens.accentSoft,
              labelStyle: textTheme.labelMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: DesignTokens.divider),
              ),
            ),
    );
  }

  /// Tipografía Lexend del sistema Vivid Academic.
  static TextTheme _textTheme(bool isDark) {
    const family = 'Lexend';
    final primary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimary;
    final secondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondary;

    TextStyle style({
      required double size,
      required double height,
      required FontWeight weight,
      Color? color,
      double? letterSpacing,
    }) =>
        TextStyle(
          fontFamily: family,
          fontSize: size,
          height: height,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          color: color ?? primary,
        );

    return TextTheme(
      displayLarge: style(
        size: 48,
        height: 56 / 48,
        weight: FontWeight.w700,
        letterSpacing: -0.96,
      ),
      displayMedium: style(
        size: 34,
        height: 1.05,
        weight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineLarge: style(
        size: 32,
        height: 40 / 32,
        weight: FontWeight.w600,
        letterSpacing: -0.32,
      ),
      headlineMedium: style(
        size: 28,
        height: 36 / 28,
        weight: FontWeight.w600,
      ),
      headlineSmall: style(
        size: 24,
        height: 1.15,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: style(size: 21, height: 1.2, weight: FontWeight.w700),
      titleMedium: style(
        size: 20,
        height: 28 / 20,
        weight: FontWeight.w600,
      ),
      titleSmall: style(size: 15, height: 1.3, weight: FontWeight.w600),
      bodyLarge: style(size: 18, height: 28 / 18, weight: FontWeight.w400),
      bodyMedium: style(
        size: 16,
        height: 24 / 16,
        weight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: style(
        size: 12,
        height: 1.35,
        weight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: style(
        size: 15,
        height: 1.3,
        weight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      labelMedium: style(
        size: 14,
        height: 20 / 14,
        weight: FontWeight.w600,
        letterSpacing: 0.28,
        color: secondary,
      ),
      labelSmall: style(
        size: 12,
        height: 16 / 12,
        weight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: DesignTokens.accentStrong,
    onPrimary: Colors.white,
    primaryContainer: DesignTokens.accent,
    onPrimaryContainer: Color(0xFFDAD7FF),
    secondary: Color(0xFF006C4C),
    onSecondary: Colors.white,
    secondaryContainer: DesignTokens.mint,
    onSecondaryContainer: Color(0xFF007351),
    tertiary: Color(0xFF434851),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFDEE2ED),
    onTertiaryContainer: Color(0xFF171C23),
    error: DesignTokens.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: DesignTokens.backgroundLight,
    onSurface: DesignTokens.textPrimary,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF3F4F5),
    surfaceContainerHigh: DesignTokens.surfaceVariant,
    surfaceContainerHighest: Color(0xFFE1E3E4),
    onSurfaceVariant: DesignTokens.textSecondary,
    outline: DesignTokens.divider,
    outlineVariant: Color(0xFFC7C4D8),
    shadow: DesignTokens.shadow,
    scrim: Color(0x33000000),
    inverseSurface: Color(0xFF2E3132),
    onInverseSurface: Color(0xFFF0F1F2),
    inversePrimary: DesignTokens.lilac,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: DesignTokens.accentVivid,
    onPrimary: Colors.white,
    primaryContainer: DesignTokens.accent,
    onPrimaryContainer: Color(0xFFDAD7FF),
    secondary: DesignTokens.mint,
    onSecondary: Color(0xFF002114),
    secondaryContainer: Color(0xFF00A572),
    onSecondaryContainer: Color(0xFF00311F),
    tertiary: DesignTokens.warningDark,
    onTertiary: Color(0xFF4F2500),
    tertiaryContainer: Color(0xFFD97721),
    onTertiaryContainer: Color(0xFFFFDCC5),
    error: DesignTokens.errorDark,
    onError: Color(0xFF690005),
    errorContainer: DesignTokens.errorContainerDark,
    onErrorContainer: Color(0xFFFFDAD6),
    surface: DesignTokens.backgroundDark,
    onSurface: DesignTokens.textPrimaryDark,
    surfaceContainerLowest: DesignTokens.surfaceLowestDark,
    surfaceContainerLow: DesignTokens.cardDark,
    surfaceContainer: DesignTokens.cardDarkAlt,
    surfaceContainerHigh: DesignTokens.surfaceVariantDark,
    surfaceContainerHighest: Color(0xFF34343D),
    onSurfaceVariant: DesignTokens.textSecondaryDark,
    outline: DesignTokens.dividerDark,
    outlineVariant: Color(0xFF464554),
    shadow: Colors.black,
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFFE4E1ED),
    onInverseSurface: Color(0xFF303038),
    inversePrimary: DesignTokens.accentStrong,
  );
}
