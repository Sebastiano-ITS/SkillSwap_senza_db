import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../flutter_bloc/home_bloc/home_bloc.dart';
import '../../flutter_bloc/home_bloc/home_event.dart';
import '../../flutter_bloc/home_bloc/home_state.dart';
import '../../models/user_profile.dart';
import 'profile_card.dart';
import 'swipe_overlay.dart';

class HomeScreen extends StatelessWidget {
  final UserProfile currentUserProfile;
  const HomeScreen({super.key, required this.currentUserProfile});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadProfiles()),
      child: Scaffold(
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoaded) {
              return Stack(
                children: [
                  PageView.builder(
                    itemCount: state.profiles.length,
                    itemBuilder: (context, index) {
                      final profile = state.profiles[index];
                      return GestureDetector(
                        onPanEnd: (details) {
                          if (details.velocity.pixelsPerSecond.dx > 0) {
                            context.read<HomeBloc>().add(SwipeRight(profile));
                          } else {
                            context.read<HomeBloc>().add(SwipeLeft(profile));
                          }
                        },
                        child: ProfileCard(profile: profile),
                      );
                    },
                  ),
                  const SwipeOverlay(),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}