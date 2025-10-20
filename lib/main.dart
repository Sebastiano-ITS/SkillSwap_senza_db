import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth_wrapper.dart';
import 'data/local_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializza i dati locali
  await LocalData().initialize();
  
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider per fornire tutti i servizi all'albero dei widget
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo).copyWith(
            secondary: const Color(0xFFFF9800),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF673AB7),
            foregroundColor: Colors.white,
          ),
          fontFamily: 'Inter',
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
