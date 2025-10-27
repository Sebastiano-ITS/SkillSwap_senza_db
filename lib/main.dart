import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'data/local_data.dart';
import 'services/local_data_service_explore.dart'; // Importa il nuovo servizio per explore page


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initializationError;

  try {
    await LocalData().initialize();
  } on StateError catch (error, stackTrace) {
    initializationError = 'Errore during l\'inizializzazione: ${error.message}';
    FlutterError.presentError(FlutterErrorDetails(exception: error, stack: stackTrace));
  } catch (error, stackTrace) {
    initializationError = 'Errore during l\'inizializzazione: $error';
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
      return MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
      );

    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider(create: (_) => LocalDataService()), // <-- per caricare user explore page
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
          catchError: (context, error) => null,
        ),
      ],
      child: MaterialApp.router(
        title: 'SkillSwap',
        theme: AppTheme.light(),
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
