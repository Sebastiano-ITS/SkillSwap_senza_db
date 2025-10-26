import 'package:flutter/material.dart';
import 'dart:math';

import '../../models/user_profile.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;
  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  late AnimationController _controller;
  late Animation<Offset> _animation;

  Offset _dragOffset = Offset.zero;
  final double _swipeThreshold = 150;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final double dragDistance = _dragOffset.dx;

    if (dragDistance.abs() > _swipeThreshold) {
      final screenWidth = MediaQuery.of(context).size.width;
      final direction = dragDistance.sign;

      _animation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset(direction * screenWidth, _dragOffset.dy),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward(from: 0).whenComplete(() {
        // Qui puoi triggerare rimozione card via bloc
      });
    } else {
      _animation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final ageText = p.age != null ? '${p.age}' : '-';
    final images = p.localImages;

    return Transform.translate(
      offset: _dragOffset,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: images.isEmpty
                    ? const ColoredBox(color: Colors.grey)
                    : Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(details.globalPosition);
                        final width = box.size.width;

                        if (localPosition.dx < width / 2) {
                          // Tap sinistro → pagina precedente
                          if (_pageCtrl.hasClients && _pageCtrl.page! > 0) {
                            _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        } else {
                          // Tap destro → pagina successiva
                          if (_pageCtrl.hasClients && _pageCtrl.page! < images.length - 1) {
                            _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: images.length,
                        itemBuilder: (_, i) {
                          final path = images[i];
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
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                              (i) => AnimatedBuilder(
                            animation: _pageCtrl,
                            builder: (_, __) {
                              double page = 0;
                              if (_pageCtrl.hasClients && _pageCtrl.page != null) {
                                page = _pageCtrl.page!;
                              }
                              final isActive = (page.round() == i);
                              return Container(
                                width: isActive ? 10 : 8,
                                height: isActive ? 10 : 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white : Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${p.name}, $ageText',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.canTeach.isNotEmpty) Text('Skills: ${p.canTeach.join(', ')}'),
                    if (p.wantsToLearn.isNotEmpty) Text('Skills da imparare: ${p.wantsToLearn.join(', ')}'),
                    const SizedBox(height: 8),
                    Text(p.bio ?? 'Nessuna biografia disponibile.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}