// Modello per un messaggio nella conversazione
class Message {
  // Indica se il messaggio è stato inviato dall'utente corrente
  final bool isMe;

  // Testo del messaggio
  final String text;

  // Ora del messaggio
  final String time;

  Message({
    required this.isMe,
    required this.text,
    required this.time,
  });

  // Costruttore factory per creare un oggetto da JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      isMe: json['isMe'],
      text: json['text'],
      time: json['time'],
    );
  }
}

// Modello per una chat nella lista principale
class Chat {
  // ID univoco della chat
  final int id;

  // Nome del contatto
  final String name;

  // URL o path dell'immagine profilo
  final String avatar;

  // Ultimo messaggio visibile nella preview
  final String lastMessage;

  // Orario dell'ultimo messaggio
  final String timestamp;

  // Numero di messaggi non letti
  final int unread;

  // Lista dei messaggi nella conversazione
  final List<Message> messages;

  Chat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
    required this.messages,
  });

  // Costruttore factory per creare una Chat da JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    var messageList = json['messages'] as List;

    // Converte ogni elemento JSON in un oggetto Message
    List<Message> messagesList = messageList.map((item) => Message.fromJson(item)).toList();

    return Chat(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'],
      unread: json['unread'],
      messages: messagesList,
    );
  }
}