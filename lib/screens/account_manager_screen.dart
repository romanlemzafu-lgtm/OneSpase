import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';

class AccountManagerScreen extends StatelessWidget {
  const AccountManagerScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аккаунты', style: TextStyle(fontWeight: FontWeight.w900))),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.switch_account_rounded, color: OneSpaseTheme.accent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Можно держать несколько аккаунтов на одном телефоне. Сессии хранятся в защищённом хранилище устройства.', style: TextStyle(height: 1.35)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...controller.accountSlots.map((slot) {
                final active = slot.userId == controller.currentUserId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(slot.label.isEmpty ? '?' : slot.label[0].toUpperCase())),
                    title: Row(
                      children: [
                        Expanded(child: Text(slot.label, style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (active) const Icon(Icons.check_circle_rounded, color: OneSpaseTheme.success, size: 18),
                      ],
                    ),
                    subtitle: Text('@${slot.username}${slot.email == null ? '' : ' • ${slot.email}'}'),
                    onTap: active ? null : () async {
                      await controller.switchAccount(slot.userId);
                      if (context.mounted && controller.currentUserId == slot.userId) Navigator.pop(context);
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'remove') await controller.removeSavedAccount(slot.userId);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'remove', child: Text('Удалить с устройства')),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  await controller.prepareAddAccount();
                  if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Добавить второй аккаунт'),
              ),
            ],
          );
        },
      ),
    );
  }
}
