import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skillswap/screens/home/profile_info.dart';
import '../../../models/user_profile.dart';
import 'profile_card_animator.dart';
import 'profile_image_gallery.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final bool isTopCard;
  final Function(UserProfile) onSwipeRight;
  final Function(UserProfile) onSwipeLeft;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.isTopCard,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  static const double _likeThreshold = 150;
  static const double _overlayThreshold = 100;
  static const double _maxRotation = 0.35;

  Offset _offset = Offset.zero;
  String? _overlay; // 'like' | 'nope'
  bool _imageScrolling = false;

  late final ProfileCardAnimator _animator;

  @override
  void initState() {
    super.initState();
    _animator = ProfileCardAnimator(vsync: this, onUpdate: (value) {
      if (mounted) setState(() => _offset = value);
    });
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  void _onSwipeEnd() {
    if (_offset.dx > _likeThreshold) {
      widget.onSwipeRight(widget.profile);
      HapticFeedback.lightImpact();
      _resetCard();
    } else if (_offset.dx < -_likeThreshold) {
      widget.onSwipeLeft(widget.profile);
      HapticFeedback.lightImpact();
      _resetCard();
    } else {
      setState(() => _overlay = null);
      _animator.springBack(from: _offset);
    }
  }

  void _resetCard() {
    setState(() {
      _overlay = null;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.9;
    final double cardHeight = size.height * 0.75;

    final double angle = widget.isTopCard
        ? (_offset.dx / 300).clamp(-_maxRotation, _maxRotation)
        : 0;

    return IgnorePointer(
      ignoring: !widget.isTopCard,
      child: Transform.translate(
        offset: widget.isTopCard ? _offset : Offset.zero,
        child: Transform.rotate(
          angle: angle,
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onPanStart: widget.isTopCard ? (_) => _animator.stop() : null,
            onPanUpdate: widget.isTopCard
                ? (details) {
              if (_imageScrolling) return;
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
            onPanEnd: widget.isTopCard ? (_) => _onSwipeEnd() : null,
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
                  ProfileImageGallery(
                    images: widget.profile.localImages,
                    onScrolling: (scrolling) =>
                        setState(() => _imageScrolling = scrolling),
                  ),
                  ProfileInfo(profile: widget.profile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}