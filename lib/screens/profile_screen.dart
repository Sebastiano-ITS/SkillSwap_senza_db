import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Devi avere questi due import corretti nel tuo progetto
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  // Rimuoviamo il parametro 'userProfile' non necessario.
  // La screen deve solo sapere chi è l'utente corrente tramite Provider/Auth.
  const ProfileScreen({super.key});

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
            const Divider(height: 20),
            skills.isEmpty
                ? Text('Nessuna competenza selezionata.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600))
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: skills.map((skill) => Chip(
                label: Text(skill),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Otteniamo l'ID Utente corrente da FirestoreService (o AuthService se preferisci)
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUserId = firestoreService.currentUserId;

    // Se l'ID è nullo, c'è un errore grave nell'autenticazione.
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Errore: ID Utente non disponibile.'),
        ),
      );
    }

    // 2. Usiamo StreamBuilder per ascoltare i cambiamenti del profilo su Firestore
    return StreamBuilder<UserProfile?>(
      // Questo stream DEVE puntare alla collezione 'users' con l'ID Utente
      stream: firestoreService.streamUserProfile(currentUserId),
      builder: (context, snapshot) {

        // *GESTIONE DEL CARICAMENTO/ERRORE*
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Se ci sono errori o il documento è null
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Creiamo un profilo di fallback se il documento non esiste ancora in Firestore
          final fallbackProfile = UserProfile(
            userId: currentUserId,
            email: 'Non disponibile (DB)',
            name: 'Nuovo Utente (DB)',
            canTeach: [],
            wantsToLearn: [],
            onboardingCompleted: false,
          );

          // Eseguiamo il rendering della schermata con i dati di fallback.
          return _buildProfileContent(context, fallbackProfile);
        }

        // *DATI DISPONIBILI*
        final currentProfile = snapshot.data!;

        // 3. Eseguiamo il rendering del contenuto con i dati di Firestore
        return _buildProfileContent(context, currentProfile);
      },
    );
  }

  // Metodo separato per costruire il corpo dello schermo
  Widget _buildProfileContent(BuildContext context, UserProfile currentProfile) {
    // ** PUNTI CRITICI: Tutti i dati visualizzati provengono da currentProfile (Firestore) **
    final displayName = currentProfile.name.isEmpty ? 'Nome non impostato' : currentProfile.name;
    final displayEmail = currentProfile.email.isEmpty ? 'Email non disponibile' : currentProfile.email;
    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio Profilo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scheda Utente
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.deepPurple.shade200,
                      child: Text(
                        initialLetter,
                        style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          displayEmail,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _displayRate(currentProfile.hourlyRate),
                          style: TextStyle(fontSize: 16, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                        // Mostra l'UID di Firestore per debug/verifica
                        Text('ID: ${currentProfile.userId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
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
  }
}
