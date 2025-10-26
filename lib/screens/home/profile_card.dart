import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;
  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final ageText = p.age != null ? '${p.age}' : '-';
    final images = p.localImages;

    return Card(
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
                PageView.builder(
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
                if (p.canTeach.isNotEmpty)
                  Text('Skills: ${p.canTeach.join(', ')}'),
                if (p.wantsToLearn.isNotEmpty)
                  Text('Skills da imparare: ${p.wantsToLearn.join(', ')}'),
                const SizedBox(height: 8),
                Text(p.bio ?? 'Nessuna biografia disponibile.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}