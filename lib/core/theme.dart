import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';

class UniThriveTheme {
  UniThriveTheme._();

  // Legacy aliases kept to avoid breaking older utility code.
  static const Color primary = DesignTokens.accent;
  static const Color duolingoGreen = Color(0xFF58CC02);
  static const Color duolingoGold = Color(0xFFFFD700);
  static const Color duolingoOrange = Color(0xFFFF9900);
  static const Color duolingoBlue = Color(0xFF1CB0F6);

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
        color: scheme.surfaceContainerLow,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          side: BorderSide(
            color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: isDark
              ? DesignTokens.textPrimaryDark
              : DesignTokens.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.onSurface,
          side: BorderSide(
            color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.primary,
          foregroundColor: isDark
              ? DesignTokens.textPrimaryDark
              : DesignTokens.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: isDark
            ? DesignTokens.textPrimaryDark
            : DesignTokens.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
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
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.dividerDark : DesignTokens.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
            ? const Color(0xFF182331)
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
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final base = isDark ? Typography.whiteCupertino : Typography.blackCupertino;
    final primary = isDark
        ? DesignTokens.textPrimaryDark
        : DesignTokens.textPrimary;
    final secondary = isDark
        ? DesignTokens.textSecondaryDark
        : DesignTokens.textSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 34,
        height: 1.05,
        letterSpacing: -1.0,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.1,
        letterSpacing: -0.7,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 21,
        letterSpacing: -0.35,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 15,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.35,
        color: primary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: secondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        color: secondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: DesignTokens.accent,
    onPrimary: DesignTokens.textPrimary,
    primaryContainer: DesignTokens.accentSoft,
    onPrimaryContainer: DesignTokens.textPrimary,
    secondary: Color(0xFF0F766E),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE6F4F1),
    onSecondaryContainer: DesignTokens.textPrimary,
    tertiary: Color(0xFFE8A34D),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFF1DE),
    onTertiaryContainer: DesignTokens.textPrimary,
    error: DesignTokens.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE4E2),
    onErrorContainer: Color(0xFF7A271A),
    surface: DesignTokens.backgroundLight,
    onSurface: DesignTokens.textPrimary,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFAFBFC),
    surfaceContainerHigh: DesignTokens.surfaceVariant,
    surfaceContainerHighest: Color(0xFFE9EEF3),
    onSurfaceVariant: DesignTokens.textSecondary,
    outline: DesignTokens.divider,
    outlineVariant: Color(0xFFE7ECF1),
    shadow: DesignTokens.shadow,
    scrim: Color(0x33000000),
    inverseSurface: Color(0xFF111827),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFA7D6C7),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8BC7B1),
    onPrimary: Color(0xFF092016),
    primaryContainer: Color(0xFF16372D),
    onPrimaryContainer: Color(0xFFD9F2E8),
    secondary: Color(0xFF76D2C7),
    onSecondary: Color(0xFF072B2B),
    secondaryContainer: Color(0xFF123D3F),
    onSecondaryContainer: Color(0xFFD8F5F0),
    tertiary: Color(0xFFFFC47E),
    onTertiary: Color(0xFF3D2405),
    tertiaryContainer: Color(0xFF5C3B12),
    onTertiaryContainer: Color(0xFFFFE4BF),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF680003),
    errorContainer: Color(0xFF81252A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: DesignTokens.backgroundDark,
    onSurface: DesignTokens.textPrimaryDark,
    surfaceContainerLowest: Color(0xFF0F151E),
    surfaceContainerLow: DesignTokens.cardDark,
    surfaceContainer: Color(0xFF141D28),
    surfaceContainerHigh: DesignTokens.surfaceVariantDark,
    surfaceContainerHighest: Color(0xFF223041),
    onSurfaceVariant: DesignTokens.textSecondaryDark,
    outline: DesignTokens.dividerDark,
    outlineVariant: Color(0xFF1D2939),
    shadow: Colors.black,
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFFF2F4F7),
    onInverseSurface: Color(0xFF111827),
    inversePrimary: DesignTokens.accentStrong,
  );
}
