import 'package:flutter/material.dart';
import '../theme/brand_palette.dart';

/// Barra step riutilizzabile (pillole) con lo stesso look delle versioni precedenti.
/// [total] = numero totale di tacche
/// [activeCount] = quante tacche sono attive (riempite e allungate)
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.total,
    required this.activeCount,
  }) : assert(total > 0);

  final int total;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool active = i < activeCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: active ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? BrandPalette.purple : Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
