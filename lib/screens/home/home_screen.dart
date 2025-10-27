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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      body: SafeArea(
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
              return Center(child: Text(state.message));
            }

            if (state is! HomeLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final profiles = state.profiles
                .where((p) => p.id != widget.currentUserProfile.id)
                .toList();

            if (profiles.isEmpty) {
              return const Center(child: Text('Nessun profilo disponibile'));
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

                  // Overlay post-swipe controllato dal bloc
                  const SwipeOverlay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}