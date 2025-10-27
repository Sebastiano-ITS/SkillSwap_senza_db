// lib/widgets/onboarding_ui.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_palette.dart';

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    this.tooltip,
    this.overrideRoute,
    this.extra, // 👈 NEW
  });

  final String? tooltip;
  final String? overrideRoute;
  final Object? extra; // 👈 NEW

  @override
  Widget build(BuildContext context) {
    final btn = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.18),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.35), width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: () {
              if (overrideRoute != null && overrideRoute!.isNotEmpty) {
                context.go(overrideRoute!, extra: extra); // 👈 passa l'extra
              } else {
                context.pop();
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded, color: BrandPalette.purple),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Dots di avanzamento (retro-compatibile).
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    this.current,
    this.activeCount,
    this.total = 5,
  });

  final int? current;
  final int? activeCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    int active = current ?? activeCount ?? 0;
    if (active < 0) active = 0;
    if (active > total) active = total;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
            (i) => _StepDot(active: i < active),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({this.active = false});
  final bool active;

  @override
  Widget build(BuildContext context) {
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
  }
}
