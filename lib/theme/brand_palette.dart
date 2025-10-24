// lib/theme/brand_palette.dart
import 'package:flutter/material.dart';

class BrandPalette {
  static const Color amber = Color(0xFFFFB200); // FFB200
  static const Color orange = Color(0xFFEB5B00); // EB5B00
  static const Color magenta = Color(0xFFD91656); // D91656
  static const Color purple = Color(0xFF640D5F); // 640D5F

  /// Gradienti
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, magenta, orange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient subtleBg = LinearGradient(
    colors: [
      Color(0x10FFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ombre
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Bordi glass
  static Border glassBorder = Border.all(
    color: Colors.white.withOpacity(0.35),
    width: 1.2,
  );
}
