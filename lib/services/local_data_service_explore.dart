// lib/services/local_data_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';

class LocalDataService {
  List<UserProfile>? _users;

  Future<void> _loadUsers() async {
    if (_users == null) {
      final String jsonString = await rootBundle.loadString('assets/data/users.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _users = jsonList.map((json) => UserProfile.fromJson(json)).toList();
    }
  }

  Future<List<UserProfile>> getUsersBySkill(String skill) async {
    await _loadUsers();
    if (_users == null) return [];

    // Filtra la lista di utenti
    return _users!.where((user) {
      // Controlla se la lista 'canTeach' dell'utente contiene la skill richiesta (case-insensitive)
      return user.canTeach.any((s) => s.toLowerCase() == skill.toLowerCase());
    }).toList();
  }
}