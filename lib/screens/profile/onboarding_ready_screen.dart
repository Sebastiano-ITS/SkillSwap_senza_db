import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../theme/brand_palette.dart';

class OnboardingReadyScreen extends StatefulWidget {
  const OnboardingReadyScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OnboardingReadyScreen> createState() => _OnboardingReadyScreenState();
}

class _OnboardingReadyScreenState extends State<OnboardingReadyScreen> {
  late UserProfile _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = LocalData().getUserById(widget.userId);
    if (u == null) {
      setState(() {
        _error = 'Profilo non trovato.';
        _loading = false;
      });
      return;
    }
    _user = u;
    _loading = false;
  }

  Future<void> _finish() async {
    final updated = _user.copyWith(onboardingCompleted: true);
    await LocalData().saveUser(updated);
    if (!mounted) return;
    context.go('/home', extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_color.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Container(color: Colors.white.withOpacity(0.30)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _VerifiedIllustration(),
                        const SizedBox(height: 16),
                        Text(
                          'Pronto a imparare nuove abilità!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BrandPalette.purple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sei ufficialmente uno Swapper.',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Trova chi vuole imparare da te.\n'
                              '• Scopri chi può insegnarti ciò che cerchi.\n'
                              '• Scambia competenze, cresce ogni giorno.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: BrandPalette.primaryGradient,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandPalette.purple.withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _finish,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: const Text(
                                'Inizia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _StepDot(active: true),
                            _StepDot(active: true),
                            _StepDot(active: true),
                            _StepDot(active: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Versione SENZA glow/ombra
class _VerifiedIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/verified.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BrandPalette.purple, BrandPalette.magenta, BrandPalette.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.90),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, size: 72, color: BrandPalette.purple),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: BrandPalette.subtleBg,
            color: Colors.white.withOpacity(0.20),
            border: BrandPalette.glassBorder,
            borderRadius: BorderRadius.circular(22),
            boxShadow: BrandPalette.softShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: child,
        ),
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
