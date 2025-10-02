import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// Import necessario per accedere all'utente autenticato
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

// --- Variabili di Configurazione ---
// ATTENZIONE: Se stai usando la struttura /artifacts/{appId}/public/data/users,
// tutti possono leggere/scrivere. Per dati privati, dovresti usare
// /artifacts/{appId}/users/{userId}/...
const String _appId = '1:476854991127:web:a88a3ee55915a40bffdf52';
const String _baseCollectionPath = 'artifacts/$_appId/public/data/users';
// -----------------------------------

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Istanza di autenticazione per leggere l'ID utente corrente
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Riferimento alla collezione utenti basato sul percorso complesso
  CollectionReference get _userCollection => _db.collection(_baseCollectionPath);

  // *CRITICO*: GETTER PER L'ID UTENTE (LEGGE DA FIREBASE AUTH)
  String? get currentUserId {
    // Restituisce l'UID dell'utente correntemente loggato
    return _auth.currentUser?.uid;
  }

  // --- Metodi di Lettura ---

  // Recupero singolo profilo (Future)
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _userCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        // userProfile deve avere un fromFirestore che accetta DocumentSnapshot
        return UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      debugPrint('Errore durante il recupero del profilo $userId: $e');
      // Non rilanciare qui, ma se l'hai fatto nel codice originale, lascio.
      rethrow;
    }
  }

  // Stream in tempo reale per un singolo utente
  Stream<UserProfile?> streamUserProfile(String userId) {
    // Aggiungo un cast per sicurezza, assumendo che UserProfile.fromFirestore
    // accetti DocumentSnapshot<Map<String, dynamic>>
    return _userCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    });
  }

  // Stream di tutti gli utenti (utile per matching/elenco)
  Stream<List<UserProfile>> streamAllUsers() {
    return _userCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => UserProfile.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((profile) => profile.onboardingCompleted && profile.name.isNotEmpty)
          .toList();
    });
  }

  // --- Metodi di Scrittura ---

  // Crea o aggiorna il profilo di un utente
  Future<void> saveUserProfile(UserProfile profile) async {
    // Aggiungiamo un controllo per sicurezza
    final userId = currentUserId;
    if (userId == null || profile.userId != userId) {
      debugPrint('ATTENZIONE: Tentativo di salvare un profilo senza utente autenticato o con ID non corrispondente.');
      return;
    }

    try {
      await _userCollection
          .doc(profile.userId)
          .set(profile.toMap(), SetOptions(merge: true));
      debugPrint('Profilo utente ${profile.userId} salvato con successo.');
    } catch (e) {
      debugPrint('Errore nel salvataggio del profilo per ${profile.userId}: $e');
      rethrow;
    }
  }
}
