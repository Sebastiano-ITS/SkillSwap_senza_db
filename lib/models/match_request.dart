class MatchRequest {
  final String id;
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

  // Factory per creare un oggetto da una Map
  factory MatchRequest.fromMap(Map<String, dynamic> data, String id) {
    return MatchRequest(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonimo',
      receiverId: data['receiverId'] ?? '',
      skillRequested: data['skillRequested'] ?? 'Sconosciuta',
      message: data['message'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      accepted: data['accepted'] ?? false,
    );
  }

  // Convertire l'oggetto in Map
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
