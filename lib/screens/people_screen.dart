import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/social_profile.dart';
import '../theme/onespase_theme.dart';

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
    _load('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
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
          title: Text(
            'Люди',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: _search,
              autocorrect: false,
              onChanged: _load,
              decoration: const InputDecoration(
                hintText: 'Имя или @username',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  widget.controller.onlineConfigured
                      ? 'Поиск OneSpase'
                      : 'Демо-пользователи',
                  style: const TextStyle(
                    color: OneSpaseTheme.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
          sliver: SliverList.builder(
            itemCount: _results.length,
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
      backgroundColor: OneSpaseTheme.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: OneSpaseTheme.accentSoft,
                child: Text(
                  profile.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: OneSpaseTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profile.displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                '@${profile.username}',
                style: const TextStyle(color: OneSpaseTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                profile.status,
                style: TextStyle(
                  color: profile.online
                      ? OneSpaseTheme.accent
                      : OneSpaseTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Настоящий старт диалога подключим к таблице conversations.',
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
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
      title: Text(
        profile.displayName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        profile.online ? 'в сети' : profile.status,
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
