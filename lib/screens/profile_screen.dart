import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
import 'settings_screen.dart';

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
            SliverAppBar(
              floating: true,
              title: const Text(
                'Профиль',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                IconButton(
                  tooltip: 'Настройки',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: OneSpaseTheme.accentSoft,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: OneSpaseTheme.accent,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            bottom: 3,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: OneSpaseTheme.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: OneSpaseTheme.background,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Center(
                      child: Text(
                        '@$handle',
                        style: const TextStyle(
                          color: OneSpaseTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        controller.status,
                        style: const TextStyle(
                          color: OneSpaseTheme.accent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Фото',
                            onTap: () => _planned(context, 'Аватарки'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileButton(
                            icon: Icons.edit_rounded,
                            label: 'Изменить',
                            onTap: () => _editProfile(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileButton(
                            icon: Icons.settings_rounded,
                            label: 'Настройки',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SettingsScreen(controller: controller),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoLine(
                              value: controller.bio,
                              label: 'О себе',
                            ),
                            const SizedBox(height: 16),
                            _InfoLine(
                              value: '@$handle',
                              label: 'Имя пользователя',
                            ),
                            const SizedBox(height: 16),
                            _InfoLine(
                              value: joined == null
                                  ? 'сегодня'
                                  : '${joined.day.toString().padLeft(2, '0')}.${joined.month.toString().padLeft(2, '0')}.${joined.year}',
                              label: 'В OneSpase с',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(value: '12', label: 'Постов'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStat(value: '4', label: 'Друзей'),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStat(value: '7', label: 'Подписок'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Публикации',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...controller.posts
                        .where((post) => post.author == name)
                        .map(
                          (post) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  post.text,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final bio = TextEditingController(text: controller.bio);
    final status = TextEditingController(text: controller.status);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OneSpaseTheme.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            6,
            18,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Редактировать профиль',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: status,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'О себе'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await controller.updateStatus(status.text);
                  await controller.updateBio(bio.text);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );

    bio.dispose();
    status.dispose();
  }

  void _planned(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature появятся позже.')),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: OneSpaseTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: OneSpaseTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: OneSpaseTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: OneSpaseTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
