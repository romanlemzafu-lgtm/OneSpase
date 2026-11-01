import 'package:flutter/material.dart';

import '../app_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final name = controller.userName ?? 'Пользователь';
        final handle = controller.userHandle ?? 'user';
        final joined = controller.joinedAt;

        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('Профиль', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: const AssetImage('assets/images/onespase_icon.png'),
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(child: Text('@$handle', style: const TextStyle(color: Colors.white54))),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(controller.status),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      controller.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ),
                  if (joined != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'В OneSpase с ${joined.day.toString().padLeft(2, '0')}.${joined.month.toString().padLeft(2, '0')}.${joined.year}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.tonalIcon(
                    onPressed: () => _editBio(context),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Изменить описание'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _editStatus(context),
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Изменить статус'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: controller.logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Выйти из демо-профиля'),
                  ),
                  const SizedBox(height: 28),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cloud_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Сейчас данные сохраняются локально. Следующий этап — настоящие аккаунты и синхронизация между устройствами.',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editBio(BuildContext context) async {
    final textController = TextEditingController(text: controller.bio);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Описание профиля'),
        content: TextField(controller: textController, minLines: 2, maxLines: 5, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, textController.text), child: const Text('Сохранить')),
        ],
      ),
    );
    textController.dispose();
    if (result != null) await controller.updateBio(result);
  }

  Future<void> _editStatus(BuildContext context) async {
    final textController = TextEditingController(text: controller.status);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статус'),
        content: TextField(
          controller: textController,
          maxLength: 40,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Например: Играю 🎮'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, textController.text), child: const Text('Сохранить')),
        ],
      ),
    );
    textController.dispose();
    if (result != null) await controller.updateStatus(result);
  }
}
