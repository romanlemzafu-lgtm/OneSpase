import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
import 'admin/owner_panel_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(
        Icons.person_outline_rounded,
        'Аккаунт',
        'Профиль, @username, статус',
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
        'Онлайн, блокировки, кто может писать',
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
          if (controller.isOwner) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFFFF3B4D),
                  size: 30,
                ),
                title: const Text(
                  'Owner Panel',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Галочки и журнал действий',
                  style: TextStyle(color: OneSpaseTheme.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OwnerPanelScreen(controller: controller),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                controller.isOnlineAccount
                    ? Icons.cloud_done_outlined
                    : Icons.science_outlined,
                color: OneSpaseTheme.accent,
              ),
              title: Text(
                controller.isOnlineAccount
                    ? 'OneSpase Online'
                    : 'Демо-режим',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                controller.isOnlineAccount
                    ? 'Аккаунт подключён к Supabase. Реальные пользователи и чаты доступны.'
                    : 'Демо не синхронизируется между устройствами.',
                style: const TextStyle(color: OneSpaseTheme.textSecondary),
              ),
            ),
          ),
          if (controller.currentUserId != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              'ID аккаунта: ${controller.currentUserId}',
              style: const TextStyle(
                color: OneSpaseTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
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
  const _SettingItem(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
