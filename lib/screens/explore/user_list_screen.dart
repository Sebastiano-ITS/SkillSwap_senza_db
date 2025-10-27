import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/local_data_service_explore.dart';
import '../../theme/brand_palette.dart';

class UserListScreen extends StatefulWidget {
  final String skill;
  const UserListScreen({super.key, required this.skill});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<UserProfile>> _filteredUsersFuture;
  final PageController _pageController = PageController();

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<List<UserProfile>>(
            future: _filteredUsersFuture,
            builder: (context, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) return Center(child: Text('Errore: ${s.error}'));
              if (!s.hasData || s.data!.isEmpty) return _buildEmptyState();

              final users = s.data!;
              return PageView.builder(
                controller: _pageController,
                itemCount: users.length,
                itemBuilder: (_, i) => UserProfileCard(user: users[i]),
              );
            },
          ),
          Positioned(
            top: 50,
            left: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(color: cs.surface.withOpacity(.6), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                color: cs.onSurface,
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text('Nessun esperto trovato', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Nessun utente al momento può insegnare "${widget.skill}". Prova un\'altra competenza!',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileCard extends StatefulWidget {
  final UserProfile user;
  const UserProfileCard({super.key, required this.user});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hasImage = (user.media?.isNotEmpty ?? false) && user.media!.first.startsWith('http');
    final hasBio = (user.bio ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: hasImage ? Colors.grey : BrandPalette.purple,
        image: hasImage ? DecorationImage(image: NetworkImage(user.media!.first), fit: BoxFit.cover) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          // gradient per leggibilità
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                stops: const [0.5, 1],
              ),
            ),
          ),
          if (!hasImage)
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: tt.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name}, ${user.age ?? ''}',
                    style: tt.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 2, color: Colors.black54)])),
                const SizedBox(height: 8),
                if (hasBio)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.bio!,
                        maxLines: _isBioExpanded ? 100 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      if (user.bio!.length > 100)
                        GestureDetector(
                          onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_isBioExpanded ? 'Mostra meno' : '...leggi altro',
                                style: tt.labelLarge?.copyWith(color: Colors.white, decoration: TextDecoration.underline)),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white54),
                const SizedBox(height: 16),
                _buildSkillsRow(context, 'Sa insegnare', user.canTeach, LucideIcons.zap, BrandPalette.amber),
                const SizedBox(height: 12),
                _buildSkillsRow(context, 'Vuole imparare', user.wantsToLearn, LucideIcons.bookOpen, BrandPalette.magenta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsRow(BuildContext context, String title, List<String> skills, IconData icon, Color iconColor) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: skills
                .map((s) => Chip(
              avatar: Icon(icon, color: iconColor, size: 16),
              label: Text(s),
              // lascia ChipTheme governare il resto (niente bg/labelStyle hardcoded)
            ))
                .toList(),
          )
        else
          Text('Nessuna competenza specificata', style: tt.bodySmall?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic)),
      ],
    );
  }
}
