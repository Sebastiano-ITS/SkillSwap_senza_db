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

  try {
    await Firebase.initializeApp(
      options: webDefaultOptions,
    );
    print("Firebase è stato inizializzato con successo.");
  } catch (e) {
    print("Errore nell'inizializzazione di Firebase: $e");
  }

  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        StreamProvider<User?>(
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
            backgroundColor: Color(0xFF673AB7),
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple).copyWith(
            secondary: const Color(0xFFFF9800),
          ),
          fontFamily: 'Inter',
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
    final firebaseUser = context.watch<User?>();
    final authService = context.watch<AuthService>();

    // CORREZIONE: Usiamo ?? false per gestire la nullità di isInitialLoading
    if (firebaseUser == null && (authService.isInitialLoading ?? true)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (firebaseUser != null) {
      return MainLayout(userId: firebaseUser.uid);
    } 
    
    return const AuthScreen();
  }
}
