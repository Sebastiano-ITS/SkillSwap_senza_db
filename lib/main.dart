import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'data/local_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initializationError;

  try {
    await LocalData().initialize();
  } on StateError catch (error, stackTrace) {
    initializationError = 'Errore durante l\'inizializzazione: ${error.message}';
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stackTrace));
  } catch (error, stackTrace) {
    initializationError = 'Errore durante l\'inizializzazione: $error';
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stackTrace));
  }

  runApp(SkillSwapApp(initializationError: initializationError));
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key, this.initializationError});

  final String? initializationError;

  @override
  Widget build(BuildContext context) {
    if (initializationError != null) {
      return MaterialApp(
        title: 'SkillSwap',
        home: _InitializationErrorScreen(message: initializationError!),
      );
    }

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

class _InitializationErrorScreen extends StatelessWidget {
  const _InitializationErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}