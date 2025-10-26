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
import '../home/swipe_overlay.dart';

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
  const _HomeView({required this.currentUserProfile});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with SingleTickerProviderStateMixin {
  static const double _likeThreshold = 150;
  static const double _overlayThreshold = 100;
  static const double _maxRotation = 0.35; // ~20°
  Offset _offset = Offset.zero;
  String? _overlay; // 'like' | 'nope'

  late final AnimationController _springCtrl;
  late final Animation<Offset> _springOffset;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _springOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.easeOut),
    )..addListener(() {
      setState(() => _offset = _springOffset.value);
    });
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  void _springBack() {
    _springCtrl.stop();
    (_springOffset as Tween<Offset>)
      ..begin = _offset
      ..end = Offset.zero;
    _springCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is ProfileMatched) {
              _showMatchDialog(state.profile);
              HapticFeedback.mediumImpact();
            }
            if (state is HomeError) {
              HapticFeedback.selectionClick();
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

              if (profiles.isEmpty) {
                return const Center(child: Text('Nessun profilo disponibile'));
              }

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < profiles.length; i++)
                      _buildCard(profiles[i], i == profiles.length - 1),

                    // Overlay di drag
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: _overlay == null,
                        child: AnimatedOpacity(
                          opacity: _overlay == null ? 0 : 1,
                          duration: const Duration(milliseconds: 120),
                          child: Container(
                            margin: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: _overlay == 'like'
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.red.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Icon(
                                _overlay == 'like' ? Icons.check_circle : Icons.cancel,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SwipeOverlay(),
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

  Widget _buildCard(UserProfile profile, bool isTopCard) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.9;
    final double cardHeight = size.height * 0.75;

    // Calcola rotazione limitata
    final double angle = isTopCard ? (_offset.dx / 300).clamp(-_maxRotation, _maxRotation) : 0;

    return IgnorePointer(
      ignoring: !isTopCard, // solo la top-card riceve gesture
      child: Transform.translate(
        offset: isTopCard ? _offset : Offset.zero,
        child: Transform.rotate(
          angle: angle,
          child: GestureDetector(
            onPanUpdate: isTopCard
                ? (details) {
              setState(() {
                _offset += details.delta;

                if (_offset.dx > _overlayThreshold) {
                  _overlay = 'like';
                } else if (_offset.dx < -_overlayThreshold) {
                  _overlay = 'nope';
                } else {
                  _overlay = null;
                }
              });
            }
                : null,
            onPanEnd: isTopCard
                ? (_) {
              if (_offset.dx > _likeThreshold) {
                context.read<HomeBloc>().add(SwipeRight(profile));
                HapticFeedback.lightImpact();
              } else if (_offset.dx < -_likeThreshold) {
                context.read<HomeBloc>().add(SwipeLeft(profile));
                HapticFeedback.lightImpact();
              } else {
                _springBack();
              }

              setState(() {
                _overlay = null;
                // se è stato swipe valido, il bloc aggiornerà la lista al rebuild
                if (_offset.dx.abs() > _likeThreshold) {
                  _offset = Offset.zero;
                }
              });
            }
                : null,
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBadgeGroup("Skills", profile.canTeach, Colors.pinkAccent),
              const SizedBox(height: 4),
              _buildBadgeGroup("Wants to learn", profile.wantsToLearn, Colors.orange),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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