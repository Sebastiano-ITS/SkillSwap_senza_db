import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/match_request.dart';
import '../models/user_profile.dart';

/// Classe che gestisce i dati locali dell'applicazione
class LocalData {
  // Singleton pattern
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  // Dati in memoria
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _matchRequests = [];

  // Utente corrente
  String? _currentUserId;

  // Getter per l'utente corrente
  String? get currentUserId => _currentUserId;

  void get newUserId => null;

  // Metodo per inizializzare i dati
  Future<void> initialize({AssetBundle? bundle}) async {
    final AssetBundle assetBundle = bundle ?? rootBundle;

    _users = await _loadJsonList(
      assetBundle,
      'assets/data/users.json',
      'Utenti di partenza',
    );

    _matchRequests = await _loadJsonList(
      assetBundle,
      'assets/data/match_requests.json',
      'Richieste di match',
    );
  }

  Future<List<Map<String, dynamic>>> _loadJsonList(
      AssetBundle bundle,
      String assetPath,
      String description,
      ) async {
    try {
      final String rawJson = await bundle.loadString(assetPath);
      _guardAgainstEmpty(rawJson, assetPath, description);
      return _decodeJsonList(rawJson, assetPath, description);
    } on FlutterError catch (error) {
      throw StateError(
        'Impossibile caricare l\'asset "$assetPath" per "$description". '
            'Assicurati che sia dichiarato in pubspec.yaml e che tu abbia eseguito "flutter pub get". '
            'Dettagli originali: ${error.message}',
      );
    } on FormatException catch (error) {
      throw StateError(
        'Impossibile decodificare "$assetPath". Controlla che il JSON sia valido. '
            'Errore: ${error.message}',
      );
    }
  }

  void _guardAgainstEmpty(String rawJson, String assetPath, String description) {
    if (rawJson.trim().isEmpty) {
      throw StateError(
        'Il file "$assetPath" per "$description" è vuoto. '
            'Verifica che l\'asset contenga dati di esempio validi.',
      );
    }
  }

  List<Map<String, dynamic>> _decodeJsonList(
      String rawJson,
      String assetPath,
      String description,
      ) {
    final Object? decoded = json.decode(rawJson);
    if (decoded is! List) {
      throw StateError(
        'Il contenuto di "$assetPath" non è una lista JSON valida per "$description".',
      );
    }
    return List<Map<String, dynamic>>.from(decoded);
  }

  // Metodo per ottenere tutti gli utenti
  List<UserProfile> getAllUsers() {
    return _users.map((userData) => UserProfile.fromMap(userData)).toList();
  }

  // Metodo per ottenere un utente specifico
  UserProfile? getUserById(String userId) {
    final userData = _users.firstWhere(
          (user) => (user['uid'] == userId) || (user['id'] == userId),
      orElse: () => <String, dynamic>{},
    );

    if (userData.isEmpty) return null;

    return UserProfile.fromMap(userData);
  }

  // Metodo per salvare un utente
  void saveUser(UserProfile user) {
    final index = _users.indexWhere((u) => (u['uid'] == user.userId) || (u['id'] == user.userId));
    final Map<String, dynamic> map = user.toMap();
    if (index != -1) {
      _users[index] = map;
    final Map<String, dynamic> newUser = {
    'uid': newUserId,
    'email': email,
    'password': password, // In un'app reale, questa password dovrebbe essere criptata
    'name': name,
    'createdAt': DateTime.now().toIso8601String(),
    'onboardingCompleted': false,
    'canTeach': <String>[],
    'wantsToLearn': <String>[],
    'hourlyRate': 15.0,
    };

    // Aggiungi l'utente alla lista
    _users.add(newUser);

    // Imposta l'utente corrente
    _currentUserId = newUserId;

    return newUserId;
    }

    // Metodo per disconnettere l'utente
    void signOut() {
    _currentUserId = null;
    }

    @visibleForTesting
    void resetForTesting() {
    _users = <Map<String, dynamic>>[];
    _matchRequests = <Map<String, dynamic>>[];
    _currentUserId = null;
    }
  }