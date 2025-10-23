// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar per dare un titolo e coerenza visiva alla schermata.
      appBar: AppBar(
        title: const Text(
          'Esplora',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Rimuove il pulsante "indietro" che potrebbe apparire
        automaticallyImplyLeading: false,
        // Puoi scegliere un colore specifico o usare quello del tema
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      // 2. Corpo della schermata con un messaggio centrale.
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona per rendere la pagina più gradevole
              Icon(
                LucideIcons.search,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              // Messaggio principale
              const Text(
                'Questa è la pagina di Explore',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Messaggio secondario che spiega cosa conterrà la pagina
              Text(
                'Qui potrai cercare nuovi utenti, competenze o categorie.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}