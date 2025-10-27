import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';

class ProfileInfo extends StatefulWidget {
  final UserProfile profile;
  const ProfileInfo({super.key, required this.profile});

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowCtrl;

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    // ✅ Prende prima location e distanceKm, poi i campi legacy se servono
    final city = profile.location ?? profile.city ?? 'Località sconosciuta';
    final distance = profile.distanceKm ?? profile.radiusKm;

    final distanceText =
    distance != null ? '${distance.toStringAsFixed(1)} km da te' : '';

    final age = profile.age != null ? ', ${profile.age}' : '';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Stack(
          children: [
            // Contenuto scrollabile
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Nome e età
                  Text(
                    '${profile.name}$age',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 📍 Città + distanza
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$city${distanceText.isNotEmpty ? " — $distanceText" : ""}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 🧠 Skills che può insegnare
                  if (profile.canTeach.isNotEmpty) ...[
                    const Text(
                      "Skills che può insegnare",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.canTeach
                          .map(
                            (e) => Chip(
                          label: Text(e),
                          backgroundColor: Colors.pinkAccent,
                          labelStyle:
                          const TextStyle(color: Colors.white),
                        ),
                      )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 🎯 Skills che vuole imparare
                  if (profile.wantsToLearn.isNotEmpty) ...[
                    const Text(
                      "Skills che vuole imparare",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: profile.wantsToLearn
                          .map(
                            (e) => Chip(
                          label: Text(e),
                          backgroundColor: Colors.orange,
                          labelStyle:
                          const TextStyle(color: Colors.white),
                        ),
                      )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 📜 Bio
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const Text(
                      "Bio",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),

            // ⬇️ Freccia animata (sempre visibile)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _arrowCtrl,
                  builder: (context, child) {
                    final offsetY = 4 * _arrowCtrl.value;
                    final opacity =
                        0.6 + 0.4 * (1 - (_arrowCtrl.value - 0.5).abs() * 2);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, offsetY),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black38,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}