import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/remote_chat.dart';
import '../theme/onespase_theme.dart';
import '../widgets/verification_badge.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.controller.isOnlineAccount) {
      widget.controller.refreshConversations();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isOnlineAccount) {
          final items = widget.controller.remoteConversations.where((item) {
            final q = _query.toLowerCase();
            return item.peerName.toLowerCase().contains(q) ||
                item.peerUsername.toLowerCase().contains(q);
          }).toList();

          return RefreshIndicator(
            onRefresh: widget.controller.refreshConversations,
            child: CustomScrollView(
              slivers: [
                _appBar(),
                _searchBox(),
                if (widget.controller.conversationsBusy && items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'Пока нет диалогов. Найди человека во вкладке «Люди».',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: OneSpaseTheme.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _RemoteChatTile(
                          item: item,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  controller: widget.controller,
                                  chatId: item.id,
                                  title: item.peerName,
                                  remote: true,
                                  online: item.peerOnline,
                                  verification: item.verification,
                                ),
                              ),
                            );
                            widget.controller.refreshConversations();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }

        final entries = widget.controller.chatTitles.entries.where((entry) {
          return entry.value.toLowerCase().contains(_query.toLowerCase());
        }).toList();

        return CustomScrollView(
          slivers: [
            _appBar(),
            _searchBox(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _DemoChatTile(
                    title: entry.value,
                    subtitle: widget.controller.lastMessage(entry.key),
                    online: entry.key != 'team',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            controller: widget.controller,
                            chatId: entry.key,
                            title: entry.value,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  SliverAppBar _appBar() => SliverAppBar(
        floating: true,
        title: const Text('Чаты', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.controller.isOnlineAccount)
            IconButton(
              tooltip: 'Обновить',
              onPressed: widget.controller.refreshConversations,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      );

  SliverPadding _searchBox() => SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        sliver: SliverToBoxAdapter(
          child: TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Поиск по чатам',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
      );
}

class _RemoteChatTile extends StatelessWidget {
  const _RemoteChatTile({required this.item, required this.onTap});
  final RemoteConversation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: OneSpaseTheme.surfaceRaised,
                    child: Text(
                      item.peerName.isEmpty ? '?' : item.peerName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: OneSpaseTheme.accent,
                      ),
                    ),
                  ),
                  if (item.peerOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: OneSpaseTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: OneSpaseTheme.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.peerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        VerificationBadge(type: item.verification, size: 17),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.lastMessage.isEmpty ? 'Начните общение' : item.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OneSpaseTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _time(item.lastMessageAt),
                style: const TextStyle(
                  color: OneSpaseTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _DemoChatTile extends StatelessWidget {
  const _DemoChatTile({
    required this.title,
    required this.subtitle,
    required this.online,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 27,
        backgroundColor: OneSpaseTheme.surfaceRaised,
        child: Text(title[0].toUpperCase()),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: OneSpaseTheme.textSecondary),
      ),
      trailing: Icon(
        online ? Icons.circle : Icons.circle_outlined,
        size: 11,
        color: online ? OneSpaseTheme.success : OneSpaseTheme.textSecondary,
      ),
    );
  }
}
