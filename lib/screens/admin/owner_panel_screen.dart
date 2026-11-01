import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../models/social_profile.dart';
import '../../theme/onespase_theme.dart';
import '../../widgets/verification_badge.dart';

class OwnerPanelScreen extends StatefulWidget {
  const OwnerPanelScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<OwnerPanelScreen> createState() => _OwnerPanelScreenState();
}

class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  final _search = TextEditingController();
  List<SocialProfile> _results = const [];
  List<Map<String, dynamic>> _audit = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshAudit();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _busy = true);
    final result = await widget.controller.searchPeople(query, includeSelf: true);
    if (!mounted) return;
    setState(() {
      _results = result;
      _busy = false;
    });
  }

  Future<void> _refreshAudit() async {
    try {
      final rows = await widget.controller.loadBadgeAudit();
      if (mounted) setState(() => _audit = rows);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isOwner) {
      return const Scaffold(
        body: Center(child: Text('Нет доступа к Owner Panel.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Owner Panel',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_rounded, color: OneSpaseTheme.accent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Панель владельца. Галочки выдаются через защищённую функцию Supabase и записываются в журнал.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: _runSearch,
            decoration: const InputDecoration(
              hintText: 'Найти по имени или @username',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Пользователи',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ..._results.map(_userCard),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Последние действия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: _refreshAudit,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_audit.isEmpty)
            const Text(
              'Журнал пока пуст.',
              style: TextStyle(color: OneSpaseTheme.textSecondary),
            )
          else
            ..._audit.take(20).map((row) {
              final badge = row['badge']?.toString() ?? 'none';
              final target = row['target_username']?.toString() ?? 'user';
              final reason = row['reason']?.toString();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: VerificationBadge(type: badge, size: 22),
                title: Text('@$target → $badge'),
                subtitle: reason == null || reason.isEmpty ? null : Text(reason),
              );
            }),
        ],
      ),
    );
  }

  Widget _userCard(SocialProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    profile.displayName.isEmpty
                        ? '?'
                        : profile.displayName[0].toUpperCase(),
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
                              profile.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 4),
                          VerificationBadge(type: profile.verification),
                        ],
                      ),
                      Text(
                        '@${profile.username}',
                        style: const TextStyle(
                          color: OneSpaseTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badgeButton(profile, 'blue', 'Синяя'),
                _badgeButton(profile, 'red', 'Красная'),
                _badgeButton(profile, 'purple', 'Фиолетовая'),
                _badgeButton(profile, 'none', 'Снять'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeButton(SocialProfile profile, String badge, String label) {
    return OutlinedButton.icon(
      onPressed: () => _confirmBadge(profile, badge),
      icon: badge == 'none'
          ? const Icon(Icons.remove_circle_outline_rounded)
          : VerificationBadge(type: badge),
      label: Text(label),
    );
  }

  Future<void> _confirmBadge(SocialProfile profile, String badge) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          badge == 'none'
              ? 'Снять галочку у @${profile.username}?'
              : 'Выдать $badge @${profile.username}?',
        ),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Причина (необязательно)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.controller.setVerificationBadge(
          profile: profile,
          badge: badge,
          reason: reason.text.trim(),
        );
        await _runSearch(_search.text);
        await _refreshAudit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Готово. Изменение записано в журнал.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
    reason.dispose();
  }
}
