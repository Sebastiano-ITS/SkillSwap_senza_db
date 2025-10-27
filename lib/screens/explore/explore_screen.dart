// lib/screens/explore_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/explore_category.dart';
import '../../models/user_profile.dart';
import 'package:go_router/go_router.dart';
import '../../theme/brand_palette.dart';

class ExploreScreen extends StatefulWidget {
  final UserProfile currentUserProfile;
  const ExploreScreen({super.key, required this.currentUserProfile});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<InterestCategory> _categories = [];
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
      final data = await json.decode(response);

      setState(() {
        _categories = (data['interest_categories'] as List)
            .map((item) => InterestCategory.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Errore nel caricamento di explore_data.json: $e");
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String iconName) {
    String lower = iconName.toLowerCase();
    switch (lower) {
      case 'fotografia':
        return LucideIcons.camera;
      case 'lingue':
        return LucideIcons.languages;
      case 'musica':
        return LucideIcons.music;
      case 'cucina':
        return LucideIcons.chefHat;
      case 'programmazione':
        return LucideIcons.code2;
      case 'viaggiare':
        return LucideIcons.plane;
      case 'spagnolo':
      case 'inglese':
      case 'francese':
        return LucideIcons.languages;
      default:
        return LucideIcons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> myInterests = widget.currentUserProfile.wantsToLearn;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
        Text('Esplora', style: tt.titleLarge?.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
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
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Sezione 1
                Text(
                  'Trova la tua community',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) =>
                      _buildCategoryCard(_categories[index]),
                ),
                const SizedBox(height: 32),

                // Sezione 2: interessi personali
                if (myInterests.isNotEmpty) ...[
                  Text(
                    'Basato su cosa vuoi imparare',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: myInterests.length,
                      itemBuilder: (context, index) {
                        final interestName = myInterests[index];
                        return _buildMyInterestCard(interestName);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(InterestCategory category) {
    final skillToSearch = category.title.split(' ').last;

    return GestureDetector(
      onTap: () {
        context.push('/explore/users_by_skill/$skillToSearch');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: category.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: BrandPalette.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_getIcon(category.icon), color: Colors.white, size: 32),
              const Spacer(),
              Text(
                category.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(0, 1))
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 13,
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: BrandPalette.glassBorder,
        boxShadow: BrandPalette.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/explore/users_by_skill/$interestName'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getIcon(interestName), color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                interestName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
