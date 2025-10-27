// lib/screens/login_signup/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/brand_palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();

    try {
      if (_isLogin) {
        await auth.signIn(_email.text.trim(), _password.text.trim());
        final UserProfile? me = auth.getCurrentUserProfile();

        if (me != null && mounted) {
          if (me.onboardingCompleted == true) {
            context.go('/home', extra: me);
          } else {
            context.go('/onboarding', extra: me.id);
          }
        } else {
          setState(() => _error = 'Impossibile recuperare il profilo utente.');
        }
      } else {
        await auth.signUp(
          _email.text.trim(),
          _password.text.trim(),
          _name.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrazione completata. Accedi con le tue credenziali.')),
        );
        setState(() {
          _isLogin = true;
          _password.clear();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

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
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 8),
                            child: Image.asset('assets/images/logo_no_bg.png', height: 96),
                          ),
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [BrandPalette.purple, BrandPalette.magenta, BrandPalette.orange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(rect),
                            child: Text(
                              'SKILL SWAP',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '“Insegna quello che sai, impara quello che vuoi”.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),

                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: _decor('Nome', icon: Icons.person),
                              validator: (v) {
                                if (_isLogin) return null;
                                if (v == null || v.trim().isEmpty) return 'Inserisci il tuo nome';
                                if (v.trim().length < 2) return 'Il nome è troppo corto';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _decor('Email', icon: Icons.email),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Inserisci l\'email';
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
                              if (!ok) return 'Email non valida';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _decor(
                              'Password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                tooltip: _obscure ? 'Mostra password' : 'Nascondi password',
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Inserisci la password';
                              if (v.length < 6) return 'Minimo 6 caratteri';
                              return null;
                            },
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                          ],

                          const SizedBox(height: 18),

                          _GradientButton(
                            onPressed: _loading ? null : _submit,
                            loading: _loading,
                            label: _isLogin ? 'Login' : 'Crea account',
                          ),

                          // ✅ VERSIONE SEMPLICE: Viola scuro, sottolineato
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 6),
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Funzione non disponibile in questa demo.')),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: BrandPalette.purple, // colore viola scuro
                              ),
                              child: const Text(
                                'Dimenticata?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.8,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: BrandPalette.purple, width: 1.3),
                                foregroundColor: BrandPalette.purple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              child: Text(_isLogin ? 'Registrati' : 'Accedi'),
                            ),
                          ),

                          SizedBox(height: size.height < 700 ? 6 : 0),
                        ],
                      ),
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

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.onPressed,
    required this.loading,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressed ? 0.98 : 1.0,
        child: SizedBox(
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
              onPressed: widget.loading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              child: widget.loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
