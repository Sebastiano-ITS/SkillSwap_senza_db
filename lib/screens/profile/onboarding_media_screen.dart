// lib/screens/profile/onboarding_media_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../theme/brand_palette.dart';
import '../../widgets/onboarding_ui.dart';

class OnboardingMediaScreen extends StatefulWidget {
  const OnboardingMediaScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OnboardingMediaScreen> createState() => _OnboardingMediaScreenState();
}

class _OnboardingMediaScreenState extends State<OnboardingMediaScreen> {
  late UserProfile _user;
  bool _loading = true;
  String? _error;

  // fino a 6 media
  final List<File?> _media = List<File?>.filled(6, null);

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
    setState(() => _loading = false);
  }

  Future<void> _pickAt(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _media[index] = File(file.path));
  }

  Future<void> _continue() async {
    if (!mounted) return;
    context.go('/onboarding/ready', extra: _user.id);
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

          // 🔙 Back (con extra!)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GlassIconButton(
                  tooltip: 'Indietro',
                  overrideRoute: '/onboarding/learn',
                  extra: _user.id, // 👈 passa l'id utente
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
                        Text(
                          'Aggiungi foto o video di te e delle tue skill!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BrandPalette.purple,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // griglia 3x2
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(
                            6,
                                (i) => GestureDetector(
                              onTap: () => _pickAt(i),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(18),
                                  border: BrandPalette.glassBorder,
                                  boxShadow: BrandPalette.softShadow,
                                ),
                                child: _media[i] == null
                                    ? const Center(
                                  child: Icon(Icons.add, color: BrandPalette.purple),
                                )
                                    : ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(_media[i]!, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
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
                        const StepDots(current: 4, total: 5),
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
