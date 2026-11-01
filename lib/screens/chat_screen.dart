import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/chat_message.dart';
import '../theme/onespase_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.chatId,
    required this.title,
  });

  final AppController controller;
  final String chatId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: OneSpaseTheme.accentSoft,
              child: Text(
                widget.title[0].toUpperCase(),
                style: const TextStyle(
                  color: OneSpaseTheme.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'в сети',
                  style: TextStyle(
                    fontSize: 12,
                    color: OneSpaseTheme.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Позвонить',
            onPressed: () => _planned('Голосовые звонки'),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Видео',
            onPressed: () => _planned('Видеозвонки'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final messages = widget.controller.chats[widget.chatId] ?? [];
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OneSpaseTheme.background,
                        Color(0xFF111016),
                      ],
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: messages[index]);
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  color: OneSpaseTheme.background,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _planned('Вложения'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Сообщение',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: OneSpaseTheme.accent,
                        ),
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    final text = _message.text;
    if (text.trim().isEmpty) return;
    _message.clear();
    await widget.controller.sendMessage(widget.chatId, text);
  }

  void _planned(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature появятся в следующем этапе.')),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        decoration: BoxDecoration(
          color: message.fromMe
              ? OneSpaseTheme.accentSoft
              : OneSpaseTheme.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.fromMe ? 20 : 5),
            bottomRight: Radius.circular(message.fromMe ? 5 : 20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 10,
                color: OneSpaseTheme.textSecondary,
              ),
            ),
            if (message.fromMe) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.done_all_rounded,
                size: 14,
                color: OneSpaseTheme.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
