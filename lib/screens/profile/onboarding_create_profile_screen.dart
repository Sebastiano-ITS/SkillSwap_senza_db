// lib/screens/profile/onboarding_create_profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/brand_palette.dart';
import '../../data/local_data.dart';
import '../../models/user_profile.dart';

// ⬇️ componenti condivisi (dots / glass back, qui usiamo solo i dots)
import '../../widgets/onboarding_ui.dart';

class OnboardingCreateProfileScreen extends StatefulWidget {
  const OnboardingCreateProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<OnboardingCreateProfileScreen> createState() =>
      _OnboardingCreateProfileScreenState();
}

class _OnboardingCreateProfileScreenState
    extends State<OnboardingCreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();

  DateTime? _birthDate;
  double _radiusKm = 3;

  bool _saving = false;
  String? _error;

  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    final user = LocalData().getUserById(widget.userId);
    if (user == null) {
      _error = 'Profilo non trovato.';
    } else {
      _user = user;
      _name.text = user.name;
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  InputDecoration _decor(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      prefixIcon: icon != null ? Icon(icon, color: BrandPalette.purple) : null,
      suffixIcon: suffix,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(now.year - 100);
    final last = DateTime(now.year - 13);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Seleziona data di nascita',
      confirmText: 'Conferma',
      cancelText: 'Annulla',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = _user.copyWith(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        radiusKm: _radiusKm,
        birthDateIso: _birthDate?.toIso8601String().substring(0, 10),
        // lo step finale imposterà onboardingCompleted = true
      );

      await LocalData().saveUser(updated);

      if (!mounted) return;
      context.go('/onboarding/teach', extra: updated.id);
    } catch (e) {
      setState(() => _error = 'Errore salvataggio: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // 👉 niente back nello step 1

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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'La tua mente si espande da qui',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BrandPalette.purple,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                decoration: _decor('Nome', icon: Icons.person),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Inserisci il tuo nome';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              GestureDetector(
                                onTap: _pickBirthDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: _decor(
                                      'Data di nascita',
                                      icon: Icons.cake_outlined,
                                      suffix: const Icon(Icons.calendar_today, color: Colors.black54),
                                    ),
                                    controller: TextEditingController(
                                      text: _birthDate == null
                                          ? ''
                                          : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: _decor('Email', icon: Icons.email),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Inserisci l\'email';
                                  }
                                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                      .hasMatch(v.trim());
                                  if (!ok) return 'Email non valida';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _phone,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.phone,
                                decoration: _decor('Cellulare', icon: Icons.phone),
                              ),
                              const SizedBox(height: 22),

                              Text(
                                'Dove ti trovi?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),

                              TextFormField(
                                controller: _city,
                                decoration: _decor(
                                  'Città (es. Milano)',
                                  icon: Icons.location_on_outlined,
                                  suffix: IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Geolocalizzazione non abilitata in questa build.'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.my_location, color: Colors.black54),
                                    tooltip: 'Usa la posizione corrente',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Quanto vicini devono essere gli Swappers?',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87),
                                ),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _radiusKm,
                                      min: 1,
                                      max: 50,
                                      divisions: 49,
                                      label: '${_radiusKm.round()} km',
                                      activeColor: BrandPalette.magenta,
                                      thumbColor: BrandPalette.orange,
                                      onChanged: (v) => setState(() => _radiusKm = v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      '${_radiusKm.round()}km',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                              ],

                              const SizedBox(height: 16),

                              _GradientButton(
                                label: 'Continua',
                                loading: _saving,
                                onPressed: _saving ? null : _continue,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ✅ Dots unificati: 1/5 (niente back in questo step)
                        const StepDots(current: 1, total: 5),
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

/// Glassmorphism card
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

/// Gradient button coerente con il brand
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: loading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
