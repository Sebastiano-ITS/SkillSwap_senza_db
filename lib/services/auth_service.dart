import 'dart:async';
import '../data/local_data.dart';

// Classe per simulare l'utente di Firebase
class User {
  final String uid;
  final String email;
  final String displayName;

  User({required this.uid, required this.email, required this.displayName});
}

class AuthService {
  // Istanza di LocalData
  final LocalData _localData = LocalData();
  
  // Controller per lo stream dell'utente
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();
  
  // Stato di caricamento iniziale per l'AuthWrapper
  bool _isInitialLoading = true;

  // Getter per lo stato di caricamento (utilizzato in main.dart)
  bool? get isInitialLoading => _isInitialLoading;

  // Stream per ascoltare i cambiamenti dello stato di autenticazione dell'utente
  Stream<User?> get userStream {
    // Inizializza i dati locali se non è già stato fatto
    _initializeLocalData();
    
    // Restituisci lo stream
    return _userStreamController.stream;
  }
  
  // Metodo per inizializzare i dati locali
  Future<void> _initializeLocalData() async {
    if (_isInitialLoading) {
      await _localData.initialize();
      
      // Controlla se c'è un utente corrente
      if (_localData.currentUserId != null) {
        final userProfile = _localData.getUserById(_localData.currentUserId!);
        if (userProfile != null) {
          _userStreamController.add(User(
            uid: userProfile.userId,
            email: userProfile.email,
            displayName: userProfile.name,
          ));
        } else {
          _userStreamController.add(null);
        }
      } else {
        _userStreamController.add(null);
      }
      
      // Imposta isInitialLoading a false dopo un breve ritardo
      Future.delayed(Duration(milliseconds: 50), () {
        _isInitialLoading = false;
      });
    }
  }

  /// ----------------------------------------------------------------------
  /// Metodi di Autenticazione (Utilizzati in auth_screen.dart)
  /// ----------------------------------------------------------------------

  // 1. Metodo di Registrazione (Sign Up)
  Future<void> signUp(String email, String password, String name) async {
    try {
      final userId = _localData.registerUser(email, password, name);
      
      if (userId != null) {
        // Notifica lo stream che c'è un nuovo utente
        final userProfile = _localData.getUserById(userId);
        if (userProfile != null) {
          _userStreamController.add(User(
            uid: userProfile.userId,
            email: userProfile.email,
            displayName: userProfile.name,
          ));
        }
      } else {
        throw Exception('Email già in uso');
      }
    } catch (e) {
      throw Exception('Errore durante la registrazione: $e');
    }
  }

  // 2. Metodo di Accesso (Sign In)
  Future<void> signIn(String email, String password) async {
    try {
      final success = _localData.authenticateUser(email, password);
      
      if (success) {
        // Notifica lo stream che c'è un utente autenticato
        if (_localData.currentUserId != null) {
          final userProfile = _localData.getUserById(_localData.currentUserId!);
          if (userProfile != null) {
            _userStreamController.add(User(
              uid: userProfile.userId,
              email: userProfile.email,
              displayName: userProfile.name,
            ));
          }
        }
      } else {
        throw Exception('Email o password non validi');
      }
    } catch (e) {
      throw Exception('Errore durante l\'accesso: $e');
    }
  }

  User? get currentUser {
    if (_localData.currentUserId != null) {
      final userProfile = _localData.getUserById(_localData.currentUserId!);
      if (userProfile != null) {
        return User(
          uid: userProfile.userId,
          email: userProfile.email,
          displayName: userProfile.name,
        );
      }
    }
    return null;
  }

  // 3. Metodo di Disconnessione (Sign Out)
  Future<void> signOut() async {
    _localData.signOut();
    _userStreamController.add(null);
  }
}