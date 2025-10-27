// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'brand_palette.dart';

/// Tema principale di SkillSwap
/// Moderno, artistico e coerente in tutte le schermate.
class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: BrandPalette.orange,
        brightness: Brightness.light,
        primary: BrandPalette.orange,
        secondary: BrandPalette.magenta,
        tertiary: BrandPalette.purple,
        surface: Colors.white.withOpacity(0.95),
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),

      // TextTheme coerente, leggibile e contemporanea
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ).copyWith(
        displayLarge: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 46,
          letterSpacing: -1.2,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.3,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Bottoni moderni
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandPalette.orange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: Colors.black.withOpacity(0.25),
          elevation: 4,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandPalette.magenta,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Chip glassmorphici coerenti
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white.withOpacity(0.15),
        side: BorderSide(color: Colors.white.withOpacity(0.35)),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 2,
      ),

      // Card uniformate
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white.withOpacity(0.12),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        hintStyle: const TextStyle(color: Colors.black54),
        labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: BrandPalette.purple, width: 1.5),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.white38,
        thickness: 0.7,
      ),

      iconTheme: const IconThemeData(color: Colors.white),
      useMaterial3: true,
    );
  }

  /// Tema scuro opzionale (gradienti invertiti e testo più morbido)
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: BrandPalette.purple,
        secondary: BrandPalette.magenta,
        surface: const Color(0xFF1A1A1A),
        onSurface: Colors.white70,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
        fontFamily: 'Inter',
      ),
      scaffoldBackgroundColor: const Color(0xFF101010),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withOpacity(0.15),
        side: BorderSide(color: Colors.white.withOpacity(0.25)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
