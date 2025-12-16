import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniThriveTheme {
  UniThriveTheme._();

  // Brand Colors
  static const Color primary = Color(0xFF9FCFBB); // Mint Green
  static const Color secondary = Color(0xFF58CC02); // Duolingo Green

  // Duolingo-style Palette
  static const Color duolingoGreen = Color(0xFF58CC02);
  static const Color duolingoGold = Color(0xFFFFD700);
  static const Color duolingoOrange = Color(0xFFFF9900);
  static const Color duolingoBlue = Color(0xFF1CB0F6);

  // Neutral Colors (Light)
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF334155);
  static const Color textLight = Color(0xFF64748B);
  static const Color backgroundLight = Color(0xFFF7F7F7);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceVariantLight = Color(0xFFF0F0F0);
  static const Color inputFillLight = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Colors (Dark)
  static const Color textDarkTheme = Color(0xFFFAFBFC);
  static const Color textMediumDarkTheme = Color(0xFFE6EDF3);
  static const Color textLightDarkTheme = Color(0xFFD0D7DE);
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1C2128);
  static const Color surfaceVariantDark = Color(0xFF2D333B);
  static const Color inputFillDark = Color(0xFF161B22);
  static const Color borderDark = Color(0xFF3D444D);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: surfaceLight,
        surfaceContainerHighest: surfaceVariantLight,
        onSurface: textDark,
        onSurfaceVariant: textLight,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          titleSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textMedium,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2A37),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF475569),
          ),
          bodySmall: TextStyle(fontSize: 12, color: textLight),
        ),
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceLight,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primary,
          foregroundColor: textDark, // Dark text for contrast
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMedium,
          side: const BorderSide(color: borderLight, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceVariantDark,
        onSurface: textDarkTheme,
        onSurfaceVariant: textLightDarkTheme,
      ),
      fontFamily: 'SF Pro Rounded',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: textDarkTheme,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDarkTheme,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF6F8FA),
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF6F8FA),
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMediumDarkTheme,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textMediumDarkTheme,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: textLightDarkTheme,
        ),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFFB8BFC6)),
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: backgroundDark,
        foregroundColor: textDarkTheme,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMediumDarkTheme,
          side: const BorderSide(color: borderDark, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillDark,
        hintStyle: const TextStyle(
          color: Color(0xFF7D8590),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: textLightDarkTheme,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}
