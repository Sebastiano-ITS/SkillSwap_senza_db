// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user_profile.dart'; // Assicurati che il percorso sia corretto
import 'package:uuid/uuid.dart';

class AuthService with ChangeNotifier {
  UserProfile? _currentUser;
  List<dynamic>? _usersData;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Metodo per caricare i dati dal JSON una sola volta
  Future<void> _loadUsersData() async {
    if (_usersData == null) {
      final jsonString = await rootBundle.loadString('assets/data/users.json');
      final decodedJson = json.decode(jsonString);

      // --- CORREZIONE CHIAVE ---
      // Il tuo JSON è direttamente una lista, quindi non dobbiamo accedere a 'users'.
      _usersData = decodedJson as List<dynamic>;
    }
  }

  // Metodo di SignIn (ora dovrebbe funzionare correttamente)
  Future<void> signIn(String email, String password) async {
    await _loadUsersData();

    final userJsonMap = _usersData?.firstWhere(
          (user) => user['email'] == email && user['password'] == password,
      orElse: () => null,
    );

    if (userJsonMap != null) {
      // Il tuo UserProfile.fromMap si aspetta 'id' e 'userId', ma il JSON ha 'uid'.
      // Dobbiamo adattare la mappa prima di passarla.
      final adaptedMap = Map<String, dynamic>.from(userJsonMap);
      adaptedMap['id'] = userJsonMap['uid'];
      adaptedMap['userId'] = userJsonMap['uid'];

      _currentUser = UserProfile.fromMap(adaptedMap);
      notifyListeners();
    } else {
      throw Exception('Credenziali non valide. Riprova.');
    }
  }

  // Metodo di SignUp
  Future<void> signUp(String email, String password, String name) async {
    await _loadUsersData();

    final emailExists = _usersData?.any((user) => user['email'] == email) ?? false;
    if (emailExists) {
      throw Exception('Questa email è già stata registrata.');
    }

    const uuid = Uuid();
    final newUserId = uuid.v4();

    _currentUser = UserProfile(
      uid: newUserId,
      userId: newUserId,
      email: email,
      name: name,
      age: 0,
      imageUrl: 'https://via.placeholder.com/600x400',
      bio: '',
      canTeach: [],
      wantsToLearn: [],
      skills: [],
      skillsToLearn: [],
      onboardingCompleted: false,
    );

    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}