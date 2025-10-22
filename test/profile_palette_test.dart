import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:skillswap/screens/profile/profile_palette.dart';

void main() {
  group('ProfilePalette', () {
    test('header gradient first color keeps base hue and chroma with tone 30', () {
      final palette = ProfilePalette();
      final baseHct = Hct.fromInt(palette.plum.value);
      final expectedColor = Color(
        Hct.from(baseHct.hue, baseHct.chroma, 30).toInt(),
      );

      expect(palette.headerGradient.colors.first, expectedColor);
    });
  });
}