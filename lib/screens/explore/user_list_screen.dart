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
    final localDataService =
    Provider.of<LocalDataService>(context, listen: false);
    _filteredUsersFuture = localDataService.getUsersBySkill(widget.skill);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandPalette.amber,
              BrandPalette.orange,
              BrandPalette.magenta,
              BrandPalette.purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            FutureBuilder<List<UserProfile>>(
              future: _filteredUsersFuture,
              builder: (context, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                if (s.hasError) {
                  return Center(
                    child: Text(
                      'Errore: ${s.error}',
                      style:
                      tt.titleMedium?.copyWith(color: Colors.white70),
                    ),
                  );
                }
                if (!s.hasData || s.data!.isEmpty) return _buildEmptyState();

                final users = s.data!;
                return PageView.builder(
                  controller: _pageController,
                  itemCount: users.length,
                  itemBuilder: (_, i) => UserProfileCard(user: users[i]),
                );
              },
            ),

            // 🔙 Pulsante indietro glass
            Positioned(
              top: 48,
              left: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                  boxShadow: BrandPalette.softShadow,
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            // Titolo in alto
            Positioned(
              top: 56,
              right: 0,
              left: 0,
              child: Center(
                child: Text(
                  widget.skill,
                  style: tt.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(blurRadius: 3, color: Colors.black45)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            const Icon(LucideIcons.users,
                size: 90, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              'Nessun esperto trovato',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nessun utente al momento può insegnare "${widget.skill}".\nProva un\'altra competenza!',
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: Colors.white70, height: 1.4),
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

    final hasImage = user.media.isNotEmpty && user.media.first.isNotEmpty;
    final hasBio = (user.bio ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.08),
        image: hasImage
            ? DecorationImage(
          image: user.media.first.startsWith('http')
              ? NetworkImage(user.media.first)
              : AssetImage(user.media.first) as ImageProvider,
          fit: BoxFit.cover,
        )
            : null,
        boxShadow: BrandPalette.softShadow,
      ),
      child: Stack(
        children: [
          // sfumatura per leggibilità
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.5, 1],
              ),
            ),
          ),

          if (!hasImage)
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?',
                  style: tt.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // info utente
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}${user.age != null ? ', ${user.age}' : ''}',
                  style: tt.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(blurRadius: 3, color: Colors.black54)
                    ],
                  ),
                ),
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
                          onTap: () =>
                              setState(() => _isBioExpanded = !_isBioExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _isBioExpanded
                                  ? 'Mostra meno'
                                  : '...leggi altro',
                              style: tt.labelLarge?.copyWith(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white54, height: 1),
                const SizedBox(height: 16),
                _buildSkillsRow(
                  context,
                  'Sa insegnare',
                  user.canTeach,
                  LucideIcons.zap,
                  BrandPalette.amber,
                ),
                const SizedBox(height: 12),
                _buildSkillsRow(
                  context,
                  'Vuole imparare',
                  user.wantsToLearn,
                  LucideIcons.bookOpen,
                  BrandPalette.magenta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsRow(
      BuildContext context,
      String title,
      List<String> skills,
      IconData icon,
      Color iconColor,
      ) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: skills
                .map(
                  (s) => Chip(
                backgroundColor: Colors.white.withOpacity(0.15),
                side: BorderSide(color: Colors.white.withOpacity(0.4)),
                avatar: Icon(icon, color: iconColor, size: 16),
                label: Text(
                  s,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
                .toList(),
          )
        else
          Text(
            'Nessuna competenza specificata',
            style: tt.bodySmall?.copyWith(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
