import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    // Reindirizza in base allo stato dell'utente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        context.go('/login');
      } else {
        context.go('/home');
      }
    });

    // Mostra uno spinner mentre si decide dove andare
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}