import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce i "match" lato client usando SharedPreferences.
/// - Cache in memoria per evitare I/O ripetuti
/// - Stream broadcast per reagire ai cambiamenti in tempo reale
/// - Namespacing per utente (opzionale) per separare i match per account
class MatchService {
  /// Versione legacy (senza namespace) usata in passato.
  static const String _legacyKey = 'matched_profile_ids';

  /// Prefisso per i key namespaced (per utente).
  static const String _keyPrefix = 'matched_profile_ids_';

  /// Facoltativo: ID dell’utente corrente per namespacing.
  /// Se non lo passi, userà il namespace 'default'.
  final String? currentUserId;

  MatchService({this.currentUserId});

  /// Key effettiva usata su SharedPreferences
  String get _key => '$_keyPrefix${currentUserId ?? 'default'}';

  /// Cache in memoria degli ID matchati (mantiene l’ordine d’inserimento, senza duplicati).
  List<String>? _cache;

  /// Stream per ascoltare aggiornamenti (es. per UI reactive).
  final StreamController<List<String>> _controller =
  StreamController<List<String>>.broadcast();

  /// Espone lo stream dei match.
  /// Subito dopo la sottoscrizione viene emesso lo stato corrente.
  Stream<List<String>> watchMatches() async* {
    // Prima emetti quello in cache o da disco
    yield await getMatchedIds();
    yield* _controller.stream;
  }

  /// Carica da disco (con cache e migrazione dal legacy al namespaced).
  Future<List<String>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();

    // Prova a leggere dal key namespaced
    List<String> data = prefs.getStringList(_key) ?? const [];

    // Migrazione: se non c'è nulla nel namespaced, ma c'è il legacy, migra
    if (data.isEmpty) {
      final legacy = prefs.getStringList(_legacyKey);
      if (legacy != null && legacy.isNotEmpty) {
        data = List<String>.from(legacy.toSet()); // dedup
        // Salva nel nuovo key e lascia intatto il legacy (per sicurezza)
        await prefs.setStringList(_key, data);
      }
    }

    _cache = data;
    return _cache!;
  }

  /// Persiste su disco e notifica lo stream.
  Future<void> _persist(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    _cache = List<String>.from(ids); // snapshot immutabile
    await prefs.setStringList(_key, _cache!);
    // Notifica gli ascoltatori con una copia (evita modifiche esterne)
    if (!_controller.isClosed) {
      _controller.add(List<String>.from(_cache!));
    }
  }

  /// Aggiunge un match (id) se non presente.
  Future<void> saveMatch(String profileId) async {
    final ids = List<String>.from(await _load());
    if (!ids.contains(profileId)) {
      ids.add(profileId);
      await _persist(ids);
    }
  }

  /// Ritorna tutti gli ID matchati (dalla cache o disco).
  Future<List<String>> getMatchedIds() async {
    return List<String>.from(await _load());
  }

  /// True se l’ID è presente tra i match.
  Future<bool> isMatched(String profileId) async {
    final ids = await _load();
    return ids.contains(profileId);
  }

  /// Rimuove un match (se presente).
  Future<void> removeMatch(String profileId) async {
    final ids = List<String>.from(await _load());
    if (ids.remove(profileId)) {
      await _persist(ids);
    }
  }

  /// Inverte lo stato di match per un ID.
  /// Ritorna il nuovo stato: true se ora è matchato, false se rimosso.
  Future<bool> toggleMatch(String profileId) async {
    final ids = List<String>.from(await _load());
    final wasMatched = ids.contains(profileId);
    if (wasMatched) {
      ids.remove(profileId);
    } else {
      ids.add(profileId);
    }
    await _persist(ids);
    return !wasMatched;
  }

  /// Cancella tutti i match dell’utente corrente (namespace corrente).
  Future<void> clearMatches() async {
    final prefs = await SharedPreferences.getInstance();
    _cache = <String>[];
    await prefs.setStringList(_key, _cache!);
    if (!_controller.isClosed) {
      _controller.add(<String>[]);
    }
  }

  /// Chiudi lo stream quando non serve più (es. in dispose di un service locator).
  Future<void> dispose() async {
    await _controller.close();
  }
}
