import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'main_layout.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta lo stato dell'utente dallo StreamProvider
    final user = context.watch<User?>();

    // Se non c'è un utente autenticato, mostra la schermata di login
    if (user == null) {
      return const AuthScreen();
    }

    // Se l'utente è autenticato, mostra il layout principale
    return MainLayout(userId: user.uid);
  }
}