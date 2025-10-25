// lib/services/firestore_service.dart
import 'dart:async';
import '../models/user_profile.dart';
import '../models/match_request.dart';
import '../data/local_data.dart';

/// "Firestore" locale basato su LocalData + stream in-memory.
/// - Stream utenti (lista completa)
/// - Stream profilo per-utente (1 controller per userId)
/// - Stream richieste ricevute
class FirestoreService {
  FirestoreService() {
    _initializeData();
  }

  final LocalData _localData = LocalData();

  // Stream globali
  final _usersStreamController = StreamController<List<UserProfile>>.broadcast();
  final _receivedRequestsStreamController =
  StreamController<List<MatchRequest>>.broadcast();

  // Stream per-utente (un controller per userId)
  final Map<String, StreamController<UserProfile?>> _userControllers = {};

  Future<void> _initializeData() async {
    await _localData.initialize();
    // Emissione iniziale lista utenti
    _emitAllUsers();
  }

  // ---------- Helpers di emissione ----------

  void _emitAllUsers() {
    final users = _localData.getAllUsers();
    _usersStreamController.add(users);
  }

  void _emitUser(String userId) {
    final c = _userControllers[userId];
    if (c != null && !c.isClosed) {
      c.add(_localData.getUserById(userId));
    }
  }

  Future<void> _emitReceivedRequests(String receiverId) async {
    await _localData.initialize();
    final reqs = _localData.getReceivedRequests(receiverId);
    _receivedRequestsStreamController.add(reqs);
  }

  // ---------- API Stream ----------

  /// Stream della lista completa utenti (broadcast).
  Stream<List<UserProfile>> streamAllUsers() {
    // emissione iniziale asincrona per non perdere il primo valore
    Future.microtask(_emitAllUsers);
    return _usersStreamController.stream;
  }

  /// Stream del singolo profilo utente (1 stream per userId).
  Stream<UserProfile?> streamUserProfile(String userId) {
    _userControllers[userId] ??= StreamController<UserProfile?>.broadcast(
      onListen: () {
        // appena qualcuno si iscrive, emetti lo snapshot corrente
        _emitUser(userId);
      },
    );
    return _userControllers[userId]!.stream;
  }

  /// Stream richieste ricevute per un dato ricevente.
  Stream<List<MatchRequest>> streamReceivedRequests(String receiverId) {
    Future.microtask(() => _emitReceivedRequests(receiverId));
    return _receivedRequestsStreamController.stream;
  }

  // ---------- Mutazioni ----------

  /// Salva/Aggiorna un profilo; aggiorna i relativi stream.
  Future<void> saveUserProfile(UserProfile user) async {
    await _localData.saveUser(user);
    _emitAllUsers();
    _emitUser(user.id);
  }

  /// Invia una nuova richiesta di match e aggiorna lo stream del ricevente.
  Future<void> sendMatchRequest(MatchRequest request) async {
    await _localData.addMatchRequest(request);
    await _emitReceivedRequests(request.receiverId);
  }

  /// Aggiorna lo stato di una richiesta e refresha stream (lista utenti + richieste).
  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    await _localData.updateRequestStatus(requestId, accepted);
    _emitAllUsers();
    // opzionale: qui non sappiamo il receiverId, aggiorniamo genericamente
    // In app reale passeresti il receiverId per ottimizzare
  }

  // Utility per forzare un refresh manuale (es. dopo operazioni batch).
  Future<void> refreshUser(String userId) async {
    await _localData.initialize();
    _emitUser(userId);
    _emitAllUsers();
  }

  // ---------- Dispose ----------
  void dispose() {
    _usersStreamController.close();
    _receivedRequestsStreamController.close();
    for (final c in _userControllers.values) {
      c.close();
    }
    _userControllers.clear();
  }
}
