// lib/screens/profile/onboarding_learn_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../theme/brand_palette.dart';

class OnboardingLearnScreen extends StatefulWidget {
  const OnboardingLearnScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OnboardingLearnScreen> createState() => _OnboardingLearnScreenState();
}

class _OnboardingLearnScreenState extends State<OnboardingLearnScreen> {
  // suggerimenti attinenti a SkillSwap (diversi/overlap con teach va benissimo)
  static const List<String> _suggested = [
    'Programmazione',
    'Matematica',
    'Fisica',
    'Inglese',
    'Cucina',
    'Fotografia',
    'Design',
    'Marketing',
    'Musica',
    'Public Speaking',
    'Project Management',
    'UI/UX',
    'Dattilografia',
    'Tedesco',
    'Spagnolo',
    'Francese',
  ];

  late UserProfile _user;
  final Set<String> _selected = <String>{};

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
    _selected.addAll(u.wantsToLearn);
    setState(() => _loading = false);
  }

  String _normalize(String s) {
    final x = s.trim();
    if (x.isEmpty) return x;
    return x[0].toUpperCase() + x.substring(1);
  }

  Future<void> _addCustomSkill() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi una competenza da imparare'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Es. Flutter, Chitarra, Cucina giapponese…',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
    if (res != null && res.isNotEmpty) {
      setState(() => _selected.add(_normalize(res)));
    }
  }

  Future<void> _continue() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una competenza che vuoi imparare.')),
      );
      return;
    }
    final updated = _user.copyWith(
      wantsToLearn: _selected.toList()..sort(),
    );
    try {
      await LocalData().saveUser(updated);
      if (!mounted) return;
      // Fine onboarding (per ora): vai alla home con il profilo aggiornato
      context.go('/onboarding/ready', extra: updated.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background pieno
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_color.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Overlay leggibilità
          Container(color: Colors.white.withOpacity(0.30)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cosa vuoi imparare?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BrandPalette.purple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aggiungiamo nuove skill costantemente.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 18),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final s in _suggested)
                              _SkillChip(
                                label: s,
                                selected: _selected.contains(s),
                                onTap: () => setState(() {
                                  if (_selected.contains(s)) {
                                    _selected.remove(s);
                                  } else {
                                    _selected.add(s);
                                  }
                                }),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _addCustomSkill,
                            style: TextButton.styleFrom(foregroundColor: BrandPalette.purple),
                            child: const Text('Altro'),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // CTA
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
                              onPressed: _continue,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              child: const Text(
                                'Continua',
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
                        // step indicator (3/4 ipotetico)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _StepDot(active: true),
                            _StepDot(active: true),
                            _StepDot(active: true),
                            _StepDot(),
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

/// chip brand
class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? BrandPalette.purple.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? BrandPalette.purple : BrandPalette.amber,
            width: 1.4,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: BrandPalette.purple.withOpacity(0.20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? BrandPalette.purple : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// glass card riusabile
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
