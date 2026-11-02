import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/social_profile.dart';
import '../theme/onespase_theme.dart';
import '../widgets/verification_badge.dart';
import 'chat_screen.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _search = TextEditingController();
  List<SocialProfile> _results = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() => _busy = true);
    final result = await widget.controller.searchPeople(query);
    if (!mounted) return;
    setState(() {
      _results = result;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('Люди', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _search,
              onChanged: _runSearch,
              decoration: const InputDecoration(
                hintText: 'Имя или @username',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
        if (_busy)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_results.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  'Никого не нашли',
                  style: TextStyle(color: OneSpaseTheme.textSecondary),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
            sliver: SliverList.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final profile = _results[index];
                return _PersonTile(
                  profile: profile,
                  onTap: () => _showProfile(profile),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showProfile(SocialProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: OneSpaseTheme.accentSoft,
                  child: Text(
                    profile.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: OneSpaseTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    VerificationBadge(type: profile.verification, size: 21),
                  ],
                ),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(color: OneSpaseTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.online ? 'в сети' : profile.status,
                  style: TextStyle(
                    color: profile.online
                        ? OneSpaseTheme.accent
                        : OneSpaseTheme.textSecondary,
                  ),
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!widget.controller.isOnlineAccount) {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('В демо-режиме это только макет.')),
                            );
                            return;
                          }
                          final id = await widget.controller.startDirectChat(profile);
                          if (!mounted || id == null) return;
                          Navigator.pop(sheetContext);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                controller: widget.controller,
                                chatId: id,
                                title: profile.displayName,
                                remote: true,
                                verification: profile.verification,
                                online: profile.online,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text('Написать'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.controller.isOnlineAccount
                            ? () => _pickGift(sheetContext, profile)
                            : null,
                        icon: const Icon(Icons.card_giftcard_rounded),
                        label: const Text('Подарок'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Future<void> _pickGift(BuildContext sheetContext, SocialProfile profile) async {
    try {
      final catalog = await widget.controller.loadGiftCatalog();
      if (!mounted) return;
      if (catalog.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Каталог подарков пока пуст.')),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (giftContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            children: [
              Text('Подарок для @${profile.username}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...catalog.map((gift) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(gift.emoji, style: const TextStyle(fontSize: 34)),
                      title: Text(gift.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(gift.rarity.toUpperCase()),
                      onTap: () async {
                        await widget.controller.sendGift(profile: profile, gift: gift);
                        if (giftContext.mounted) Navigator.pop(giftContext);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${gift.emoji} Подарок отправлен @${profile.username}')),
                          );
                        }
                      },
                    ),
                  )),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.profile, required this.onTap});
  final SocialProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: OneSpaseTheme.surfaceRaised,
            child: Text(
              profile.displayName[0].toUpperCase(),
              style: const TextStyle(
                color: OneSpaseTheme.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (profile.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OneSpaseTheme.success,
                  border: Border.all(color: OneSpaseTheme.background, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              profile.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          VerificationBadge(type: profile.verification, size: 17),
        ],
      ),
      subtitle: Text(
        profile.online ? 'в сети' : profile.status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: profile.online
              ? OneSpaseTheme.accent
              : OneSpaseTheme.textSecondary,
        ),
      ),
      trailing: Text(
        '@${profile.username}',
        style: const TextStyle(
          color: OneSpaseTheme.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
