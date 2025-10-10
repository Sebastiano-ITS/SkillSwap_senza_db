import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  // L'userProfile iniziale serve solo come fallback e per ottenere l'ID utente
  final UserProfile userProfile;
  const ProfileScreen({super.key, required this.userProfile});

  // Funzione helper per visualizzare il rate correttamente
  String _displayRate(dynamic rate) {
    if (rate == null) return 'Non impostato';

    final rateValue = double.tryParse(rate.toString()) ?? 0.0;

    if (rateValue == 0.0) {
      return 'Gratis';
    }
    return '${rateValue.toStringAsFixed(2)} €';
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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

    // Usa StreamBuilder per ottenere il profilo più aggiornato da Firestore
    return StreamBuilder<UserProfile?>(
      stream: firestoreService.streamUserProfile(userProfile.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(message: 'Caricamento Profilo...');
        }

        // Se l'utente non esiste più o c'è un errore (improbabile qui)
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
                // TODO: Navigare alla schermata di Onboarding/Edit
                onPressed: () {
                  // Esempio di navigazione (dovrai definire OnboardingScreen se non l'hai già fatto)
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) => OnboardingScreen(
                  //     userId: currentProfile.userId,
                  //     name: currentProfile.name,
                  //     email: currentProfile.email,
                  //   ),
                  // ));
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
                // Sezione Foto e Informazioni Base
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
                      Text(
                        currentProfile.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentProfile.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 10),
                      
                      // Tariffa Oraria
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Tariffa Oraria: ${_displayRate(currentProfile.hourlyRate)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ID Utente (utile per debugging e per la sicurezza Firestore)
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
                        // CORREZIONE: Usiamo l'ID del profilo corrente
                        Text(currentProfile.userId, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Competenze da Insegnare
                _buildSkillsCard(
                  title: 'Cosa posso INSEGNARE',
                  skills: currentProfile.canTeach,
                  icon: LucideIcons.zap,
                  color: Colors.yellow.shade700,
                ),
                const SizedBox(height: 20),

                // Competenze da Imparare
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

// Aggiungo una semplice LoadingScreen per pulizia
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
