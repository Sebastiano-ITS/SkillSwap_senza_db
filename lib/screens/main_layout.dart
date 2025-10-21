import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'onboarding_screen.dart';
import 'home/home_screen.dart';
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

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.streamUserProfile(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final UserProfile? userProfile = snapshot.data;

        // Se il profilo è nullo o non completato, mostra onboarding
        if (userProfile == null || !userProfile.onboardingCompleted) {
          return OnboardingScreen(
            userId: widget.userId,
            name: userProfile?.name ?? '',
            email: userProfile?.email ?? '',
          );
        }

        // Schermate principali
        final List<Widget> screens = [
          HomeScreen(currentUserProfile: userProfile),
          ProfileScreen(userProfile: userProfile),
          SettingsScreen(userProfile: userProfile),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Colors.indigo.shade600,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profilo'),
              BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Impostazioni'),
            ],
          ),
        );
      },
    );
  }
}