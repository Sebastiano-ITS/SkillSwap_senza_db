import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  // Riceviamo userProfile iniziale, ma usiamo lo Stream per i dati aggiornati
  final UserProfile userProfile; 
  const ProfileScreen({super.key, required this.userProfile});

  // Funzione helper per visualizzare il rate correttamente
  String _displayRate(dynamic rate) {
    if (rate == null) return 'Non impostato';
    
    // Tenta il parsing a double, assumendo che i dati siano double (0.0 per Gratis)
    final rateValue = double.tryParse(rate.toString()) ?? 0.0; 
    
    if (rateValue == 0.0) {
      return 'Gratis';
    }
    // Mostra solo due decimali
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

  @override
  Widget build(BuildContext context) {
    // Ottiene il servizio Firestore tramite Provider
    final firestoreService = Provider.of<FirestoreService>(context);

    // Usa StreamBuilder per assicurare che il profilo sia sempre aggiornato
    return StreamBuilder<UserProfile?>(
      // L'ascolto deve avvenire sull'ID utente corretto
      stream: firestoreService.streamUserProfile(userProfile.userId), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Se il profilo è mancante o c'è un errore, usiamo il profilo iniziale come fallback
        final currentProfile = snapshot.data ?? userProfile;

        // Determina i dati da visualizzare
        final displayName = currentProfile.name.isEmpty ? 'Nome non impostato' : currentProfile.name;
        final displayEmail = currentProfile.email.isEmpty ? 'Email non disponibile' : currentProfile.email;
        final initialLetter = currentProfile.name.isNotEmpty ? currentProfile.name[0].toUpperCase() : 'U';


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
                          child: Text(initialLetter, style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 15),
                        Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(displayEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 10),
                        // Usa la funzione helper per formattare la tariffa
                        Text('Tariffa Oraria: ${_displayRate(currentProfile.hourlyRate)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                        const SizedBox(height: 5),
                        Text('ID Utente: ${currentProfile.userId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
