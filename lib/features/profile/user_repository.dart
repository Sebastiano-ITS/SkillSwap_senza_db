import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../../models/user_profile.dart';

class UsersRepository {
  final String assetPath;
  const UsersRepository({this.assetPath = 'assets/data/users.json'});

  Future<List<UserProfile>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = json.decode(raw);
    return jsonList.map((json) => UserProfile.fromJson(json)).toList();
  }
}
