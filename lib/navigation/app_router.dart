import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/profile/onboarding_learn_screen.dart';
import '../screens/login_signup/register_screen.dart';
import '../screens/auth_wrapper.dart';
import '../screens/login_signup/login_screen.dart';
import '../screens/profile/onboarding_create_profile_screen.dart'; // ⬅️ import onboarding
import '../screens/profile/onboarding_teach_screen.dart';
import '../features/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../models/user_profile.dart';
import '../screens/explore/user_list_screen.dart'; // Importa la nuova schermata

import '../screens/profile/onboarding_ready_screen.dart';
import '../screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding/ready',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingReadyScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per lo step finale.')),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/learn',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingLearnScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per lo step "imparare".')),
        );
      },
    ),
    GoRoute(
      path: '/onboarding/teach',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingTeachScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per lo step delle competenze.')),
        );
      },
    ),
    // Schermate fuori dalla Shell (senza bottom bar)
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        // ci aspettiamo l'userId passato in extra
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingCreateProfileScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per l’onboarding.')),
        );
      },
    ),

    // Schermate dentro la Shell (con bottom bar)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is UserProfile) {
              return HomeScreen(currentUserProfile: extra);
            }
            return const Scaffold(
              body: Center(child: Text('Dati utente mancanti per la schermata Home.')),
            );
          },
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) {
            // 1. Recupera i dati passati durante la navigazione
            final extra = state.extra;
            if (extra is UserProfile) {
              // 2. Se i dati sono del tipo corretto, passa il profilo a ExploreScreen
              return ExploreScreen(currentUserProfile: extra);
            }
            // 3. Fallback di sicurezza se i dati non sono disponibili
            return const Scaffold(
              body: Center(child: Text('Dati utente mancanti per la schermata Explore.')),
            );

          },

          // Definiamo la rotta della lista utenti come FIGLIA di /explore
          routes: [
            GoRoute(
              path: 'users_by_skill/:skill', // NOTA: Niente '/' all'inizio
              builder: (context, state) {
                final skill = state.pathParameters['skill'] ?? 'sconosciuta';
                return UserListScreen(skill: skill);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Chat non disponibile.')),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final profile = state.extra;
            if (profile is UserProfile) {
              return ProfileScreen(userId: profile.id);
            }
            return const Scaffold(
              body: Center(child: Text('Nessun profilo fornito per visualizzare la schermata profilo.')),
            );
          },
        ),
      ],
    ),
  ],
);
