import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'data/local_data.dart';
import 'services/local_data_service_explore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;
  try {
    await LocalData().initialize();
  } on StateError catch (error, stackTrace) {
    initializationError =
    "Errore durante l'inizializzazione: ${error.message}";
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
  } catch (error, stackTrace) {
    initializationError = "Errore durante l'inizializzazione: $error";
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
  }

  runApp(SkillSwapApp(initializationError: initializationError));
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key, this.initializationError});

  final String? initializationError;

  @override
  Widget build(BuildContext context) {
    // Se c'è un errore in fase di init mostriamo una schermata chiara e leggibile
    if (initializationError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SkillSwap',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: _InitializationErrorScreen(message: initializationError!),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<LocalDataService>(create: (_) => LocalDataService()),
        // Se il tuo AuthService espone uno stream di User (Firebase)
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().userStream,
          initialData: null,
          catchError: (_, __) => null,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SkillSwap',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
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
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              // coerente con BrandPalette
              Color(0xFFFFB200),
              Color(0xFFEB5B00),
              Color(0xFFD91656),
              Color(0xFF640D5F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ops…', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: tt.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Chiudi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
