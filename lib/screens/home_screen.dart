import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../models/match_request.dart'; // IMPORT NECESSARIO

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

  void _goToNextCard() {
    setState(() {
      _currentCardIndex = _currentCardIndex + 1;
    });
  }

  // FUNZIONE: Mostra il dialogo di contatto/invio richiesta
  void _showContactDialog(UserProfile receiver, FirestoreService firestoreService) {
    final TextEditingController messageController = TextEditingController();
    String? selectedSkill;
    
    // Trova le skill comuni che l'utente corrente vuole imparare e il ricevente insegna
    final commonSkills = widget.currentUserProfile.wantsToLearn
        .where((skill) => receiver.canTeach.contains(skill))
        .toList();
    
    // Se non ci sono skill in comune (non dovrebbe accadere se il filtro funziona bene, ma per sicurezza)
    if (commonSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna competenza in comune per l\'invio della richiesta.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Contatta ${receiver.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleziona la competenza che vuoi imparare:'),
                const SizedBox(height: 10),
                // Usiamo uno StatefulBuilder per gestire il cambio di stato nel Dropdown
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Scegli una skill'),
                      value: selectedSkill,
                      items: commonSkills.map((skill) => DropdownMenuItem(
                        value: skill,
                        child: Text(skill),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() { // Aggiorna lo stato del dialogo
                          selectedSkill = value;
                        });
                      },
                    );
                  }
                ),
                const SizedBox(height: 20),
                const Text('Messaggio (opzionale):'),
                TextFormField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ciao! Mi piacerebbe imparare X. Sei disponibile?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedSkill == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devi selezionare una competenza!')),
                  );
                  return;
                }
                
                final request = MatchRequest(
                  id: '', 
                  senderId: widget.currentUserProfile.userId,
                  senderName: widget.currentUserProfile.name,
                  receiverId: receiver.userId,
                  skillRequested: selectedSkill!,
                  message: messageController.text.trim(),
                  timestamp: DateTime.now(),
                );
                
                try {
                  // CHIAMATA AL NUOVO METODO sendMatchRequest
                  await firestoreService.sendMatchRequest(request);
                  
                  // Chiudi il dialogo, vai alla carta successiva e mostra il feedback
                  Navigator.of(context).pop();
                  _goToNextCard(); 
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Richiesta inviata a ${receiver.name} per ${selectedSkill}!'),
                      backgroundColor: Colors.green.shade500,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  // Gestione degli errori
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Errore nell\'invio della richiesta: ${e.toString()}'),
                      backgroundColor: Colors.red.shade500,
                    ),
                  );
                }
              },
              child: const Text('Invia Richiesta'),
            ),
          ],
        );
      },
    );
  }

  // FUNZIONE: Gestione dell'accettazione della richiesta
  void _acceptRequest(MatchRequest request, FirestoreService firestoreService) async {
    try {
      // CHIAMATA AL NUOVO METODO updateRequestStatus
      await firestoreService.updateRequestStatus(request.id, true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hai accettato la richiesta da ${request.senderName} per ${request.skillRequested}! Ora puoi contattarlo/a.'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'accettare la richiesta: ${e.toString()}'),
          backgroundColor: Colors.red.shade500,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Ottieni il servizio Firestore tramite Provider
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
                  icon: LucideIcons.inbox, 
                  label: 'Richieste Ricevute',
                ),
              ],
            ),
          ),
          
          // Contenuto Dinamico
          Expanded(
            child: _matchMode == MatchMode.learn
                ? _buildMatchingView(firestoreService) // Mostra le carte
                : _buildRequestsView(firestoreService), // Mostra le richieste
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
          _currentCardIndex = 0; // Torna alla prima carta
        }

        final usersToShow = matchedUsers.skip(_currentCardIndex).toList();

        if (usersToShow.isEmpty) {
          // CORREZIONE QUI: Chiusura del widget Text con ")"
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Nessun insegnante trovato in base alle tue competenze richieste. Aggiorna il tuo profilo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ), // Chiusura corretta
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
                onContact: () => _showContactDialog(usersToShow.first, firestoreService),
                onSkip: _goToNextCard, // Funzione per scartare
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- Widget per la Visualizzazione delle Richieste (Modalità Teach) ---
  Widget _buildRequestsView(FirestoreService firestoreService) {
    final currentUserId = widget.currentUserProfile.userId;

    return StreamBuilder<List<MatchRequest>>(
      // CHIAMATA REALISTICA AL DB: usa il nuovo metodo streamReceivedRequests
      stream: firestoreService.streamReceivedRequests(currentUserId), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Errore nel caricamento delle richieste: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? []; // Ottieni la lista di MatchRequest

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
              request: request, 
              // Passa la funzione di accettazione
              onAccept: () => _acceptRequest(request, firestoreService),
            );
          },
        );
      },
    );
  }

  // Costruisce il bottone per cambiare modalità
  Widget _buildModeButton({required MatchMode mode, required IconData icon, required String label}) {
    final isSelected = _matchMode == mode;
    final color = mode == MatchMode.learn ? Colors.indigo.shade600 : Colors.deepOrange;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _matchMode = mode;
            _currentCardIndex = 0; // Resetta l'indice quando si cambia modalità
          });
        },
        icon: Icon(icon, color: isSelected ? Colors.white : color),
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
  final MatchRequest request; 
  final VoidCallback onAccept;

  const _RequestCard({
    required this.request,
    required this.onAccept,
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
                  request.senderName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333)),
                ),
                const Spacer(),
                Text(
                  // Formattazione della data
                  'Inviata il: ${request.timestamp.day}/${request.timestamp.month}/${request.timestamp.year.toString().substring(2)}', 
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                )
              ],
            ),
            const Divider(height: 15, thickness: 0.5),
            Text(
              'Richiesta per: ${request.skillRequested}', 
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.indigo.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              request.message.isNotEmpty 
                ? 'Messaggio: "${request.message}"' 
                : 'L\'utente non ha lasciato un messaggio.',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onAccept, // Chiama la funzione che usa updateRequestStatus
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
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
