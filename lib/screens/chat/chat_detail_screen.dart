import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../theme/brand_palette.dart'; // <-- usa i colori brand

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late List<Message> messages;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.chat.messages);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.chat.avatar), radius: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chat.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('Online', style: tt.labelSmall?.copyWith(color: BrandPalette.amber)),
              ],
            ),
          ],
        ),
        // niente background/elevation: eredita AppBarTheme
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final bubbleColor = m.isMe ? cs.primary : cs.surface;
                final textColor = m.isMe ? cs.onPrimary : cs.onSurface;

                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(20),
                      border: m.isMe ? null : Border.all(color: const Color(0xFFE6E6EA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text, style: tt.bodyMedium?.copyWith(color: textColor)),
                        const SizedBox(height: 4),
                        Text(
                          m.time,
                          style: tt.labelSmall?.copyWith(
                            color: m.isMe ? Colors.white70 : Colors.black45,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: const Border(top: BorderSide(color: Color(0xFFE6E6EA))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(25))),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: BrandPalette.purple,
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      final msg = Message(isMe: true, text: _controller.text, time: "Ora");
                      setState(() => messages.add(msg));
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
