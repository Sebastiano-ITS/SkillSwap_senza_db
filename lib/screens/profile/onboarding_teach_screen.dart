// lib/screens/profile/onboarding_teach_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../theme/brand_palette.dart';
// componenti condivisi (back + dots)
import '../../widgets/onboarding_ui.dart';
import '../../widgets/step_dots.dart' hide StepDots;

class OnboardingTeachScreen extends StatefulWidget {
  const OnboardingTeachScreen({super.key, required this.userId});

  final String userId;

  @override
  State<OnboardingTeachScreen> createState() => _OnboardingTeachScreenState();
}

class _OnboardingTeachScreenState extends State<OnboardingTeachScreen> {
  final TextEditingController _bio = TextEditingController();

  // Sorgente suggerimenti (coerenti con l’app SkillSwap)
  final List<String> _suggested = const [
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
    _selected.addAll(u.canTeach);
    _bio.text = u.bio ?? '';
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _addCustomSkill() async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi una competenza'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Es. Flutter, Chitarra, Fotografia notturna…',
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

  String _normalize(String s) {
    final x = s.trim();
    if (x.isEmpty) return x;
    return x[0].toUpperCase() + x.substring(1);
  }

  Future<void> _continue() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una competenza che puoi insegnare.')),
      );
      return;
    }

    final updated = _user.copyWith(
      canTeach: _selected.toList()..sort(),
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
    );

    try {
      await LocalData().saveUser(updated);
      if (!mounted) return;
      context.go('/onboarding/learn', extra: updated.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio: $e')),
      );
    }
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.90),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandPalette.purple, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background full
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_color.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Overlay leggibilità
          Container(color: Colors.white.withOpacity(0.30)),

          // ← Back (step 2+)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GlassIconButton(
                  tooltip: 'Indietro',
                  overrideRoute: '/onboarding',
                  extra: _user.id,
                ),

              ),
            ),
          ),

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
                        // Titolo + sottotitolo
                        Text(
                          'Cosa vuoi insegnare?',
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

                        // Griglia chip suggerite
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

                        // Pulsante "Altro"
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _addCustomSkill,
                            style: TextButton.styleFrom(foregroundColor: BrandPalette.purple),
                            child: const Text('Altro'),
                          ),
                        ),

                        const SizedBox(height: 22),
                        Text(
                          'Parlaci un po’ di te:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // BIO
                        TextField(
                          controller: _bio,
                          maxLines: 5,
                          minLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: _decor('Scrivi una breve bio…'),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
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
                        // ✅ Dots 2/5
                        const StepDots(current: 2, total: 5),
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

/// Glass card riusabile (coerente con login/registrazione)
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
