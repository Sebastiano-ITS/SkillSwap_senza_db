// lib/screens/home/profile_card.dart
import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile profile;
  const ProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final ageText = profile.age != null ? '${profile.age}' : '-';
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: profile.imageUrl.isNotEmpty
                      ? Image.network(profile.imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    '${profile.name}, $ageText',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
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
                Text('Skills: ${profile.canTeach.join(', ')}'),
                Text('Skills da imparare: ${profile.wantsToLearn.join(', ')}'),
                const SizedBox(height: 8),
                Text(profile.bio),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
