import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Shell principale dell'app, include una bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // Determina quale tab è selezionato in base al percorso attuale
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  // Gestisce il tap su un tab della bottom navigation
  void _onTabTapped(int index, BuildContext context) {
    final userProfile = context.read<AuthService>().getCurrentUserProfile();

    // Se non esiste un profilo utente loggato, non fa nulla
    if (userProfile == null) return;

    // Naviga alla pagina selezionata, passando il profilo utente come extra
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

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onTabTapped(index, context),
        type: BottomNavigationBarType.fixed,
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