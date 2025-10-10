import 'package:cloud_firestore/cloud_firestore.dart';

class MatchRequest {
  final String id; // ID del documento Firestore
  final String senderId; // ID di chi invia (il Learner)
  final String senderName; // Nome di chi invia
  final String receiverId; // ID di chi riceve (il Teacher)
  final String skillRequested; // La competenza richiesta (es. 'Programmazione')
  final String message; // Messaggio opzionale del Learner
  final DateTime timestamp;
  final bool accepted;

  MatchRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.skillRequested,
    required this.message,
    required this.timestamp,
    this.accepted = false,
  });

  // Factory per creare un oggetto da un DocumentSnapshot di Firestore
  factory MatchRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception("Documento richiesta match vuoto!");
    }
    
    return MatchRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonimo',
      receiverId: data['receiverId'] ?? '',
      skillRequested: data['skillRequested'] ?? 'Sconosciuta',
      message: data['message'] ?? '',
      // Conversione sicura di Timestamp in DateTime
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(), 
      accepted: data['accepted'] ?? false,
    );
  }

  // Convertire l'oggetto in Map per Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'skillRequested': skillRequested,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'accepted': accepted,
    };
  }
}
