import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/profile/user_repository.dart';
import '../flutter_bloc/home_bloc/home_bloc.dart';
import '../flutter_bloc/home_bloc/home_event.dart';

import '../screens/profile/onboarding_learn_screen.dart';
import '../screens/login_signup/register_screen.dart';
import '../screens/auth_wrapper.dart';
import '../screens/login_signup/login_screen.dart';
import '../screens/profile/onboarding_create_profile_screen.dart';
import '../screens/profile/onboarding_teach_screen.dart';
import '../features/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../models/user_profile.dart';
import '../screens/explore/user_list_screen.dart';
import '../screens/profile/onboarding_ready_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../services/auth_service.dart';
import '../services/match_services.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../models/chat.dart';

import '../screens/profile/onboarding_media_screen.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Schermata di splash
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Schermata finale dell'onboarding
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

    // Step intermedio per caricare media dell'utente
    GoRoute(
      path: '/onboarding/media',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingMediaScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per lo step media.')),
        );
      },
    ),

    // Step per selezionare cosa si vuole imparare
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

    // Step per selezionare cosa si può insegnare
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

    // Wrapper per autenticazione (sceglie login o main)
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),

    // Schermata login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Schermata registrazione
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Step di creazione profilo iniziale
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is String && extra.isNotEmpty) {
          return OnboardingCreateProfileScreen(userId: extra);
        }
        return const Scaffold(
          body: Center(child: Text('Utente non fornito per l’onboarding.')),
        );
      },
    ),

    // Shell principale con bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Schermata home con bloc
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is UserProfile) {
              return BlocProvider(
                create: (context) => HomeBloc(
                  matchService: MatchService(),
                  authService: context.read<AuthService>(),
                  usersRepository: const UsersRepository(),
                )..add(LoadProfiles()),
                child: HomeScreen(currentUserProfile: extra),
              );
            }

            return const Scaffold(
              body: Center(child: Text('Dati utente mancanti per la schermata Home.')),
            );
          },
        ),

        // Schermata explore
        GoRoute(
          path: '/explore',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is UserProfile) {
              return ExploreScreen(currentUserProfile: extra);
            }
            return const Scaffold(
              body: Center(child: Text('Dati utente mancanti per la schermata Explore.')),
            );
          },

          // elenco utenti per abilità
          routes: [
            GoRoute(
              path: 'users_by_skill/:skill',
              builder: (context, state) {
                final skill = state.pathParameters['skill'] ?? 'sconosciuta';
                return UserListScreen(skill: skill);
              },
            ),
          ],
        ),

        // Schermata lista chat
        GoRoute(
          path: '/chat',
          builder: (context, state) => const ChatListScreen(),
          routes: [
            // Schermata dettaglio chat
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                final chat = state.extra as Chat?;
                if (chat == null || chat.id != id) {
                  return const Scaffold(body: Center(child: Text('Chat non trovata')));
                }
                return ChatDetailScreen(chat: chat);
              },
            ),
          ],
        ),

        // Schermata profilo
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