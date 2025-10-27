import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../theme/brand_palette.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late List<Message> messages;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.chat.messages);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add(Message(isMe: true, text: text, time: "Ora")));
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 60), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background con gradiente
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
          // Veil per leggibilità
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.10))),

          SafeArea(
            child: Column(
              children: [
                // Header glass
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: _Glass(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Back
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: BrandPalette.purple),
                          tooltip: 'Indietro',
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(backgroundImage: NetworkImage(widget.chat.avatar), radius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chat.name,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const SizedBox(width: 2),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: BrandPalette.amber, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Online', style: tt.labelSmall?.copyWith(color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert, color: BrandPalette.purple),
                          tooltip: 'Altro',
                        ),
                      ],
                    ),
                  ),
                ),

                // Messaggi
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isMe = m.isMe;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _Bubble(
                            isMe: isMe,
                            text: m.text,
                            time: m.time,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Composer
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: _Glass(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.add_circle_outline, color: BrandPalette.purple),
                          tooltip: 'Allega',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Scrivi un messaggio…',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(18)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SendButton(onTap: _send),
                      ],
                    ),
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

/// Bolla messaggio coerente col tema
class _Bubble extends StatelessWidget {
  const _Bubble({required this.isMe, required this.text, required this.time});

  final bool isMe;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (isMe) {
      // Bolla con gradiente brand per i messaggi dell’utente
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: BrandPalette.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: tt.bodyMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: tt.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Bolla chiara con bordo soft per i messaggi dell’altro
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6E6EA)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: tt.bodyMedium?.copyWith(color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: tt.labelSmall?.copyWith(color: Colors.black45, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

/// Bottone invio con micro-animazione e gradiente
class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressed ? 0.96 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: BrandPalette.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.send, color: Colors.white, size: 20),
        ),
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
