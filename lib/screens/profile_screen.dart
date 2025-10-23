// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';

// Rimuoviamo le dipendenze da Firestore e Provider perché non le usiamo in questa versione
// import 'package:provider/provider.dart';
// import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  // Riceve i dati dell'utente direttamente dal router
  final UserProfile userProfile;
  const ProfileScreen({super.key, required this.userProfile});

  // Widget helper per mostrare le card delle competenze
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
            const Divider(height: 25, thickness: 1),
            if (skills.isEmpty)
              Text(
                'Nessuna competenza aggiunta.',
                style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: skills.map((skill) => Chip(
                  label: Text(skill, style: TextStyle(color: color)),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.5)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo direttamente l'oggetto 'userProfile' passato al widget.
    // Non c'è più bisogno di StreamBuilder o Provider.
    final currentProfile = userProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProfile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funzione Modifica Profilo non ancora implementata.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.indigo.shade500,
                    child: Text(
                      currentProfile.name.isNotEmpty ? currentProfile.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(currentProfile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(currentProfile.email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  if (currentProfile.age != null && currentProfile.age! > 0)
                    Text('Età: ${currentProfile.age}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  if (currentProfile.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        currentProfile.bio,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSkillsCard(
              title: 'Cosa posso INSEGNARE',
              skills: currentProfile.canTeach,
              icon: LucideIcons.zap,
              color: Colors.yellow.shade700,
            ),
            const SizedBox(height: 20),
            _buildSkillsCard(
              title: 'Cosa voglio IMPARARE',
              skills: currentProfile.wantsToLearn,
              icon: LucideIcons.bookOpen,
              color: Colors.indigo.shade600,
            ),
          ],
        ),
      ),
    );
  }
}