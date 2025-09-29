import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

enum MatchMode { learn, teach }

class HomeScreen extends StatefulWidget {
  final UserProfile currentUserProfile;
  const HomeScreen({super.key, required this.currentUserProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MatchMode _matchMode = MatchMode.learn;

  // Logica di filtraggio per trovare gli utenti compatibili
  List<UserProfile> _filterUsers(List<UserProfile> allUsers) {
    final currentUserId = widget.currentUserProfile.userId;
    final otherUsers = allUsers.where((u) => u.userId != currentUserId).toList();

    return otherUsers.where((user) {
      if (_matchMode == MatchMode.learn) {
        // Modalità IMPARARE: cerco chi INSEGNA ciò che VOGLIO IMPARARE.
        final skillsNeeded = widget.currentUserProfile.wantsToLearn;
        final skillsOffered = user.canTeach;
        return skillsNeeded.any((skill) => skillsOffered.contains(skill));
      } else {
        // Modalità INSEGNARE: cerco chi VUOLE IMPARARE ciò che POSSO INSEGNARE.
        final skillsOffered = widget.currentUserProfile.canTeach;
        final skillsNeeded = user.wantsToLearn;
        return skillsOffered.any((skill) => skillsNeeded.contains(skill));
      }
    }).toList();
  }

  void _showContactMessage(UserProfile user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hai inviato una richiesta a ${user.name}! Inizia lo scambio di competenze.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: firestoreService.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Errore nel caricamento degli utenti.'));
          }

          final allUsers = snapshot.data!;
          final matchedUsers = _filterUsers(allUsers);

          return Column(
            children: [
              // Toggle Mode
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(
                      mode: MatchMode.learn,
                      icon: LucideIcons.bookOpen,
                      label: 'Voglio Imparare',
                    ),
                    const SizedBox(width: 16),
                    _buildModeButton(
                      mode: MatchMode.teach,
                      icon: LucideIcons.zap,
                      label: 'Voglio Insegnare',
                    ),
                  ],
                ),
              ),
              
              // Scheda Utente
              Expanded(
                child: matchedUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Nessun match trovato in modalità ${_matchMode == MatchMode.learn ? 'IMPARARE' : 'INSEGNARE'}.\nProva a cambiare le tue competenze nel Profilo.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : _buildUserCardStack(matchedUsers),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  // Costruisce il bottone per cambiare modalità
  Widget _buildModeButton({required MatchMode mode, required IconData icon, required String label}) {
    final isSelected = _matchMode == mode;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _matchMode = mode;
          });
        },
        icon: Icon(icon, color: isSelected ? Colors.white : (mode == MatchMode.learn ? Colors.indigo.shade600 : Colors.yellow.shade700)),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.indigo.shade600 : Colors.white,
          side: BorderSide(color: isSelected ? Colors.indigo.shade600 : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
  
  // Implementazione di una Stack che simula lo swipe (in questo caso, semplicemente mostra la prima carta)
  Widget _buildUserCardStack(List<UserProfile> users) {
    // Per semplicità, in Flutter mostriamo solo l'utente in cima e usiamo un bottone per "scartare"
    final user = users.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder per effetto stack
          if (users.length > 1)
            Positioned(
              top: 20,
              child: Opacity(
                opacity: 0.5,
                child: _UserCard(user: users[1]),
              ),
            ),
          
          _UserCard(user: user, onContact: () => _showContactMessage(user)),
        ],
      ),
    );
  }
}

// Widget separato per la scheda utente
class _UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onContact;

  const _UserCard({required this.user, this.onContact});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo.shade500,
              child: Text(user.name.isNotEmpty ? user.name[0] : 'U', style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            Text(
              user.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${user.userId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Competenze da Insegnare
            _buildSkillsSection(
              label: 'Può Insegnare',
              skills: user.canTeach,
              icon: LucideIcons.zap,
              color: Colors.yellow.shade700,
              bgColor: Colors.yellow.shade50,
            ),
            const SizedBox(height: 15),

            // Competenze che Vuole Imparare
            _buildSkillsSection(
              label: 'Vuole Imparare',
              skills: user.wantsToLearn,
              icon: LucideIcons.bookOpen,
              color: Colors.indigo.shade600,
              bgColor: Colors.indigo.shade50,
            ),
            const SizedBox(height: 25),

            Text(
              'Tariffa Oraria: ${user.hourlyRate}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade600),
            ),
            const SizedBox(height: 20),

            if (onContact != null)
              ElevatedButton.icon(
                onPressed: onContact,
                icon: const Icon(LucideIcons.phone, color: Colors.white),
                label: const Text('Contatta', style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection({required String label, required List<String> skills, required IconData icon, required Color color, required Color bgColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: skills.map((skill) => Chip(
            label: Text(skill, style: TextStyle(color: color)),
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          )).toList(),
        ),
      ],
    );
  }
}
