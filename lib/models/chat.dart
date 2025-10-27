
// Modello per un messaggio nella conversazione
class Message {
  final bool isMe;
  final String text;
  final String time;

  Message({required this.isMe, required this.text, required this.time});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      isMe: json['isMe'],
      text: json['text'],
      time: json['time'],
    );
  }
}

// Modello per una chat nella lista
class Chat {
  final int id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final int unread;
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

  factory Chat.fromJson(Map<String, dynamic> json) {
    var messageList = json['messages'] as List;
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