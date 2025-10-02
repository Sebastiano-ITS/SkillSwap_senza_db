import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necessario per il tipo User
import 'package:provider/provider.dart';
// Importa FirebaseOptions dal platform interface per evitare errori su alcune piattaforme web
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart' show FirebaseOptions;

import 'screens/auth_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

// --- Configurazione Firebase per Web/Flutter ---
// Questa configurazione è essenziale per l'inizializzazione corretta
const FirebaseOptions webDefaultOptions = FirebaseOptions(
    apiKey: "AIzaSyBUsnd5mGb50sGZR8JKP8pUTau5vWd2gNY",
    authDomain: "skillswap-9b65c.firebaseapp.com",
    projectId: "skillswap-9b65c",
    storageBucket: "skillswap-9b65c.firebasestorage.app",
    messagingSenderId: "476854991127",
    appId: "1:476854991127:web:a88a3ee55915a40bffdf52"
);
// ---------------------------------------------

void main() async {
  // Assicura che il binding del framework sia inizializzato prima di chiamate native
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inizializza Firebase con le opzioni specifiche per la piattaforma
    await Firebase.initializeApp(
      options: webDefaultOptions,
    );
    // print("Firebase è stato inizializzato con successo.");
  } catch (e) {
    // print("Errore nell'inizializzazione di Firebase: $e");
    // Puoi aggiungere una logica per mostrare un errore critico all'utente
  }

  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider per fornire tutti i servizi all'albero dei widget
    return MultiProvider(
      providers: [
        // CORREZIONE 1: Uso Provider standard per AuthService.
        // Cambia in ChangeNotifierProvider solo se AuthService estende ChangeNotifier.
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // 2. FirestoreService come Provider standard
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // 3. StreamProvider per tracciare lo stato di autenticazione di Firebase in tempo reale
        StreamProvider<User?>(
          // Usiamo context.read (anziché watch) poiché AuthService non è un ChangeNotifier qui.
          // context.read è sicuro perché il provider non cambia durante la creazione dello stream.
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
          catchError: (context, error) => null,
        ),
      ],
      child: MaterialApp(
        title: 'SkillSwap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          // CORREZIONE 2: Corretto da adaptivePlatformVersion a adaptivePlatformDensity
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: const Color(0xFFF5F5F9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF673AB7),
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple).copyWith(
            secondary: const Color(0xFFFF9800),
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta lo stato dell'utente dallo StreamProvider
    // Questo snapshot sarà null finché Firebase non emette il primo stato (utente o null)
    final firebaseUser = context.watch<User?>();

    // Non è più necessario ascoltare authService se non è un ChangeNotifier
    // final authService = context.watch<AuthService>();

    // MODIFICA CRITICA: Usiamo solo il valore di firebaseUser per determinare lo stato.
    // Il StreamProvider gestisce l'attesa iniziale (connectionState.waiting).
    if (firebaseUser == null) {
      // Se non abbiamo un utente E il provider è nel suo stato iniziale (null)
      // Dobbiamo distinguere tra "utente non loggato" e "ancora in caricamento".
      // Lo StreamProvider non ci fornisce lo stato di connessione qui, quindi usiamo un controllo temporaneo:

      final userSnapshot = context.watch<User?>();

      // Se userSnapshot è null, c'è un'ambiguità: è ancora in caricamento O non è loggato?
      // Per evitare il blocco, mostriamo il login e lasciamo che l'AuthService gestisca l'ascolto di stato.

      // ⚠️ La migliore pratica sarebbe usare StreamBuilder qui.
      // Dato che siamo vincolati al Provider, assumiamo un caricamento breve e mostriamo l'AuthScreen:
      return const AuthScreen();
    }

    // Se l'utente è autenticato (non è null), mostra il MainLayout
    if (firebaseUser != null) {
      return MainLayout(userId: firebaseUser.uid);
    }

    // Fallback: mostra la schermata di autenticazione/login
    return const AuthScreen();
  }
}
