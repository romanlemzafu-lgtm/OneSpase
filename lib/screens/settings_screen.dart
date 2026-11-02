import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
import 'account_manager_screen.dart';
import 'admin/owner_panel_screen.dart';
import 'emoji_studio_screen.dart';
import 'profile_customization_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
        children: [
          _tile(context, Icons.switch_account_rounded, 'Аккаунты', 'Добавить второй аккаунт и переключаться', const Color(0xFF55A8FF), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AccountManagerScreen(controller: controller)));
          }),
          _tile(context, Icons.palette_rounded, 'Оформление профиля', 'Тема, emoji-status, музыка, канал', OneSpaseTheme.accent, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileCustomizationScreen(controller: controller)));
          }),
          _tile(context, Icons.add_reaction_rounded, 'Emoji Studio', 'Создавай свои emoji-паки', const Color(0xFFFFA726), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EmojiStudioScreen(controller: controller)));
          }),
          _tile(context, Icons.key_rounded, 'Конфиденциальность', 'Онлайн, блокировки, кто может писать', const Color(0xFF47D268), () {}),
          _tile(context, Icons.notifications_outlined, 'Уведомления', 'Сообщения, реакции, подарки', const Color(0xFFFF5D73), () {}),
          _tile(context, Icons.storage_rounded, 'Данные и память', 'Кэш и загрузка медиа', const Color(0xFF5F82FF), () {}),
          if (controller.isOwner) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFF3B4D), size: 30),
                title: const Text('Owner Panel', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Галочки, журнал и защищённые юзернеймы', style: TextStyle(color: OneSpaseTheme.textSecondary)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerPanelScreen(controller: controller))),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(controller.isOnlineAccount ? Icons.cloud_done_outlined : Icons.science_outlined, color: OneSpaseTheme.accent),
              title: Text(controller.isOnlineAccount ? 'OneSpase Online' : 'Демо-режим', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(controller.isOnlineAccount ? 'Профиль и чаты подключены к Supabase.' : 'Демо не синхронизируется между устройствами.', style: const TextStyle(color: OneSpaseTheme.textSecondary)),
            ),
          ),
          if (controller.currentUserId != null) ...[
            const SizedBox(height: 10),
            SelectableText('ID аккаунта: ${controller.currentUserId}', style: const TextStyle(color: OneSpaseTheme.textSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await controller.logout();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти из этого аккаунта'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: OneSpaseTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
