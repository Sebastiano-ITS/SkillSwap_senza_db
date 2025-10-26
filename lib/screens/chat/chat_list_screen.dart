import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat.dart';
import 'chat_detail_screen.dart';
import 'dart:convert';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    String jsonString = await rootBundle.loadString('assets/data/chats.json');
    List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      chats = jsonList.map((json) => Chat.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat.avatar),
              radius: 25,
            ),
            title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat.timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (chat.unread > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            onTap: () {
              context.go('/chat/${chat.id}', extra: chat);
            },
          );
        },
      ),
    );
  }
}