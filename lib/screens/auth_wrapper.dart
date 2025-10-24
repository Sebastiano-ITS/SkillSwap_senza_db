import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamProvider<User?> è già configurato nel main
    final user = context.watch<User?>();
    final auth = context.read<AuthService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        // Utente non loggato → vai al login solo se non ci sei già
        final currentPath = GoRouterState.of(context).uri.toString();
        if (currentPath != '/login') {
          context.go('/login');
        }
      } else {
        // Utente loggato: recupera il profilo locale
        final UserProfile? profile = auth.getCurrentUserProfile();
        if (profile == null) {
          context.go('/login');
          return;
        }

        // Se non ha completato l’onboarding, portalo lì
        if (profile.onboardingCompleted == false) {
          context.go('/onboarding', extra: profile.id);
        } else {
          // Altrimenti entra nel flusso principale
          context.go('/home', extra: profile);
        }
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
