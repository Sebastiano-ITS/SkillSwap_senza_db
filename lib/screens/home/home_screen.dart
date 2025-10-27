import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillswap/screens/home/profile_card.dart';
import 'package:skillswap/screens/home/swipe_overlay.dart';

import '../../features/profile/user_repository.dart';
import '../../flutter_bloc/home_bloc/home_bloc.dart';
import '../../flutter_bloc/home_bloc/home_event.dart';
import '../../flutter_bloc/home_bloc/home_state.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/match_services.dart';
import '../../theme/brand_palette.dart';

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

    await Future.delayed(Duration.zero);
    if (!mounted) return;

    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text("🎉 Match trovato!"),
        content: Text("Hai fatto match con ${matchedUser.name}!"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _dialogOpen = false;

    // Comunica al bloc che il dialog è chiuso
    context.read<HomeBloc>().add(const DialogClosed());
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('SkillSwap', style: tt.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandPalette.amber,
              BrandPalette.orange,
              BrandPalette.magenta,
              BrandPalette.purple
            ],
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
                  child: Text(
                    state.message,
                    style: tt.titleMedium?.copyWith(color: Colors.white),
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
                  child: Text(
                    'Nessun profilo disponibile',
                    style: tt.titleMedium?.copyWith(color: Colors.white),
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
                        onSwipeRight: (p) =>
                            context.read<HomeBloc>().add(SwipeRight(p)),
                        onSwipeLeft: (p) =>
                            context.read<HomeBloc>().add(SwipeLeft(p)),
                      ),
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
