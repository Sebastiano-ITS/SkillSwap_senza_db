import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user_profile.dart';
import '../models/match_request.dart';
import 'dart:async';

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
  
  // Metodo per inizializzare i dati
  Future<void> initialize() async {
    // Carica i dati degli utenti dal file JSON
    final String usersJson = await rootBundle.loadString('assets/data/users.json');
    _users = List<Map<String, dynamic>>.from(json.decode(usersJson));
    
    // Carica i dati delle richieste di match dal file JSON
    final String requestsJson = await rootBundle.loadString('assets/data/match_requests.json');
    _matchRequests = List<Map<String, dynamic>>.from(json.decode(requestsJson));
  }
  
  // Metodo per ottenere tutti gli utenti
  List<UserProfile> getAllUsers() {
    return _users.map((userData) => UserProfile(
      userId: userData['uid'],
      email: userData['email'],
      name: userData['name'],
      canTeach: List<String>.from(userData['canTeach'] ?? []),
      wantsToLearn: List<String>.from(userData['wantsToLearn'] ?? []),
      onboardingCompleted: userData['onboardingCompleted'] ?? false,
      hourlyRate: (userData['hourlyRate'] is num) ? userData['hourlyRate'].toDouble() : 15.0,
    )).toList();
  }
  
  // Metodo per ottenere un utente specifico
  UserProfile? getUserById(String userId) {
    final userData = _users.firstWhere(
      (user) => user['uid'] == userId,
      orElse: () => <String, dynamic>{},
    );
    
    if (userData.isEmpty) return null;
    
    return UserProfile(
      userId: userData['uid'],
      email: userData['email'],
      name: userData['name'],
      canTeach: List<String>.from(userData['canTeach'] ?? []),
      wantsToLearn: List<String>.from(userData['wantsToLearn'] ?? []),
      onboardingCompleted: userData['onboardingCompleted'] ?? false,
      hourlyRate: (userData['hourlyRate'] is num) ? userData['hourlyRate'].toDouble() : 15.0,
    );
  }
  
  // Metodo per salvare un utente
  void saveUser(UserProfile user) {
    final index = _users.indexWhere((u) => u['uid'] == user.userId);
    if (index != -1) {
      _users[index] = user.toJson();
    } else {
      _users.add(user.toJson());
    }
  }
  
  // Metodo per ottenere tutte le richieste di match
  List<MatchRequest> getAllMatchRequests() {
    return _matchRequests.map((requestData) => MatchRequest(
      id: requestData['id'],
      senderId: requestData['senderId'],
      senderName: requestData['senderName'],
      receiverId: requestData['receiverId'],
      skillRequested: requestData['skillRequested'],
      message: requestData['message'],
      timestamp: DateTime.parse(requestData['timestamp']),
      accepted: requestData['accepted'] ?? false,
    )).toList();
  }
  
  // Metodo per ottenere le richieste di match ricevute da un utente
  List<MatchRequest> getReceivedRequests(String receiverId) {
    return getAllMatchRequests()
        .where((request) => request.receiverId == receiverId && !request.accepted)
        .toList();
  }
  
  // Metodo per aggiungere una nuova richiesta di match
  void addMatchRequest(MatchRequest request) {
    final Map<String, dynamic> requestMap = request.toMap();
    requestMap['id'] = 'request_${_matchRequests.length + 1}';
    requestMap['timestamp'] = request.timestamp.toIso8601String();
    _matchRequests.add(requestMap);
  }
  
  // Metodo per aggiornare lo stato di una richiesta di match
  void updateRequestStatus(String requestId, bool accepted) {
    final index = _matchRequests.indexWhere((r) => r['id'] == requestId);
    if (index != -1) {
      _matchRequests[index]['accepted'] = accepted;
      _matchRequests[index]['acceptanceTimestamp'] = DateTime.now().toIso8601String();
    }
  }
  
  // Metodo per autenticare un utente
  bool authenticateUser(String email, String password) {
    final user = _users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => <String, dynamic>{},
    );
    
    if (user.isNotEmpty) {
      _currentUserId = user['uid'];
      return true;
    }
    return false;
  }
  
  // Metodo per registrare un nuovo utente
  String? registerUser(String email, String password, String name) {
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
}