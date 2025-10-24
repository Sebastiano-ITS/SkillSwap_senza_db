import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

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

  // Gestione inizializzazione e file locali
  bool _initialized = false;
  Completer<void>? _initializationCompleter;
  late File _usersFile;
  late File _matchRequestsFile;

  // Utente corrente
  String? _currentUserId;

  // Getter per l'utente corrente
  String? get currentUserId => _currentUserId;

  bool get isReady => _initialized;

  // Metodo per inizializzare i dati
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    final completer = Completer<void>();
    _initializationCompleter = completer;

    try {
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final Directory dataDirectory = Directory('${appDirectory.path}/skillswap');
      if (!await dataDirectory.exists()) {
        await dataDirectory.create(recursive: true);
      }

      _usersFile = File('${dataDirectory.path}/users.json');
      _matchRequestsFile = File('${dataDirectory.path}/match_requests.json');

      await _ensureLocalFile(_usersFile, 'assets/data/users.json');
      await _ensureLocalFile(_matchRequestsFile, 'assets/data/match_requests.json');

      _users = await _readJsonFile(_usersFile);
      _matchRequests = await _readJsonFile(_matchRequestsFile);

      _initialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      _initializationCompleter = null;
      rethrow;
    }
  }

  // Modificato per forzare la sovrascrittura del file locale con la versione degli asset
  Future<void> _ensureLocalFile(File file, String assetPath) async {
    final String assetContent = await rootBundle.loadString(assetPath);
    await file.writeAsString(assetContent);
  }

  Future<List<Map<String, dynamic>>> _readJsonFile(File file) async {
    if (!await file.exists()) {
      return <Map<String, dynamic>>[];
    }
    final String rawContent = await file.readAsString();
    if (rawContent.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final dynamic decoded = json.decode(rawContent);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded.map<Map<String, dynamic>>(
            (dynamic item) => Map<String, dynamic>.from(item as Map),
      ));
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _persistUsers() async {
    if (!_initialized) return;
    await _usersFile.writeAsString(json.encode(_users));
  }

  Future<void> _persistMatchRequests() async {
    if (!_initialized) return;
    await _matchRequestsFile.writeAsString(json.encode(_matchRequests));
  }

  // Metodo per ottenere tutti gli utenti
  List<UserProfile> getAllUsers() {
    return _users.map((userData) => UserProfile.fromJson(userData)).toList();
  }

  // Metodo per ottenere un utente specifico
  UserProfile? getUserById(String userId) {
    final userData = _users.firstWhere(
          (user) => user['id'] == userId,
      orElse: () => <String, dynamic>{},
    );

    if (userData.isEmpty) return null;

    return UserProfile.fromJson(userData);
  }

  // Metodo per salvare un utente
  Future<void> saveUser(UserProfile user) async {
    await initialize();
    final index = _users.indexWhere((u) => u['id'] == user.id);
    if (index != -1) {
      _users[index] = user.toJson();
    } else {
      _users.add(user.toJson());
    }
    await _persistUsers();
  }

  // Metodo per ottenere tutte le richieste di match
  List<MatchRequest> getAllMatchRequests() {
    return _matchRequests
        .map((requestData) =>
            MatchRequest.fromMap(requestData, requestData['id'] ?? ''))
        .toList();
  }

  // Metodo per ottenere le richieste di match ricevute da un utente
  List<MatchRequest> getReceivedRequests(String receiverId) {
    return getAllMatchRequests()
        .where((request) => request.receiverId == receiverId && !request.accepted)
        .toList();
  }

  // Metodo per aggiungere una nuova richiesta di match
  Future<void> addMatchRequest(MatchRequest request) async {
    await initialize();
    final Map<String, dynamic> requestMap = request.toMap();
    requestMap['id'] = 'request_${_matchRequests.length + 1}';
    _matchRequests.add(requestMap);
    await _persistMatchRequests();
  }

  // Metodo per aggiornare lo stato di una richiesta di match
  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    await initialize();
    final index = _matchRequests.indexWhere((r) => r['id'] == requestId);
    if (index != -1) {
      _matchRequests[index]['accepted'] = accepted;
      _matchRequests[index]['acceptanceTimestamp'] = DateTime.now().toIso8601String();
      await _persistMatchRequests();
    }
  }

  // Metodo per autenticare un utente
  Future<bool> authenticateUser(String email, String password) async {
    await initialize();
    final user = _users.firstWhere(
          (u) => u['email'] == email && u['password'] == password,
      orElse: () => <String, dynamic>{},
    );

    if (user.isNotEmpty) {
      _currentUserId = user['id'];
      return true;
    }
    return false;
  }

  // Metodo per registrare un nuovo utente
  Future<String?> registerUser(String email, String password, String name) async {
    await initialize();
    // Verifica se l'email è già in uso
    final existingUser = _users.firstWhere(
          (u) => u['email'] == email,
      orElse: () => <String, dynamic>{},
    );

    if (existingUser.isNotEmpty) {
      return null; // Email già in uso
    }

    // Crea un nuovo ID utente
    final String newUserId = 'user_${_users.length + 1}';

    // Crea un nuovo utente
    final Map<String, dynamic> newUser = {
      'id': newUserId,
      'email': email,
      'password': password, // In un'app reale, questa password dovrebbe essere criptata
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
      'onboardingCompleted': false,
      'canTeach': <String>[],
      'wantsToLearn': <String>[],
    };

    // Aggiungi l'utente alla lista
    _users.add(newUser);
    await _persistUsers();

    // Imposta l'utente corrente
    _currentUserId = newUserId;

    return newUserId;
  }

  // Metodo per disconnettere l'utente
  void signOut() {
    _currentUserId = null;
  }
}
