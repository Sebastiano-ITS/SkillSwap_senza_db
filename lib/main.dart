import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NECESSARIO per il tipo User
import 'package:provider/provider.dart';
// Devi aggiungere questo import per usare FirebaseOptions
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart' show FirebaseOptions;

import 'screens/auth_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

// Definizione della configurazione per Flutter Web
// Questa configurazione è specifica per il tuo ambiente di test.
const FirebaseOptions webDefaultOptions = FirebaseOptions(
    apiKey: "AIzaSyBUsnd5mGb50sGZR8JKP8pUTau5vWd2gNY",
    authDomain: "skillswap-9b65c.firebaseapp.com",
    projectId: "skillswap-9b65c",
    storageBucket: "skillswap-9b65c.firebasestorage.app",
    messagingSenderId: "476854991127",
    appId: "1:476854991127:web:a88a3ee55915a40bffdf52"
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  //  PUNTO CHIAVE: INIZIALIZZAZIONE FIREBASE CORRETTA
  // ------------------------------------------------------------------
  try {
    // Inizializza Firebase usando l'oggetto options corretto
    await Firebase.initializeApp(
      options: webDefaultOptions,
    );

    print("Firebase è stato inizializzato con successo.");
  } catch (e) {
    print("Errore nell'inizializzazione di Firebase: $e");
    // Gestisci l'errore o notifica l'utente
  }
  // ------------------------------------------------------------------

  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Fornisce l'istanza di AuthService
        // AuthService non deve essere un ChangeNotifier se usi lo StreamProvider
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // 2. Fornisce l'istanza di FirestoreService
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // 3. Ascolta lo stato dell'utente (login/logout)
        // Questo è il modo standard e pulito di usare Provider con Firebase Auth.
        StreamProvider<User?>(
          // L'AuthService deve esporre uno stream chiamato userStream
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
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: const Color(0xFFF5F5F9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF673AB7), // Viola scuro
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple).copyWith(
            secondary: const Color(0xFFFF9800), // Arancione (Accent Color)
          ),
          fontFamily: 'Inter',
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Wrapper per decidere se mostrare la schermata di Auth o il MainLayout
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Legge lo stato dell'utente dallo StreamProvider in modo reattivo
    final firebaseUser = context.watch<User?>();

    // Controlla il caricamento iniziale (necessita di una variabile in AuthService)
    // Se l'utente è null E non è ancora terminato il caricamento iniziale dell'AuthService, mostra il loader.
    final authService = context.watch<AuthService>();

    if (firebaseUser == null && authService.isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Se l'utente è loggato, mostra il layout principale.
    if (firebaseUser != null) {
      // Passiamo l'UID (che è garantito non nullo qui)
      return MainLayout(userId: firebaseUser.uid);
    }

    // Altrimenti, mostra la schermata di autenticazione.
    return const AuthScreen();
  }
}
