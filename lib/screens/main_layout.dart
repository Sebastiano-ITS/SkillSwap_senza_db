import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  final String userId;
  const MainLayout({super.key, required this.userId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // StreamBuilder per caricare il profilo e decidere se mostrare l'onboarding
    return StreamBuilder<UserProfile?>(
      stream: firestoreService.streamUserProfile(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final UserProfile? userProfile = snapshot.data;

        // Caso 1: Profilo non trovato o non completo -> Onboarding
        if (userProfile == null || (userProfile.canTeach.isEmpty && userProfile.wantsToLearn.isEmpty)) {
          return OnboardingScreen(
            userId: widget.userId,
            name: userProfile?.name ?? 'Nuovo Utente',
            email: userProfile?.email ?? '',
          );
        }

        // Caso 2: Profilo completo -> Layout Principale con TabBar
        final List<Widget> children = [
          HomeScreen(currentUserProfile: userProfile),
          // ProfileScreen NON richiede userProfile (si auto-carica)
          const ProfileScreen(),
          // *** CORREZIONE: SettingsScreen richiede userProfile ***
          SettingsScreen(userProfile: userProfile),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: children,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.indigo.shade600,
            unselectedItemColor: Colors.grey.shade500,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.user),
                label: 'Profilo',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}