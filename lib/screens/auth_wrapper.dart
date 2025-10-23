import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final userProfile = context.read<AuthService>().getCurrentUserProfile();

    // Reindirizza in base allo stato dell'utente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        context.go('/login');
      } else {
        // Passa SEMPRE il profilo utente come extra alla Home
        if (userProfile != null) {
          context.go('/home', extra: userProfile);
        } else {
          // In caso estremo, vai comunque a /home (mostrerà il fallback) o torna al login
          context.go('/home');
        }
      }
    });

    // Mostra uno spinner mentre si decide dove andare
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}