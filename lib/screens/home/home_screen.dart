import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  const _HomeView({super.key, required this.currentUserProfile});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with SingleTickerProviderStateMixin {
  static const double _likeThreshold = 150;
  static const double _overlayThreshold = 100;
  static const double _maxRotation = 0.35; // ~20°

  Offset _offset = Offset.zero;
  String? _overlay; // 'like' | 'nope'
  bool _imageScrolling = false;
  bool _dialogOpen = false; // <-- previene crash e dialog ripetuti

  late final AnimationController _springCtrl;
  late Animation<Offset> _springOffset;
  VoidCallback? _springListener; // <-- per gestire correttamente i listener

  final PageController _pageCtrl = PageController();
  int _currentPhoto = 0;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

    // Animazione iniziale (zero -> zero) + listener agganciato
    _springOffset = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.easeOut),
    );
    _attachSpringListener();
  }

  void _attachSpringListener() {
    _springListener = () {
      if (mounted) setState(() => _offset = _springOffset.value);
    };
    _springOffset.addListener(_springListener!);
  }

  @override
  void dispose() {
    // Rimuovo il listener prima di dispose
    if (_springListener != null) {
      _springOffset.removeListener(_springListener!);
      _springListener = null;
    }
    _springCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _springBack() {
    // Ferma animazione corrente ed evita listener duplicati
    _springCtrl.stop();
    if (_springListener != null) {
      _springOffset.removeListener(_springListener!);
      _springListener = null;
    }

    // Ricreo SEMPRE la Tween dall'offset attuale a zero
    _springOffset = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.easeOutBack),
    );

    _attachSpringListener();
    _springCtrl.forward(from: 0);
  }

  Future<void> _safeShowMatchDialog(UserProfile matchedUser) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    await Future.delayed(Duration.zero); // attende build stabilizzato
    if (!mounted) return;

    final result = await showDialog<bool>(
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

    // evita crash se widget smontato
    if (!mounted) return;
    _dialogOpen = false;

    // Dopo chiusura, emetti evento per pulire stato bloc
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

            // L’ultimo child nello Stack è la top-card
            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < profiles.length; i++)
                    _buildCard(
                      profile: profiles[i],
                      isTopCard: i == profiles.length - 1,
                    ),

                  // Overlay locale durante il drag (deve essere Positioned.fill diretto)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _overlay == null,
                      child: AnimatedOpacity(
                        opacity: _overlay == null ? 0 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _overlay == 'like'
                                ? Colors.green.withOpacity(0.35)
                                : Colors.red.withOpacity(0.35),
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

                  // Overlay pilotato dal BLoC (post-swipe): ✔️ / ❌
                  const SwipeOverlay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({
    required UserProfile profile,
    required bool isTopCard,
  }) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.9;
    final double cardHeight = size.height * 0.75;

    // Usa lo stesso offset usato per la translate anche per la rotazione
    final Offset animatedOffset = _springCtrl.isAnimating ? _springOffset.value : _offset;
    final double angle = isTopCard ? (animatedOffset.dx / 300).clamp(-_maxRotation, _maxRotation) : 0;

    return IgnorePointer(
      ignoring: !isTopCard, // solo la top-card riceve gesture
      child: Transform.translate(
        offset: isTopCard ? animatedOffset : Offset.zero,
        child: Transform.rotate(
          angle: angle,
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onPanStart: isTopCard
                ? (_) {
              // se stava tornando al centro, ferma l'animazione per dare priorità al drag
              _springCtrl.stop();
            }
                : null,
            onPanUpdate: isTopCard
                ? (details) {
              if (_imageScrolling) return; // mentre scorri le foto, non trascinare la card
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
              if (_imageScrolling) return;

              if (_offset.dx > _likeThreshold) {
                context.read<HomeBloc>().add(SwipeRight(profile));
                HapticFeedback.lightImpact();
                setState(() {
                  _overlay = null;
                  _offset = Offset.zero;
                  _currentPhoto = 0;
                  _pageCtrl.jumpToPage(0);
                });
              } else if (_offset.dx < -_likeThreshold) {
                context.read<HomeBloc>().add(SwipeLeft(profile));
                HapticFeedback.lightImpact();
                setState(() {
                  _overlay = null;
                  _offset = Offset.zero;
                  _currentPhoto = 0;
                  _pageCtrl.jumpToPage(0);
                });
              } else {
                // Torna al centro ✨ (animazione corretta)
                if (mounted) {
                  setState(() {
                    _overlay = null;
                  });
                  _springBack();
                }
              }
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
                  _buildImageArea(profile, enableGallery: isTopCard),
                  _buildInfo(profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(UserProfile profile, {required bool enableGallery}) {
    final images = profile.localImages;
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          height: 300,
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Text('Nessuna immagine', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: enableGallery
            ? Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                final tapPosition = box?.globalToLocal(details.globalPosition);
                if (tapPosition == null) return;

                final width = box!.size.width;
                final tapX = tapPosition.dx;

                if (tapX < width / 2) {
                  // 👈 Tap lato sinistro → foto precedente
                  if (_currentPhoto > 0) {
                    setState(() {
                      _currentPhoto--;
                      _pageCtrl.animateToPage(
                        _currentPhoto,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    });
                  }
                } else {
                  // 👉 Tap lato destro → foto successiva
                  if (_currentPhoto < images.length - 1) {
                    setState(() {
                      _currentPhoto++;
                      _pageCtrl.animateToPage(
                        _currentPhoto,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    });
                  }
                }
              },
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final path = images[index];
                  return Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Center(
                      child: Text(
                        'Asset non trovato:\n$path',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🔘 Dots indicator
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPhoto == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPhoto == i ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // 👇 Overlay semi-trasparente con indicatori ai lati
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Colors.white70, size: 28),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child:
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            // 👇 Messaggio di hint (solo alla prima foto)
            if (_currentPhoto == 0)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 800),
                  child: const Center(
                    child: Text(
                      'Tocca per cambiare foto',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        )
            : Image.asset(
          images.first,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: Text(
              'Asset non trovato:\n${images.first}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
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
              Text('${profile.name}$age', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBadgeGroup("Skills", profile.canTeach, Colors.pinkAccent),
              const SizedBox(height: 4),
              _buildBadgeGroup("Wants to learn", profile.wantsToLearn, Colors.orange),
              const SizedBox(height: 8),
              Text(profile.bio ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
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
              .map((e) => Chip(label: Text(e), backgroundColor: color, labelStyle: const TextStyle(color: Colors.white)))
              .toList(),
        ),
      ],
    );
  }
}