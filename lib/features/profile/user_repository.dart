import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../models/user_profile.dart';

class UsersRepository {
  // Evita di ricaricare gli utenti più volte
  static List<UserProfile>? _cachedUsers;

  const UsersRepository();

  // Carica la lista degli utenti dal file JSON
  Future<List<UserProfile>> load() async {
    // Se gli utenti sono già in cache, li restituisce
    if (_cachedUsers != null) return _cachedUsers!;

    // Carica il file JSON dagli asset
    final jsonStr = await rootBundle.loadString('assets/data/users.json');
    final List<dynamic> data = json.decode(jsonStr);

    // Converte ogni elemento JSON in un oggetto UserProfile
    final users = data.map((e) => UserProfile.fromJson(e)).toList();

    // Mescola gli utenti in ordine casuale
    users.shuffle(Random());

    // Salva in cache
    _cachedUsers = users;

    return users;
  }
}