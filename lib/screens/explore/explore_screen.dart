// lib/screens/explore_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/explore_category.dart';
import '../../models/user_profile.dart'; // <-- 1. Importa il modello UserProfile
import 'package:go_router/go_router.dart'; // Importa go_router


class ExploreScreen extends StatefulWidget {
  // 2. Aggiungi il profilo utente come parametro richiesto
  final UserProfile currentUserProfile;
  const ExploreScreen({super.key, required this.currentUserProfile});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<InterestCategory> _categories = [];
  // Rimuoviamo _myInterests, non ci serve più
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExploreData();
  }

  // Funzione per caricare e parsare i dati dal file JSON
  Future<void> _loadExploreData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/explore_data.json');
      final data = await json.decode(response);

      setState(() {
        _categories = (data['interest_categories'] as List)
            .map((item) => InterestCategory.fromJson(item))
            .toList();
        // Non carichiamo più 'my_interests' da qui
        _isLoading = false;
      });
    } catch (e) {
      print("Errore nel caricamento di explore_data.json: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funzione helper per ottenere l'icona corretta in base alla stringa
  IconData _getIcon(String iconName) {
    // Convertiamo il nome dell'interesse in minuscolo per un matching più robusto
    String lowerCaseIconName = iconName.toLowerCase();
    switch (lowerCaseIconName) {
      case 'fotografia': return LucideIcons.camera;
      case 'lingue': return LucideIcons.languages;
      case 'musica': return LucideIcons.music;
      case 'cucina': return LucideIcons.chefHat;
      case 'programmazione': return LucideIcons.code2;
      case 'viaggiare': return LucideIcons.plane;
      case 'spagnolo': return LucideIcons.languages;
      case 'inglese': return LucideIcons.languages;
      case 'francese': return LucideIcons.languages;
    // Aggiungi altre associazioni se necessario
      default: return LucideIcons.star; // Icona di default
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Accedi alla lista wantsToLearn direttamente dal profilo dell'utente
    final List<String> myInterests = widget.currentUserProfile.wantsToLearn;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFB200), Color(0xFFEB5B00), Color(0xFFD91656), Color(0xFF640D5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esplora',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5.0, color: Colors.black26, offset: Offset(0, 2))]
                  ),
                ),
                const SizedBox(height: 24),

                // Sezione 1: Card per Categorie di Interessi (invariata)
                const Text(
                  'Trova la tua community',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
                ),
                const SizedBox(height: 32),

                // --- Sezione 2: Card per i Tuoi Interessi (MODIFICATA) ---
                if (myInterests.isNotEmpty) ...[
                  const Text(
                    'Basato su cosa vuoi imparare',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      // 4. Usa la lunghezza della lista di interessi dell'utente
                      itemCount: myInterests.length,
                      itemBuilder: (context, index) {
                        // 5. Prendi l'interesse dalla lista dell'utente
                        final interestName = myInterests[index];
                        return _buildMyInterestCard(interestName);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(InterestCategory category) {

    // Associamo il titolo della card alla skill effettiva (es. "Appassionati di Fotografia" -> "Fotografia")
    final skillToSearch = category.title.split(' ').last;

    // ... questo widget rimane invariato ...
    return GestureDetector(
      onTap: () {
        // Naviga alla nuova schermata passando la skill come parametro nella URL
        context.push('/explore/users_by_skill/$skillToSearch');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: category.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_getIcon(category.icon), color: Colors.white, size: 30),
              const Spacer(),
              Text(
                category.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Modifica questo widget per accettare una semplice stringa
  Widget _buildMyInterestCard(String interestName) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)
      ),
      child: InkWell(
        onTap: () {
          // Usa context.push per navigare alla lista di utenti che possono insegnare questo interesse.
          // Il comportamento è ora identico a quello delle card delle categorie.
          context.push('/explore/users_by_skill/$interestName');
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(interestName), color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              interestName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}