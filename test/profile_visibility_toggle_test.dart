import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/screens/profile/profile_screen.dart';

void main() {
  group('adaptToggleOnChanged', () {
    test('uses fallback value when toggle emits null', () {
      bool? capturedValue;
      final handler = adaptToggleOnChanged(
        onChanged: (value) => capturedValue = value,
        fallbackValue: true,
      );

      handler(null);

      expect(capturedValue, isTrue);
    });

    test('forwards non-null values as-is', () {
      bool? capturedValue;
      final handler = adaptToggleOnChanged(
        onChanged: (value) => capturedValue = value,
        fallbackValue: false,
      );

      handler(true);

      expect(capturedValue, isTrue);
    });
  });
}