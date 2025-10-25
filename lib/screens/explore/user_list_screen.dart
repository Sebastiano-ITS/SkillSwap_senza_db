// lib/screens/user_list_screen.dart
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

  // Funzione per animare lo swipe alla pagina successiva
  void _swipeNext() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usiamo uno Stack per sovrapporre il pulsante "indietro" al contenuto
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
                  return _buildUserProfileCard(users[index]);
                },
              );
            },
          ),
          // --- Pulsante Indietro ---
          // Posizionato in alto a sinistra sopra tutto il resto
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

  // Widget per la card del profilo utente
  Widget _buildUserProfileCard(UserProfile user) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: DecorationImage(
          // Placeholder per un'immagine di profilo, puoi sostituirla
          image: NetworkImage('https://picsum.photos/seed/${user.id}/800/1200'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.name}, ${user.age}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 8),
              if (user.bio != null && user.bio!.isNotEmpty)
                Text(
                  user.bio!, // Usiamo '!' perché abbiamo già controllato che non sia null
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
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
      ),
    );
  }

  // Widget per mostrare le competenze
  Widget _buildSkillsRow(String title, List<String> skills, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
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
        ),
      ],
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