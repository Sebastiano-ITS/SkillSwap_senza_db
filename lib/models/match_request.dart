// Modello che rappresenta una richiesta di match tra utenti
class MatchRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String skillRequested;
  final String message;
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

  // Crea un'istanza di MatchRequest a partire da una mappa
  factory MatchRequest.fromMap(Map<String, dynamic> data, String id) {
    return MatchRequest(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonimo',
      receiverId: data['receiverId'] ?? '',
      skillRequested: data['skillRequested'] ?? 'Sconosciuta',
      message: data['message'] ?? '',
      timestamp: DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      accepted: data['accepted'] ?? false,
    );
  }

  // Converte l'oggetto in una mappa, utile per il salvataggio su file o database
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'skillRequested': skillRequested,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'accepted': accepted,
    };
  }
}