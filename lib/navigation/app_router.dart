import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_wrapper.dart';
import '../screens/login_screen.dart';
import '../features/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile_screen.dart';
import '../models/user_profile.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
            // Fallback: mostra messaggio se non è stato passato un UserProfile
            return Scaffold(
              appBar: AppBar(title: const Text('Home')),
              body: const Center(child: Text('Dati utente mancanti per la schermata Home.')),
            );
          },
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) {
            // Evita errori se ExploreScreen non è esportato correttamente: placeholder minimale
            return Scaffold(
              appBar: AppBar(title: const Text('Explore')),
              body: const Center(child: Text('Explore non disponibile.')),
            );
          },
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            // Evita errori se ChatListScreen non è esportato correttamente: placeholder minimale
            return Scaffold(
              appBar: AppBar(title: const Text('Chat')),
              body: const Center(child: Text('Chat non disponibile.')),
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) {
            final profile = state.extra;
            if (profile is UserProfile) {
              return ProfileScreen(userProfile: profile);
            }
            // Fallback: mostra messaggio se non è stato passato un UserProfile
            return Scaffold(
              appBar: AppBar(title: const Text('Profilo non disponibile')),
              body: const Center(child: Text('Nessun profilo fornito per visualizzare la schermata profilo.')),
            );
          },
        ),
      ],
    ),
  ],
);