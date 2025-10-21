import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;
  const ProfileScreen({super.key, required this.userProfile});

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
                'Non hai ancora aggiunto nessuna competenza per ${title.toLowerCase()}.',
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
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.streamUserProfile(userProfile.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(message: 'Caricamento Profilo...');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Impossibile caricare i dati del profilo.'));
        }

        final currentProfile = snapshot.data!;

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
                      if (currentProfile.age != null)
                        Text('Età: ${currentProfile.age}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      if (currentProfile.bio != null && currentProfile.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            currentProfile.bio!,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('Il tuo ID Utente (UserId)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 5),
                        Text(currentProfile.userId, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
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
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  final String message;
  const LoadingScreen({super.key, this.message = "Caricamento..."});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(message),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      ),
    );
  }
}