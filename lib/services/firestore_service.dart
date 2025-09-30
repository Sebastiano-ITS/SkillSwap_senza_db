import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

// --- Variabili di Configurazione (Mantengo la tua struttura) ---
// L'ID dell'app e la struttura Canvas/Deployment specifica.
// Assicurati che l'ID sia corretto per la tua app Firebase!
const String _appId = '1:476854991127:web:a88a3ee55915a40bffdf52'; 
const String _baseCollectionPath = 'artifacts/$_appId/public/data/users';
// ----------------------------------------------------------------

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Riferimento alla collezione utenti basato sul percorso complesso
  CollectionReference get _userCollection => _db.collection(_baseCollectionPath);

  // --- Metodi di Lettura ---

  // Ottiene il profilo di un singolo utente in tempo reale (Stream). 
  // Usa l'UID dell'utente loggato come 'userId'.
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _userCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Usa il factory method UserProfile.fromFirestore(snapshot) 
        // che gestisce i campi mancanti (name, email) con placeholder.
        return UserProfile.fromFirestore(snapshot);
      }
      // Se il documento non esiste (l'utente non ha ancora un profilo), restituisce null.
      return null;
    });
  }

  // Ottiene tutti i profili utente (utile per il matching/elenco)
  Stream<List<UserProfile>> streamAllUsers() {
    return _userCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data() != null) // Filtra documenti vuoti
          .map((doc) => UserProfile.fromFirestore(doc))
          // MODIFICA: Filtra utenti che non hanno completato l'onboarding o hanno un nome vuoto, 
          // per non mostrarli nella lista dei potenziali match.
          .where((profile) => profile.onboardingCompleted && profile.name.isNotEmpty)
          .toList();
    });
  }

  // --- Metodi di Scrittura ---
  
  // Crea o aggiorna il profilo di un utente
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      // Usa SetOptions(merge: true) per evitare di sovrascrivere l'intero documento
      await _userCollection.doc(profile.userId).set(profile.toMap(), SetOptions(merge: true));
      debugPrint('Profilo utente ${profile.userId} salvato con successo.');
    } catch (e) {
      debugPrint('Errore nel salvataggio del profilo per ${profile.userId}: $e');
      rethrow;
    }
  }
}