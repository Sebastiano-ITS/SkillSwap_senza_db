import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'data/local_data.dart';

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
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
          catchError: (context, error) => null,
        ),
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
        routerConfig: appRouter,
      ),
    );
  }
}