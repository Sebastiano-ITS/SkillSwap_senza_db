import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/chat.dart';
import '../../theme/brand_palette.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> chats = [];
  List<Chat> filtered = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadChats();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> loadChats() async {
    final jsonString = await rootBundle.loadString('assets/data/chats.json');
    final jsonList = json.decode(jsonString) as List<dynamic>;
    final list = jsonList.map((e) => Chat.fromJson(e)).toList();
    setState(() {
      chats = list;
      filtered = list;
    });
  }

  void _onSearchChanged() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      filtered = q.isEmpty
          ? chats
          : chats.where((c) => c.name.toLowerCase().contains(q) || c.lastMessage.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background brand
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [BrandPalette.amber, BrandPalette.orange, BrandPalette.magenta, BrandPalette.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Velatura per leggibilità
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.12))),
          SafeArea(
            child: Column(
              children: [
                // AppBar custom con glass
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: _Glass(
                    borderRadius: 16,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_rounded, color: BrandPalette.purple),
                        const SizedBox(width: 10),
                        Text(
                          'Chat',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: BrandPalette.purple,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        // eventuale action
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz, color: BrandPalette.purple),
                          tooltip: 'Altro',
                        ),
                      ],
                    ),
                  ),
                ),

                // Barra di ricerca glass
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _Glass(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Cerca conversazioni…',
                        prefixIcon: Icon(Icons.search, color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // Lista chat
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _Glass(
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined, size: 42, color: BrandPalette.purple),
                            const SizedBox(height: 12),
                            Text(
                              'Nessuna chat trovata',
                              style: tt.titleMedium?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Prova a cercare per nome o contenuto.',
                              style: tt.bodyMedium?.copyWith(color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      return _Glass(
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(chat.avatar),
                          ),
                          title: Text(
                            chat.name,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                chat.timestamp,
                                style: tt.labelSmall?.copyWith(color: Colors.black45),
                              ),
                              if (chat.unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: BrandPalette.primaryGradient,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${chat.unread}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => context.go('/chat/${chat.id}', extra: chat),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenitore riutilizzabile con effetto glass coerente
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: BrandPalette.subtleBg,
            color: Colors.white.withOpacity(0.20),
            border: BrandPalette.glassBorder,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: BrandPalette.softShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
