// lib/screens/explore_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/explore_category.dart';
import '../../models/user_profile.dart';

class ExploreScreen extends StatefulWidget {
  final UserProfile currentUserProfile;
  const ExploreScreen({super.key, required this.currentUserProfile});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<InterestCategory> _categories = [];
  List<String> _suggestedInterests = []; // fallback se il profilo non ne ha
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExploreData();
  }

  Future<void> _loadExploreData() async {
    try {
      final String response =
      await rootBundle.loadString('assets/data/explore_data.json');
      final data = json.decode(response);

      final categories = (data['interest_categories'] as List)
          .map((item) => InterestCategory.fromJson(item))
          .toList();

      // Proviamo a leggere eventuali suggerimenti dal JSON
      final fallback = (data['default_interests'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          // Se il file non li ha, usiamo un minimo di default
          <String>['Fotografia', 'Inglese', 'Programmazione', 'Chitarra'];

      setState(() {
        _categories = categories;
        _suggestedInterests = fallback;
        _isLoading = false;
      });
    } catch (e) {
      // In caso di errore, mettiamo almeno delle card di default
      setState(() {
        _categories = [
          InterestCategory(
            title: 'Appassionati di Fotografia',
            description: 'Trova chi condivide la tua passione.',
            icon: 'fotografia',
            gradient: const [
              Color(0xFFFFC08A),
              Color(0xFFFF9A76),
            ],
          ),
          InterestCategory(
            title: 'Amanti delle Lingue',
            description: 'Connettiti con chi parla nuove lingue.',
            icon: 'lingue',
            gradient: const [
              Color(0xFF8DB3FF),
              Color(0xFFDA7BBE),
            ],
          ),
        ];
        _suggestedInterests = ['Fotografia', 'Inglese', 'Programmazione'];
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fotografia':
        return LucideIcons.camera;
      case 'lingue':
      case 'inglese':
      case 'francese':
      case 'spagnolo':
        return LucideIcons.languages;
      case 'musica':
        return LucideIcons.music;
      case 'cucina':
        return LucideIcons.chefHat;
      case 'programmazione':
        return LucideIcons.code2;
      case 'viaggiare':
        return LucideIcons.plane;
      default:
        return LucideIcons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Interessi dal profilo
    final myInterests = widget.currentUserProfile.wantsToLearn
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFB200),
              Color(0xFFEB5B00),
              Color(0xFFD91656),
              Color(0xFF640D5F)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        )
            : SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Esplora',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sezione 1 — categorie
                        const Text(
                          'Trova la tua community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) =>
                              _buildCategoryCard(_categories[index]),
                        ),
                        const SizedBox(height: 28),

                        // Sezione 2 — interessi del profilo o fallback
                        Text(
                          myInterests.isNotEmpty
                              ? 'Basato su cosa vuoi imparare'
                              : 'Suggeriti per te',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (myInterests.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: myInterests.length,
                              itemBuilder: (context, index) {
                                final interestName = myInterests[index];
                                return _buildMyInterestCard(interestName);
                              },
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _suggestedInterests.length,
                                  itemBuilder: (context, index) {
                                    final name =
                                    _suggestedInterests[index];
                                    return _buildMyInterestCard(name);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => context.go('/profile'),
                                icon: const Icon(
                                  LucideIcons.plusCircle,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Aggiungi interessi dal profilo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Evita “barra nera” aggiungendo spazio extra
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(InterestCategory category) {
    // es. "Appassionati di Fotografia" -> "Fotografia"
    final skillToSearch = category.title.split(' ').last;

    return GestureDetector(
      onTap: () => context.push('/explore/users_by_skill/$skillToSearch'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: category.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyInterestCard(String interestName) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/explore/users_by_skill/$interestName'),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIcon(interestName), color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                interestName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
