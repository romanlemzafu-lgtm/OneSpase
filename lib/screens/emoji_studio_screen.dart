import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';

class EmojiStudioScreen extends StatefulWidget {
  const EmojiStudioScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<EmojiStudioScreen> createState() => _EmojiStudioScreenState();
}

class _EmojiStudioScreenState extends State<EmojiStudioScreen> {
  final _title = TextEditingController();
  final _slug = TextEditingController();
  final _emojis = TextEditingController(text: '🚀 💜 🌙 🎮');
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _emojis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emoji Studio', style: TextStyle(fontWeight: FontWeight.w900))),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Создать свой emoji-пак', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 6),
                      const Text('В v0.6 — Unicode emoji-паки. Загрузка собственных PNG/WebP будет следующим этапом.', style: TextStyle(color: OneSpaseTheme.textSecondary, height: 1.35)),
                      const SizedBox(height: 14),
                      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Название')),
                      const SizedBox(height: 10),
                      TextField(controller: _slug, decoration: const InputDecoration(labelText: 'Короткое имя', prefixText: '@')),
                      const SizedBox(height: 10),
                      TextField(controller: _emojis, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Emoji через пробел')),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy ? null : _create,
                        icon: const Icon(Icons.add_reaction_rounded),
                        label: Text(_busy ? 'Создаю…' : 'Создать пак'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Мои паки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (widget.controller.emojiPacks.isEmpty)
                const Text('Пока нет паков.', style: TextStyle(color: OneSpaseTheme.textSecondary))
              else
                ...widget.controller.emojiPacks.map(
                  (pack) => Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      title: Text(pack.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('@${pack.slug}  •  ${pack.emojis.join(' ')}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    final slug = _slug.text.trim().replaceAll('@', '').toLowerCase();
    final emojis = _emojis.text
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (title.length < 2 || slug.length < 3 || emojis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполни название, короткое имя и хотя бы один emoji.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.createEmojiPack(title: title, slug: slug, emojis: emojis);
      if (mounted) {
        _title.clear();
        _slug.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emoji-пак создан.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
