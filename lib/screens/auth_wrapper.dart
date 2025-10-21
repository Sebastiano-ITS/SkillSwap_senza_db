// auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// Sostituisci con le tue schermate effettive
import '../screens/login_screen.dart';
import '../screens/home/home_screen.dart'; // Assicurati che il percorso sia corretto

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Ascolta le modifiche sull'istanza di AuthService.
    //    Ogni volta che chiami notifyListeners() in AuthService, questo widget si ricostruirà.
    final authService = context.watch<AuthService>();

    // 2. In base alla proprietà 'isLoggedIn', mostra la schermata corretta.
    if (authService.isLoggedIn) {
      // Se l'utente è loggato, mostra la schermata Home.
      return HomeScreen(currentUserProfile: authService.currentUser!);
    } else {
      // Altrimenti, mostra la schermata di Login.
      return const LoginScreen();
    }
  }
}