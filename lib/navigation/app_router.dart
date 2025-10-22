import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'onboarding_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  final String userId;
  const MainLayout({super.key, required this.userId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final int _currentIndex = 0;

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