import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../models/user_profile.dart';

class UsersRepository {
  static List<UserProfile>? _cachedUsers; // mantiene la lista per la sessione

  const UsersRepository();

  Future<List<UserProfile>> load() async {
    // Se già caricati, restituisci la cache (mantiene ordine casuale)
    if (_cachedUsers != null) return _cachedUsers!;

    final jsonStr = await rootBundle.loadString('assets/data/users.json');
    final List<dynamic> data = json.decode(jsonStr);

    final users = data.map((e) => UserProfile.fromJson(e)).toList();

    // 👉 Mescola SOLO una volta all’avvio (ordine casuale per la sessione)
    users.shuffle(Random());

    _cachedUsers = users;
    return users;
  }
}