import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;
  const ProfileScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Profilo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Dettagli Base
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade500,
                      child: Text(userProfile.name.isNotEmpty ? userProfile.name[0] : 'U', style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),
                    Text(userProfile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(userProfile.email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text('Tariffa Oraria: ${userProfile.hourlyRate}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                    const SizedBox(height: 5),
                    Text('ID Utente: ${userProfile.userId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Competenze da Insegnare
            _buildSkillsCard(
              title: 'Cosa posso INSEGNARE',
              skills: userProfile.canTeach,
              icon: LucideIcons.zap,
              color: Colors.yellow.shade700,
            ),
            const SizedBox(height: 20),

            // Competenze da Imparare
            _buildSkillsCard(
              title: 'Cosa voglio IMPARARE',
              skills: userProfile.wantsToLearn,
              icon: LucideIcons.bookOpen,
              color: Colors.indigo.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard({required String title, required List<String> skills, required IconData icon, required Color color}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            skills.isEmpty
                ? const Text('Nessuna competenza inserita.', style: TextStyle(color: Colors.grey))
                : Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: skills.map((skill) => Chip(
                      label: Text(skill, style: TextStyle(color: color)),
                      backgroundColor: color.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
