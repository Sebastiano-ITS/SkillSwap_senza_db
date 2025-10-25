import 'package:shared_preferences/shared_preferences.dart';

class MatchService {
  static const _key = 'matched_profile_ids';

  Future<void> saveMatch(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    if (!existing.contains(profileId)) {
      existing.add(profileId);
      await prefs.setStringList(_key, existing);
    }
  }

  Future<List<String>> getMatchedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<bool> isMatched(String profileId) async {
    final matches = await getMatchedIds();
    return matches.contains(profileId);
  }
}