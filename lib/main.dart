// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/local_data.dart';
import 'navigation/app_router.dart'; // Importa la variabile globale appRouter
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalData().initialize();
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp.router(
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
        // Usa la configurazione del router globale
        routerConfig: appRouter,
      ),
    );
  }
}