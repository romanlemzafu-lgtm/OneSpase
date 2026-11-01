import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/chat_message.dart';
import '../models/remote_chat.dart';
import '../theme/onespase_theme.dart';
import '../widgets/verification_badge.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.chatId,
    required this.title,
    this.remote = false,
    this.online = false,
    this.verification = 'none',
  });

  final AppController controller;
  final String chatId;
  final String title;
  final bool remote;
  final bool online;
  final String verification;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _message = TextEditingController();
  Stream<List<RemoteMessage>>? _remoteStream;

  @override
  void initState() {
    super.initState();
    if (widget.remote) {
      _remoteStream = widget.controller.remoteMessageStream(widget.chatId);
      widget.controller.markConversationRead(widget.chatId);
    }
  }

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
                widget.title.isEmpty ? '?' : widget.title[0].toUpperCase(),
                style: const TextStyle(
                  color: OneSpaseTheme.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      VerificationBadge(type: widget.verification, size: 16),
                    ],
                  ),
                  Text(
                    widget.remote
                        ? (widget.online ? 'в сети' : 'не в сети')
                        : 'демо-чат',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.online
                          ? OneSpaseTheme.accent
                          : OneSpaseTheme.textSecondary,
                    ),
                  ),
                ],
              ),
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
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.remote ? _remoteMessages() : _demoMessages(),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _remoteMessages() {
    return StreamBuilder<List<RemoteMessage>>(
      stream: _remoteStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <RemoteMessage>[];
        final hasUnreadIncoming = messages.any(
          (message) =>
              message.senderId != widget.controller.currentUserId &&
              message.readAt == null,
        );
        if (hasUnreadIncoming) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.markConversationRead(widget.chatId);
          });
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Напиши первое сообщение 👋',
              style: TextStyle(color: OneSpaseTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final fromMe = message.senderId == widget.controller.currentUserId;
            return _RemoteMessageBubble(
              message: message,
              fromMe: fromMe,
              onLongPress: fromMe ? () => _messageMenu(message) : null,
            );
          },
        );
      },
    );
  }

  Widget _demoMessages() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final messages = widget.controller.chats[widget.chatId] ?? [];
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _DemoMessageBubble(message: messages[index]);
          },
        );
      },
    );
  }

  Widget _composer() {
    return SafeArea(
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
    );
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    _message.clear();
    try {
      if (widget.remote) {
        await widget.controller.sendRemoteMessage(widget.chatId, text);
      } else {
        await widget.controller.sendMessage(widget.chatId, text);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _messageMenu(RemoteMessage message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(sheetContext);
                _editMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Удалить'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await widget.controller.deleteRemoteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(RemoteMessage message) async {
    final editor = TextEditingController(text: message.body);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: editor,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editor.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (value != null && value.trim().isNotEmpty) {
      await widget.controller.editRemoteMessage(message.id, value);
    }
  }

  void _planned(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature добавим следующим апдейтом.')),
    );
  }
}

class _RemoteMessageBubble extends StatelessWidget {
  const _RemoteMessageBubble({
    required this.message,
    required this.fromMe,
    this.onLongPress,
  });

  final RemoteMessage message;
  final bool fromMe;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: fromMe
                ? OneSpaseTheme.accentSoft
                : OneSpaseTheme.surfaceRaised,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(fromMe ? 20 : 5),
              bottomRight: Radius.circular(fromMe ? 5 : 20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  message.body,
                  style: const TextStyle(fontSize: 16, height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              if (message.editedAt != null)
                const Text(
                  'изм. ',
                  style: TextStyle(
                    fontSize: 9,
                    color: OneSpaseTheme.textSecondary,
                  ),
                ),
              Text(
                _time(message.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: OneSpaseTheme.textSecondary,
                ),
              ),
              if (fromMe) ...[
                const SizedBox(width: 3),
                Icon(
                  message.readAt == null
                      ? Icons.done_rounded
                      : Icons.done_all_rounded,
                  size: 14,
                  color: OneSpaseTheme.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _DemoMessageBubble extends StatelessWidget {
  const _DemoMessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.fromMe
              ? OneSpaseTheme.accentSoft
              : OneSpaseTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(message.text),
      ),
    );
  }
}
