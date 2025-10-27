import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat.dart';
import 'dart:convert';
import '../../theme/brand_palette.dart';

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
    final jsonString = await rootBundle.loadString('assets/data/chats.json');
    final jsonList = json.decode(jsonString) as List<dynamic>;
    setState(() => chats = jsonList.map((e) => Chat.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Chat', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(chat.avatar), radius: 25),
            title: Text(chat.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat.timestamp, style: tt.labelSmall?.copyWith(color: Colors.black45)),
                if (chat.unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: BrandPalette.purple, shape: BoxShape.circle),
                    child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            onTap: () => context.go('/chat/${chat.id}', extra: chat),
          );
        },
      ),
    );
  }
}
