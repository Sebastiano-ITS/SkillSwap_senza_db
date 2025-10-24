// lib/features/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart'; // Importa Provider
import '../services/auth_service.dart'; // Importa AuthService

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Funzione per calcolare l'indice del tab corrente in base alla rotta
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Default a Home
  }

  // Funzione chiamata quando un tab viene toccato
  void _onTabTapped(int index, BuildContext context) {
    // --- PASSO CHIAVE DELLA SOLUZIONE ---
    // 1. Recupera il profilo utente corrente da AuthService.
    final userProfile = context.read<AuthService>().getCurrentUserProfile();

    // 2. Se per qualche motivo il profilo non è disponibile, non fare nulla per sicurezza.
    if (userProfile == null) return;

    // 3. Naviga alla rotta corrispondente, passando SEMPRE l'utente come 'extra'.
    switch (index) {
      case 0:
        context.go('/home', extra: userProfile);
        break;
      case 1:
        context.go('/explore', extra: userProfile);
        break;
      case 2:
        context.go('/chat', extra: userProfile);
        break;
      case 3:
        context.go('/profile', extra: userProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onTabTapped(index, context),
        type: BottomNavigationBarType.fixed, // Mantiene i tab visibili
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'Esplora'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profilo'),
        ],
      ),
    );
  }
}