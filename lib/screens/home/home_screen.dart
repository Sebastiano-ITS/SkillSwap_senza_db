import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      )..add(LoadProfiles()),
      child: _HomeView(currentUserProfile: currentUserProfile),
    );
  }
}

class _HomeView extends StatefulWidget {
  final UserProfile currentUserProfile;
  const _HomeView({super.key, required this.currentUserProfile});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  Offset _offset = Offset.zero;
  String? _overlay; // 'like' or 'nope'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is ProfileMatched) {
              _showMatchDialog(state.profile);
            }
          },
          builder: (context, state) {
            if (state is HomeError) {
              return Center(child: Text(state.message));
            }

            if (state is HomeLoaded) {
              final profiles = state.profiles
                  .where((p) => p.id != widget.currentUserProfile.id)
                  .toList();

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = profiles.length - 1; i >= 0; i--)
                      _buildCard(profiles[i], i == profiles.length - 1),
                    if (_overlay != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _overlay == 'like'
                                ? Colors.green.withOpacity(0.4)
                                : Colors.red.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              _overlay == 'like'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildCard(UserProfile profile, bool topCard) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;
    final double cardHeight = MediaQuery.of(context).size.height * 0.75;

    return Positioned(
      child: GestureDetector(
        onPanUpdate: topCard
            ? (details) {
          setState(() {
            _offset += details.delta;
            if (_offset.dx > 100) {
              _overlay = 'like';
            } else if (_offset.dx < -100) {
              _overlay = 'nope';
            } else {
              _overlay = null;
            }
          });
        }
            : null,
        onPanEnd: topCard
            ? (_) {
          if (_offset.dx > 150) {
            context.read<HomeBloc>().add(SwipeRight(profile));
          } else if (_offset.dx < -150) {
            context.read<HomeBloc>().add(SwipeLeft(profile));
          }

          setState(() {
            _offset = Offset.zero;
            _overlay = null;
          });
        }
            : null,
        child: Transform.translate(
          offset: topCard ? _offset : Offset.zero,
          child: Transform.rotate(
            angle: topCard ? _offset.dx / 300 : 0,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: Column(
                children: [
                  _buildImage(profile),
                  _buildInfo(profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(UserProfile profile) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: profile.localImages.isNotEmpty
            ? Image.asset(
          profile.localImages.first,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Center(
            child: Text(
              'Asset non trovato:\n${profile.localImages.first}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        )
            : Container(color: Colors.grey),
      ),
    );
  }

  Widget _buildInfo(UserProfile profile) {
    final age = profile.age != null ? ', ${profile.age}' : '';
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${profile.name}$age',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBadgeGroup("Skills", profile.canTeach, Colors.pinkAccent),
              const SizedBox(height: 4),
              _buildBadgeGroup(
                  "Wants to learn", profile.wantsToLearn, Colors.orange),
              const SizedBox(height: 8),
              Text(profile.bio ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGroup(String label, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items
              .map(
                (e) => Chip(
              label: Text(e),
              backgroundColor: color,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  void _showMatchDialog(UserProfile matchedUser) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Match trovato!"),
        content: Text("Hai fatto match con ${matchedUser.name}!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}