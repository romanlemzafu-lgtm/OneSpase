import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(
        Icons.person_outline_rounded,
        'Аккаунт',
        'Почта, @username, описание',
        const Color(0xFF55A8FF),
      ),
      _SettingItem(
        Icons.chat_bubble_outline_rounded,
        'Настройки чатов',
        'Фон, размер текста, анимации',
        const Color(0xFFFFA726),
      ),
      _SettingItem(
        Icons.key_rounded,
        'Конфиденциальность',
        'Онлайн, блокировки, устройства',
        const Color(0xFF47D268),
      ),
      _SettingItem(
        Icons.notifications_outlined,
        'Уведомления',
        'Звуки, сообщения, события',
        const Color(0xFFFF5D73),
      ),
      _SettingItem(
        Icons.storage_rounded,
        'Данные и память',
        'Кэш и загрузка медиа',
        const Color(0xFF5F82FF),
      ),
      _SettingItem(
        Icons.devices_rounded,
        'Устройства',
        'Активные сеансы OneSpase',
        const Color(0xFF42C4D6),
      ),
      _SettingItem(
        Icons.language_rounded,
        'Язык',
        'Русский',
        OneSpaseTheme.accent,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
        children: [
          Card(
            child: Column(
              children: items
                  .map(
                    (item) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(item.icon, color: Colors.white),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: OneSpaseTheme.textSecondary,
                        ),
                      ),
                      onTap: () {},
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(
                Icons.cloud_done_outlined,
                color: OneSpaseTheme.accent,
              ),
              title: Text(
                controller.onlineConfigured
                    ? 'OneSpase Online подключён'
                    : 'Сейчас демо-режим',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                controller.onlineConfigured
                    ? 'Эта сборка знает адрес Supabase и может использовать email-коды.'
                    : 'Добавь SUPABASE_URL и SUPABASE_ANON_KEY в GitHub Secrets для онлайн-сборки.',
                style: const TextStyle(color: OneSpaseTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await controller.logout();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  const _SettingItem(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
  );

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
