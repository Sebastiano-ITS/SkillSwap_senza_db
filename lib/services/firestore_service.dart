import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

// Simulazione dell'ID dell'app e della struttura Canvas
const String _appId = 'skillswap_app_id'; // Deve corrispondere a __app_id
const String _baseCollectionPath = 'artifacts/$_appId/public/data/users';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Riferimento alla collezione utenti
  CollectionReference get _userCollection => _db.collection(_baseCollectionPath);

  // Ottiene il profilo di un singolo utente in tempo reale (Stream)
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _userCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Ottiene tutti i profili utente (utile per il matching)
  Stream<List<UserProfile>> streamAllUsers() {
    return _userCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    });
  }

  // Crea o aggiorna il profilo di un utente
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _userCollection.doc(profile.userId).set(profile.toMap(), SetOptions(merge: true));
      debugPrint('Profilo utente ${profile.userId} salvato con successo.');
    } catch (e) {
      debugPrint('Errore nel salvataggio del profilo: $e');
      rethrow;
    }
  }
}
