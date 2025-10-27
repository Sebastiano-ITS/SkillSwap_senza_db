import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/match_request.dart';
import '../models/user_profile.dart';

class LocalData {
  //Singleton
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  // Liste per utenti e richieste di match
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _matchRequests = <Map<String, dynamic>>[];

  // Stato di inizializzazione
  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  // File per memorizzare utenti e match
  late File _usersFile;
  late File _matchRequestsFile;

  // ID dell'utente attualmente loggato
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  bool get isReady => _initialized;

  // Getter per il percorso dei file
  String get usersFilePath => _usersFile.path;
  String get matchRequestsFilePath => _matchRequestsFile.path;

  // Normalizza email rimuovendo spazi e rendendola minuscola
  String _normalizeEmail(String e) => e.trim().toLowerCase();

  // Inizializzazione dei file e caricamento dati
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationCompleter != null) return _initializationCompleter!.future;

    final completer = Completer<void>();
    _initializationCompleter = completer;

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory dataDir = Directory('${appDir.path}/skillswap');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      _usersFile = File('${dataDir.path}/users.json');
      _matchRequestsFile = File('${dataDir.path}/match_requests.json');

      if (!await _usersFile.exists()) {
        await _usersFile.writeAsString('[]');
      }
      if (!await _matchRequestsFile.exists()) {
        await _matchRequestsFile.writeAsString('[]');
      }

      _users = await _readJsonFile(_usersFile);
      _matchRequests = await _readJsonFile(_matchRequestsFile);

      final bool changed = await _migrateIfNeeded();
      if (changed) await _persistUsers();

      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('currentUserId');

      _initialized = true;
      completer.complete();
    } catch (e, st) {
      _initialized = false;
      _initializationCompleter = null;
      completer.completeError(e, st);
      rethrow;
    }
  }

  // Migrazione: normalizza email e rimuove duplicati
  Future<bool> _migrateIfNeeded() async {
    bool mutated = false;

    for (int i = 0; i < _users.length; i++) {
      final email = (_users[i]['email'] ?? '') as String;
      final norm = _normalizeEmail(email);
      if (email != norm) {
        _users[i] = {..._users[i], 'email': norm};
        mutated = true;
      }
    }

    final Map<String, Map<String, dynamic>> byEmail = {};
    for (final u in _users) {
      final email = _normalizeEmail((u['email'] ?? '') as String);
      if (email.isEmpty) continue;

      if (!byEmail.containsKey(email)) {
        byEmail[email] = u;
      } else {
        final hasPwd = (byEmail[email]!['password'] ?? '').toString().isNotEmpty;
        final candidateHasPwd = (u['password'] ?? '').toString().isNotEmpty;
        if (!hasPwd && candidateHasPwd) {
          byEmail[email] = u;
          mutated = true;
        } else {
          mutated = true;
        }
      }
    }

    if (byEmail.isNotEmpty) {
      final reconstructed = byEmail.values.toList();
      if (reconstructed.length != _users.length) {
        _users = reconstructed;
        mutated = true;
      }
    }

    return mutated;
  }

  // Lettura da file JSON e parsing in lista di mappe
  Future<List<Map<String, dynamic>>> _readJsonFile(File file) async {
    if (!await file.exists()) return <Map<String, dynamic>>[];
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) return <Map<String, dynamic>>[];

    final dynamic decoded = json.decode(raw);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(
        decoded.map<Map<String, dynamic>>(
              (dynamic item) => Map<String, dynamic>.from(item as Map),
        ),
      );
    }
    return <Map<String, dynamic>>[];
  }

  // Salva la lista utenti su file
  Future<void> _persistUsers() async {
    if (!_initialized) return;
    await _usersFile.writeAsString(json.encode(_users));
  }

  // Salva la lista richieste di match su file
  Future<void> _persistMatchRequests() async {
    if (!_initialized) return;
    await _matchRequestsFile.writeAsString(json.encode(_matchRequests));
  }

  // Salva o rimuove la sessione corrente
  Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove('currentUserId');
    } else {
      await prefs.setString('currentUserId', userId);
    }
  }

  // Restituisce tutti gli utenti
  List<UserProfile> getAllUsers() {
    return _users.map((e) => UserProfile.fromJson(e)).toList();
  }

  // Cerca utente per ID
  UserProfile? getUserById(String userId) {
    final Map<String, dynamic> data = _users.firstWhere(
          (u) => u['id'] == userId,
      orElse: () => <String, dynamic>{},
    );
    if (data.isEmpty) return null;
    return UserProfile.fromJson(data);
  }

  // Salva un utente (nuovo o esistente)
  Future<void> saveUser(UserProfile user) async {
    await initialize();
    final i = _users.indexWhere((u) => u['id'] == user.id);
    if (i != -1) {
      final existing = Map<String, dynamic>.from(_users[i]);
      final updated = user.toJson();
      _users[i] = {...existing, ...updated};
    } else {
      _users.add(user.toJson());
    }
    await _persistUsers();
  }

  // Autenticazione email + password
  Future<bool> authenticateUser(String email, String password) async {
    await initialize();
    final norm = _normalizeEmail(email);

    final int idx = _users.indexWhere(
          (u) => _normalizeEmail((u['email'] ?? '') as String) == norm,
    );
    if (idx == -1) return false;

    final Map<String, dynamic> user = Map<String, dynamic>.from(_users[idx]);
    final String? storedPwd = user['password'] as String?;

    // Se non ha password, la imposta
    if (storedPwd == null || storedPwd.isEmpty) {
      user['password'] = password;
      _users[idx] = user;
      await _persistUsers();
      _currentUserId = user['id'] as String?;
      await _persistSession(_currentUserId);
      return true;
    }

    // Se la password coincide
    if (storedPwd == password) {
      _currentUserId = user['id'] as String?;
      await _persistSession(_currentUserId);
      return true;
    }

    return false;
  }

  // Registra un nuovo utente
  Future<String?> registerUser(String email, String password, String name) async {
    await initialize();
    final norm = _normalizeEmail(email);

    final exists = _users.firstWhere(
          (u) => _normalizeEmail((u['email'] ?? '') as String) == norm,
      orElse: () => <String, dynamic>{},
    );
    if (exists.isNotEmpty) return null;

    final newId = 'user_${_users.length + 1}';
    final Map<String, dynamic> newUser = <String, dynamic>{
      'id': newId,
      'email': norm,
      'password': password,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
      'onboardingCompleted': false,
      'canTeach': <String>[],
      'wantsToLearn': <String>[],
    };

    _users.add(newUser);
    await _persistUsers();

    _currentUserId = newId;
    await _persistSession(_currentUserId);
    return newId;
  }

  // Disconnette l'utente corrente
  void signOut() {
    _currentUserId = null;
    _persistSession(null);
  }

  // Restituisce tutte le richieste
  List<MatchRequest> getAllMatchRequests() {
    return _matchRequests
        .map((e) => MatchRequest.fromMap(e, e['id'] ?? ''))
        .toList();
  }

  // Restituisce richieste ricevute non ancora accettate
  List<MatchRequest> getReceivedRequests(String receiverId) {
    return getAllMatchRequests()
        .where((r) => r.receiverId == receiverId && !(r.accepted ?? false))
        .toList();
  }

  // Aggiunge una nuova richiesta di match
  Future<void> addMatchRequest(MatchRequest request) async {
    await initialize();
    final map = request.toMap();
    map['id'] = 'request_${_matchRequests.length + 1}';
    _matchRequests.add(map);
    await _persistMatchRequests();
  }

  // Aggiorna lo stato di una richiesta
  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    await initialize();
    final i = _matchRequests.indexWhere((r) => r['id'] == requestId);
    if (i != -1) {
      _matchRequests[i]['accepted'] = accepted;
      _matchRequests[i]['acceptanceTimestamp'] = DateTime.now().toIso8601String();
      await _persistMatchRequests();
    }
  }

  // Pulisce tutto (reset app)
  Future<void> resetAll() async {
    await initialize();
    _users = <Map<String, dynamic>>[];
    _matchRequests = <Map<String, dynamic>>[];
    await _persistUsers();
    await _persistMatchRequests();
    _currentUserId = null;
    await _persistSession(null);
  }

  // Stampa contenuto del file utenti
  Future<void> debugPrintUsersFile() async {
    await initialize();
    final c = await _usersFile.readAsString();
    print('Users file path: $usersFilePath');
    if (c.length > 2000) {
      print('${c.substring(0, 2000)}... [troncato]');
    } else {
      print(c);
    }
  }
}
