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
  int _currentCardIndex = 0; // Aggiunto per gestire lo scorrimento delle carte

  // Logica di filtraggio per trovare gli utenti compatibili (solo in modalità 'learn')
  List<UserProfile> _filterUsers(List<UserProfile> allUsers) {
    if (_matchMode == MatchMode.teach) {
      // In modalità 'teach' mostriamo le richieste, non filtriamo l'intera lista.
      // Questa funzione verrà chiamata solo in modalità 'learn'.
      return []; 
    }
    
    final currentUserId = widget.currentUserProfile.userId;
    // Filtriamo gli utenti in base alla corrispondenza delle competenze
    final otherUsers = allUsers
        .where((u) => u.userId != currentUserId && u.onboardingCompleted)
        .toList();

    return otherUsers.where((user) {
      // Modalità IMPARARE: cerco chi INSEGNA ciò che VOGLIO IMPARARE.
      final skillsNeeded = widget.currentUserProfile.wantsToLearn;
      final skillsOffered = user.canTeach;
      return skillsNeeded.any((skill) => skillsOffered.contains(skill));
    }).toList();
  }

  // LOGICA TEMPORANEA PER LE RICHIESTE (solo per simulazione)
  // In una vera app, questo sarebbe uno Stream/Future Builder su una collezione Firestore 'requests'
  List<Map<String, dynamic>> _getReceivedRequests() {
    if (_matchMode == MatchMode.learn) return [];
    
    // Dati fittizi per la modalità 'Voglio Insegnare' (Richieste Ricevute)
    return [
      {'name': 'Giulia Rossi', 'skill': 'Web Design (Figma)', 'message': 'Posso pagare 15/ora per 4 lezioni di base.'},
      {'name': 'Marco Bianchi', 'skill': 'Programmazione Dart', 'message': 'Ho bisogno di aiuto urgente sulla sintassi asincrona.'},
      {'name': 'Anna Verdi', 'skill': 'Lingua Inglese (C1)', 'message': 'Sono libera tutti i lunedì sera per conversazione.'},
    ];
  }
  // FINE LOGICA TEMPORANEA

  void _showContactMessage(UserProfile user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Richiesta inviata a ${user.name}! Lo scambio può iniziare.'),
        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Simula lo scorrimento alla prossima carta
    _goToNextCard();
  }
  
  void _goToNextCard() {
    setState(() {
      _currentCardIndex = _currentCardIndex + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
                  icon: LucideIcons.inbox, // Icona cambiata per le richieste
                  label: 'Richieste Ricevute', // Label cambiata
                ),
              ],
            ),
          ),
          
          // Contenuto Dinamico
          Expanded(
            child: _matchMode == MatchMode.learn
                ? _buildMatchingView(firestoreService) // Mostra le carte
                : _buildRequestsView(), // Mostra le richieste
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Widget per la Visualizzazione delle Carte Match (Modalità Learn) ---
  Widget _buildMatchingView(FirestoreService firestoreService) {
    return StreamBuilder<List<UserProfile>>(
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
        
        // Assicurati che l'indice corrente sia valido
        if (_currentCardIndex >= matchedUsers.length && matchedUsers.isNotEmpty) {
          _currentCardIndex = 0;
        }

        final usersToShow = matchedUsers.skip(_currentCardIndex).toList();

        if (usersToShow.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Nessun insegnante trovato in base alle tue competenze richieste. Aggiorna il tuo profilo!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        // Costruisci lo Stack delle carte
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Carta successiva (sfocata sotto)
              if (usersToShow.length > 1)
                Positioned(
                  top: 30,
                  left: 10,
                  right: 10,
                  child: Opacity(
                    opacity: 0.7,
                    child: _UserCard(user: usersToShow[1], onContact: null, onSkip: null),
                  ),
                ),
              
              // Carta in cima (interagibile)
              _UserCard(
                user: usersToShow.first, 
                onContact: () => _showContactMessage(usersToShow.first),
                onSkip: _goToNextCard, // Funzione per scartare
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- Widget per la Visualizzazione delle Richieste (Modalità Teach) ---
  Widget _buildRequestsView() {
    final requests = _getReceivedRequests(); // Ottieni le richieste fittizie

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.mail, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                'Nessuna richiesta di apprendimento ricevuta per le tue competenze. Condividi le tue abilità!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          name: request['name'],
          skill: request['skill'],
          message: request['message'],
        );
      },
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
            _currentCardIndex = 0; // Resetta l'indice quando si cambia modalità
          });
        },
        icon: Icon(icon, color: isSelected ? Colors.white : (mode == MatchMode.learn ? Colors.indigo.shade600 : Colors.deepOrange)),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.indigo.shade600 : Colors.white,
          side: BorderSide(color: isSelected ? Colors.indigo.shade600 : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: isSelected ? 4 : 1,
        ),
      ),
    );
  }
}

// Widget separato per la SCHEDA UTENTE (Modalità Learn)
class _UserCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback? onContact;
  final VoidCallback? onSkip;

  const _UserCard({required this.user, this.onContact, this.onSkip});

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
        if (skills.isEmpty)
          Text('Nessuna competenza selezionata.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
        
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.indigo.shade500,
                child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Text(
                user.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildSkillsSection(
                label: 'Può Insegnare',
                skills: user.canTeach,
                icon: LucideIcons.zap,
                color: Colors.yellow.shade700,
                bgColor: Colors.yellow.shade50,
              ),
              const SizedBox(height: 15),

              _buildSkillsSection(
                label: 'Vuole Imparare',
                skills: user.wantsToLearn,
                icon: LucideIcons.bookOpen,
                color: Colors.indigo.shade600,
                bgColor: Colors.indigo.shade50,
              ),
              const SizedBox(height: 25),

              Text(
                'Tariffa Oraria Stimata: €${user.hourlyRate.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade600),
              ),
              const SizedBox(height: 20),

              if (onContact != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSkip,
                        icon: Icon(LucideIcons.x, color: Colors.red.shade400),
                        label: Text('Scarta', style: TextStyle(color: Colors.red.shade400, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onContact,
                        icon: const Icon(LucideIcons.send, color: Colors.white),
                        label: const Text('Contatta', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade500,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget separato per la SCHEDA RICHIESTA (Modalità Teach)
class _RequestCard extends StatelessWidget {
  final String name;
  final String skill;
  final String message;

  const _RequestCard({
    required this.name,
    required this.skill,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.user, size: 20, color: Color(0xFFFF9800)),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                ),
              ],
            ),
            const Divider(height: 15, thickness: 0.5),
            Text(
              'Vuole Imparare: $skill',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.indigo.shade600),
            ),
            const SizedBox(height: 10),
            Text(
              'Messaggio: "$message"',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementa logica per accettare / aprire la chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hai accettato la richiesta di $name!'), backgroundColor: Colors.deepPurple),
                    );
                  },
                  icon: const Icon(LucideIcons.messageSquare, size: 18),
                  label: const Text('Accetta e Contatta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}