import 'dart:async';
import '../models/user_profile.dart';
import '../models/match_request.dart';
import '../data/local_data.dart';

class FirestoreService {
  // Istanza di LocalData
  final LocalData _localData = LocalData();

  // Stream controllers
  final _usersStreamController = StreamController<List<UserProfile>>.broadcast();
  final _userProfileStreamController = StreamController<UserProfile?>.broadcast();
  final _receivedRequestsStreamController =
      StreamController<List<MatchRequest>>.broadcast();

  // Costruttore
  FirestoreService() {
    _initializeData();
  }

  // Inizializza i dati
  Future<void> _initializeData() async {
    await _localData.initialize();
  }

  // Metodo per ottenere tutti i profili utente in tempo reale
  Stream<List<UserProfile>> streamAllUsers() {
    // Programma l'emissione iniziale per evitare perdita di eventi prima dell'iscrizione
    Future.microtask(() async {
      await _localData.initialize();
      _usersStreamController.add(_localData.getAllUsers());
    });
    return _usersStreamController.stream;
  }

  // Metodo per ottenere un singolo profilo utente
  Stream<UserProfile?> streamUserProfile(String userId) {
    // Programma l'emissione iniziale per evitare perdita di eventi prima dell'iscrizione
    Future.microtask(() async {
      await _localData.initialize();
      _userProfileStreamController.add(_localData.getUserById(userId));
    });
    return _userProfileStreamController.stream;
  }

  // Metodo per salvare o aggiornare un profilo (usato in Onboarding)
  Future<void> saveUserProfile(UserProfile user) async {
    await _localData.saveUser(user);
    // Aggiorna gli stream
    _usersStreamController.add(_localData.getAllUsers());
    _userProfileStreamController.add(user);
  }

  // --- METODI PER LA GESTIONE DELLE RICHIESTE ---

  // 1. Invia una richiesta di match
  Future<void> sendMatchRequest(MatchRequest request) async {
    await _localData.addMatchRequest(request);
    // Aggiorna lo stream delle richieste ricevute
    await _updateReceivedRequestsStream(request.receiverId);
  }

  // 2. Ottieni le richieste ricevute in tempo reale per un dato ricevente
  Stream<List<MatchRequest>> streamReceivedRequests(String receiverId) {
    Future.microtask(() async {
      await _updateReceivedRequestsStream(receiverId);
    });
    return _receivedRequestsStreamController.stream;
  }

  // Metodo per aggiornare lo stream delle richieste ricevute
  Future<void> _updateReceivedRequestsStream(String receiverId) async {
    await _localData.initialize();
    _receivedRequestsStreamController
        .add(_localData.getReceivedRequests(receiverId));
  }

  // 3. Aggiorna lo stato di una richiesta (es. accettarla)
  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    await _localData.updateRequestStatus(requestId, accepted);
    // Aggiorna tutti gli stream per riflettere i cambiamenti
    await _updateAllStreams();
  }

  // Metodo per aggiornare tutti gli stream
  Future<void> _updateAllStreams() async {
    // Aggiorna lo stream degli utenti
    await _localData.initialize();
    _usersStreamController.add(_localData.getAllUsers());

    // Aggiorna lo stream delle richieste ricevute per tutti gli utenti
    // (in un'app reale, questo sarebbe più mirato)
    for (var user in _localData.getAllUsers()) {
      await _updateReceivedRequestsStream(user.id);
    }
  }

  // Chiudi tutti gli stream quando non sono più necessari
  void dispose() {
    _usersStreamController.close();
    _userProfileStreamController.close();
    _receivedRequestsStreamController.close();
  }
}
