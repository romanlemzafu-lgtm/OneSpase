import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';

class ProfileCustomizationScreen extends StatefulWidget {
  const ProfileCustomizationScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ProfileCustomizationScreen> createState() => _ProfileCustomizationScreenState();
}

class _ProfileCustomizationScreenState extends State<ProfileCustomizationScreen> {
  late String _theme;
  late final TextEditingController _emoji;
  late final TextEditingController _music;
  late final TextEditingController _channel;

  @override
  void initState() {
    super.initState();
    _theme = widget.controller.profileTheme;
    _emoji = TextEditingController(text: widget.controller.emojiStatus);
    _music = TextEditingController(text: widget.controller.musicTitle);
    _channel = TextEditingController(text: widget.controller.featuredChannel);
  }

  @override
  void dispose() {
    _emoji.dispose();
    _music.dispose();
    _channel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оформление профиля', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
        children: [
          const Text('Тема профиля', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['purple', 'blue', 'sunset', 'mint'].map((theme) {
              return ChoiceChip(
                label: Text(theme),
                selected: _theme == theme,
                onSelected: (_) => setState(() => _theme = theme),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emoji,
            maxLength: 8,
            decoration: const InputDecoration(labelText: 'Emoji-status', hintText: '🎧'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _music,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Музыка в профиле', hintText: 'Название трека'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _channel,
            maxLength: 50,
            decoration: const InputDecoration(labelText: 'Канал/сообщество в профиле', prefixText: '@'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await widget.controller.updateProfileCustomization(
                theme: _theme,
                newEmojiStatus: _emoji.text,
                newMusicTitle: _music.text,
                newFeaturedChannel: _channel.text.replaceAll('@', ''),
              );
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.palette_rounded),
            label: const Text('Сохранить оформление'),
          ),
        ],
      ),
    );
  }
}
