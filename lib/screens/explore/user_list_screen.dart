import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/local_data_service_explore.dart';

class UserListScreen extends StatefulWidget {
  final String skill;
  const UserListScreen({super.key, required this.skill});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserProfile>> _filteredUsersFuture;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final localDataService = Provider.of<LocalDataService>(context, listen: false);
    _filteredUsersFuture = localDataService.getUsersBySkill(widget.skill);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<List<UserProfile>>(
            future: _filteredUsersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Errore: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final users = snapshot.data!;
              return PageView.builder(
                controller: _pageController,
                itemCount: users.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  // Usiamo il nostro nuovo widget Stateful per ogni card
                  return UserProfileCard(user: users[index]);
                },
              );
            },
          ),
          // Pulsante Indietro sovrapposto
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                onPressed: () {
                  // Usa go_router per tornare indietro
                  context.pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget per quando non ci sono utenti
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'Nessun esperto trovato',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            Text(
              'Nessun utente al momento può insegnare "${widget.skill}". Prova a cercare un\'altra competenza!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET STATEFUL PER LA CARD DEL PROFILO ---
// Isola la logica di espansione della bio per ogni card

class UserProfileCard extends StatefulWidget {
  final UserProfile user;
  const UserProfileCard({super.key, required this.user});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  // Stato per gestire l'espansione della bio, specifico per questa card
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final bool hasImage = user.localImages.isNotEmpty && user.localImages.first.startsWith('http');
    final bool hasBio = user.bio != null && user.bio!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: hasImage ? Colors.grey : Colors.indigo.shade400,
        image: hasImage ? DecorationImage(image: NetworkImage(user.localImages.first), fit: BoxFit.cover) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          // Gradiente per la leggibilità del testo
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Avatar di fallback se non c'è immagine
          if (!hasImage)
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          // Contenuto testuale sovrapposto
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}, ${user.age ?? ''}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                ),
                const SizedBox(height: 8),
                // Logica "Leggi altro" per la bio
                if (hasBio)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.bio!,
                        maxLines: _isBioExpanded ? 100 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      // Mostra il pulsante solo se la bio è potenzialmente lunga
                      if (user.bio!.length > 100)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBioExpanded = !_isBioExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _isBioExpanded ? 'Mostra meno' : '...leggi altro',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white54),
                const SizedBox(height: 16),
                _buildSkillsRow('Sa insegnare', user.canTeach, LucideIcons.zap, Colors.yellow.shade600),
                const SizedBox(height: 12),
                _buildSkillsRow('Vuole imparare', user.wantsToLearn, LucideIcons.bookOpen, Colors.lightBlue.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper per mostrare le competenze
  Widget _buildSkillsRow(String title, List<String> skills, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        if (skills.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: skills.map((skill) => Chip(
              avatar: Icon(icon, color: iconColor, size: 16),
              label: Text(skill),
              backgroundColor: Colors.white.withOpacity(0.2),
              labelStyle: const TextStyle(color: Colors.black),
              side: BorderSide.none,
            )).toList(),
          )
        else
          Text('Nessuna competenza specificata', style: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic)),
      ],
    );
  }
}
