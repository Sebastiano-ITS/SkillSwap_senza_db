// lib/data/local_data.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/models/match_request.dart';
import 'package:skillswap/models/user_profile.dart';


/// Storage locale JSON per utenti e richieste match.
/// - Copia gli asset la PRIMA volta; poi NON sovrascrive più i file locali.
/// - Mantiene la sessione (currentUserId) con SharedPreferences.
/// - Fa "merge" in saveUser per non perdere campi come password/createdAt.
/// - Login resiliente: normalizza email e backfill password se mancante (solo per demo).
class LocalData {
  // ---------- Singleton ----------
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  // ---------- Stato in memoria ----------
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _matchRequests = <Map<String, dynamic>>[];

  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  late File _usersFile;
  late File _matchRequestsFile;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  bool get isReady => _initialized;

  // (debug) path file utili da loggare
  String get usersFilePath => _usersFile.path;
  String get matchRequestsFilePath => _matchRequestsFile.path;

  // ---------- Helpers ----------
  String _normalizeEmail(String e) => e.trim().toLowerCase();

  // ---------- Init ----------
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

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

      // Copia asset SOLO se i file non esistono già
      await _ensureLocalFile(_usersFile, 'assets/data/users.json');
      await _ensureLocalFile(_matchRequestsFile, 'assets/data/match_requests.json');

      _users = await _readJsonFile(_usersFile);
      _matchRequests = await _readJsonFile(_matchRequestsFile);

      // Ripristina sessione (se presente)
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

  /// Crea il file locale dagli asset **solo se non esiste** (no sovrascrittura).
  Future<void> _ensureLocalFile(File file, String assetPath) async {
    if (!await file.exists()) {
      final String assetContent = await rootBundle.loadString(assetPath);
      await file.writeAsString(assetContent);
    }
  }

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

  Future<void> _persistUsers() async {
    if (!_initialized) return;
    await _usersFile.writeAsString(json.encode(_users));
  }

  Future<void> _persistMatchRequests() async {
    if (!_initialized) return;
    await _matchRequestsFile.writeAsString(json.encode(_matchRequests));
  }

  Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove('currentUserId');
    } else {
      await prefs.setString('currentUserId', userId);
    }
  }

  // ---------- API Utenti ----------
  List<UserProfile> getAllUsers() {
    return _users.map((e) => UserProfile.fromJson(e)).toList();
  }

  UserProfile? getUserById(String userId) {
    final Map<String, dynamic> data = _users.firstWhere(
          (u) => u['id'] == userId,
      orElse: () => <String, dynamic>{},
    );
    if (data.isEmpty) return null;
    return UserProfile.fromJson(data);
  }

  /// Crea/Aggiorna utente facendo MERGE con i campi esistenti (preserva password/createdAt).
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

  /// Login "mock" da file locale: email normalizzata, backfill password se mancante (solo demo).
  Future<bool> authenticateUser(String email, String password) async {
    await initialize();
    final norm = _normalizeEmail(email);

    // Cerca per email normalizzata
    final int idx = _users.indexWhere(
          (u) => _normalizeEmail((u['email'] ?? '') as String) == norm,
    );
    if (idx == -1) return false;

    final Map<String, dynamic> user = Map<String, dynamic>.from(_users[idx]);
    final String? storedPwd = user['password'] as String?;

    if (storedPwd == null || storedPwd.isEmpty) {
      // 🔧 Password mancante (è successo perché in passato veniva sovrascritta): facciamo backfill.
      user['password'] = password;
      _users[idx] = user;
      await _persistUsers();
      _currentUserId = user['id'] as String?;
      await _persistSession(_currentUserId);
      return true;
    }

    if (storedPwd == password) {
      _currentUserId = user['id'] as String?;
      await _persistSession(_currentUserId);
      return true;
    }

    return false;
  }

  /// Registrazione: ritorna l'id generato o null se email già in uso (confronto normalizzato).
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
      'email': norm, // salviamo già normalizzata
      'password': password, // NB: in produzione va hashata
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

  void signOut() {
    _currentUserId = null;
    _persistSession(null); // best-effort
  }

  // ---------- API Match ----------
  List<MatchRequest> getAllMatchRequests() {
    return _matchRequests
        .map((e) => MatchRequest.fromMap(e, e['id'] ?? ''))
        .toList();
  }

  List<MatchRequest> getReceivedRequests(String receiverId) {
    return getAllMatchRequests()
        .where((r) => r.receiverId == receiverId && !(r.accepted ?? false))
        .toList();
  }

  Future<void> addMatchRequest(MatchRequest request) async {
    await initialize();
    final map = request.toMap();
    map['id'] = 'request_${_matchRequests.length + 1}';
    _matchRequests.add(map);
    await _persistMatchRequests();
  }

  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    await initialize();
    final i = _matchRequests.indexWhere((r) => r['id'] == requestId);
    if (i != -1) {
      _matchRequests[i]['accepted'] = accepted;
      _matchRequests[i]['acceptanceTimestamp'] = DateTime.now().toIso8601String();
      await _persistMatchRequests();
    }
  }

  // ---------- Debug helpers ----------
  Future<void> debugPrintUsersFile() async {
    await initialize();
    final c = await _usersFile.readAsString();
    if (c.length > 2000) {
      // ignore: avoid_print
      print('${c.substring(0, 2000)}... [truncated]');
    } else {
      // ignore: avoid_print
      print(c);
    }
    // ignore: avoid_print
    print('Users file path: $usersFilePath');
  }

  /// (Opzionale) ripristina gli asset di default. Usare solo in debug.
  Future<void> resetLocalData() async {
    await initialize();
    final usersAsset = await rootBundle.loadString('assets/data/users.json');
    final reqsAsset = await rootBundle.loadString('assets/data/match_requests.json');
    await _usersFile.writeAsString(usersAsset);
    await _matchRequestsFile.writeAsString(reqsAsset);
    _users = await _readJsonFile(_usersFile);
    _matchRequests = await _readJsonFile(_matchRequestsFile);
  }
}
