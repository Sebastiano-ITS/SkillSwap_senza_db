import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart'; 
import '../models/match_request.dart'; // IMPORT NECESSARIO

// Assumiamo che queste variabili siano state inizializzate nel tuo ambiente Flutter/Firebase
final FirebaseFirestore _db = FirebaseFirestore.instance;

// Variabile globale per l'ID dell'app, essenziale per la sicurezza di Firestore
const String __app_id = 'skillswap-gemini-app'; // Sostituisci con il tuo ID reale se necessario

class FirestoreService {
  // Metodo per ottenere tutti i profili utente in tempo reale
  Stream<List<UserProfile>> streamAllUsers() {
    // Percorso della collezione pubblica come definito dalle regole di sicurezza
    final userProfileCollection = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('user_profiles');
    
    return userProfileCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
    });
  }
  
  // Metodo per ottenere un singolo profilo utente
  Stream<UserProfile?> streamUserProfile(String userId) {
    final docRef = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('user_profiles').doc(userId);
    
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot);
    });
  }

  // Metodo per salvare o aggiornare un profilo (usato in Onboarding)
  Future<void> saveUserProfile(UserProfile user) async {
    final docRef = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('user_profiles').doc(user.userId);
    await docRef.set(user.toMap(), SetOptions(merge: true));
  }

  // --- NUOVI METODI PER LA GESTIONE DELLE RICHIESTE ---
  
  // 1. Invia una richiesta di match
  Future<void> sendMatchRequest(MatchRequest request) async {
    final requestCollection = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('match_requests'); 
    await requestCollection.add(request.toMap());
  }

  // 2. Ottieni le richieste ricevute in tempo reale per un dato ricevente
  Stream<List<MatchRequest>> streamReceivedRequests(String receiverId) {
    final requestCollection = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('match_requests'); 
    
    // Filtra per il destinatario e mostra solo quelle NON ancora accettate
    return requestCollection
        .where('receiverId', isEqualTo: receiverId)
        .where('accepted', isEqualTo: false) // Mostra solo quelle in sospeso
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MatchRequest.fromFirestore(doc)).toList();
        });
  }

  // 3. Aggiorna lo stato di una richiesta (es. accettarla)
  Future<void> updateRequestStatus(String requestId, bool accepted) async {
    final docRef = _db.collection('artifacts').doc(__app_id).collection('public').doc('data').collection('match_requests').doc(requestId);
    await docRef.update({'accepted': accepted, 'acceptanceTimestamp': FieldValue.serverTimestamp()});
  }
}
