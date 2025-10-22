import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class ProfilePalette {
  ProfilePalette()
      : sunflower = const Color(0xFFFFB200),
        tangerine = const Color(0xFFEB5B00),
        magenta = const Color(0xFFD91656),
        plum = const Color(0xFF640D5F);

  final Color sunflower;
  final Color tangerine;
  final Color magenta;
  final Color plum;

  LinearGradient get headerGradient {
    return LinearGradient(
      colors: [_tone(plum, 30), _tone(magenta, 45)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color get scaffoldBackground => _tone(plum, 96);
  Color get cardColor => Colors.white;
  Color get borderColor => _tone(plum, 80);
  Color get primary => _tone(magenta, 45);
  Color get accent => _tone(sunflower, 60);
  Color get warning => _tone(tangerine, 55);
  Color get textPrimary => _tone(plum, 18);
  Color get textSecondary => _tone(plum, 50);
  Color get textMuted => _tone(plum, 70);
  Color get chipBackground => _tone(plum, 94);

  Color _tone(Color base, double tone) {
    final hct = Hct.fromInt(base.value);
    final adjusted = Hct.from(hct.hue, hct.chroma, tone.clamp(0, 100));
    return Color(adjusted.toInt());
  }
}