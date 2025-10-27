import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/profile/user_repository.dart';
import '../../flutter_bloc/home_bloc/home_bloc.dart';
import '../../flutter_bloc/home_bloc/home_event.dart';
import '../../flutter_bloc/home_bloc/home_state.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/match_services.dart';
import '../../theme/brand_palette.dart';
import 'profile_card.dart';
import 'swipe_overlay.dart';

class HomeScreen extends StatelessWidget {
  final UserProfile currentUserProfile;
  const HomeScreen({super.key, required this.currentUserProfile});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        matchService: MatchService(),
        authService: context.read<AuthService>(),
        usersRepository: const UsersRepository(),
      )..add(const LoadProfiles()),
      child: _HomeView(currentUserProfile: currentUserProfile),
    );
  }
}

class _HomeView extends StatefulWidget {
  final UserProfile currentUserProfile;
  const _HomeView({required this.currentUserProfile});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _dialogOpen = false;

  Future<void> _safeShowMatchDialog(UserProfile matchedUser) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    // Evita setState durante il build
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final theme = Theme.of(context);

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        // Forza dialog chiaro e testo scuro, indipendente dal tema esterno
        final dlgTheme = theme.copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white, // evita tint grigiastro su Android 12+
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        );

        return Theme(
          data: dlgTheme,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [BrandPalette.purple, BrandPalette.magenta, BrandPalette.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Match trovato!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Hai fatto match con ${matchedUser.name} 🎉',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                if (matchedUser.canTeach.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: matchedUser.canTeach.take(4).map((s) {
                      return Chip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFFE6E6EA)),
                        backgroundColor: const Color(0xFFF8F8FA),
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: BrandPalette.purple,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Chiudi'),
              ),
              SizedBox(
                height: 42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: BrandPalette.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: BrandPalette.purple.withOpacity(0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                      // TODO: se gestisci la chat, naviga qui:
                      // context.go('/chat/${matchedUser.id}', extra: matchedUser);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Apri chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    _dialogOpen = false;

    // Comunica al bloc che il dialog è stato chiuso
    context.read<HomeBloc>().add(const DialogClosed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background brand coerente con il resto dell’app
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [BrandPalette.amber, BrandPalette.orange, BrandPalette.magenta, BrandPalette.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<HomeBloc, HomeState>(
            listener: (context, state) {
              if (state is ProfileMatched) {
                _safeShowMatchDialog(state.profile);
                HapticFeedback.mediumImpact();
              } else if (state is HomeError) {
                HapticFeedback.selectionClick();
              }
            },
            builder: (context, state) {
              if (state is HomeError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (state is! HomeLoaded) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final profiles = state.profiles
                  .where((p) => p.id != widget.currentUserProfile.id)
                  .toList();

              if (profiles.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: const Text(
                      'Nessun profilo disponibile',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < profiles.length; i++)
                      ProfileCard(
                        profile: profiles[i],
                        isTopCard: i == profiles.length - 1,
                        onSwipeRight: (p) => context.read<HomeBloc>().add(SwipeRight(p)),
                        onSwipeLeft: (p) => context.read<HomeBloc>().add(SwipeLeft(p)),
                      ),
                    // Overlay post-swipe controllato dal bloc (coerente col brand)
                    const SwipeOverlay(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
