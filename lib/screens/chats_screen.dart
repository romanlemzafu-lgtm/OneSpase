import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final entries = widget.controller.chatTitles.entries.where((entry) {
          return entry.value.toLowerCase().contains(_query.toLowerCase());
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text(
                'Чаты',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
            SliverPadding(
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
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _ChatTile(
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
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
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
                      title[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: OneSpaseTheme.accent,
                      ),
                    ),
                  ),
                  if (online)
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: OneSpaseTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'сейчас',
                    style: TextStyle(
                      color: OneSpaseTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 8),
                  Icon(
                    Icons.done_all_rounded,
                    size: 18,
                    color: OneSpaseTheme.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
