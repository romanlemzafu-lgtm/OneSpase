import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
import '../widgets/verification_badge.dart';
import 'emoji_studio_screen.dart';
import 'gifts_screen.dart';
import 'profile_customization_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;

  Color _themeColor(String theme) => switch (theme) {
        'blue' => const Color(0xFF4C8DFF),
        'sunset' => const Color(0xFFFF7A45),
        'mint' => const Color(0xFF48D6AD),
        _ => OneSpaseTheme.accent,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final name = controller.userName ?? 'Пользователь';
        final handle = controller.userHandle ?? 'user';
        final accent = _themeColor(controller.profileTheme);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Профиль', style: TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                IconButton(
                  tooltip: 'Настройки',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsScreen(controller: controller)),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [accent.withOpacity(0.34), OneSpaseTheme.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundColor: OneSpaseTheme.surfaceRaised,
                          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: accent)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                            const SizedBox(width: 5),
                            VerificationBadge(type: controller.verification, size: 24),
                            if (controller.emojiStatus.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(controller.emojiStatus, style: const TextStyle(fontSize: 22)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('@$handle', style: const TextStyle(color: OneSpaseTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(controller.status, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                        if (controller.musicTitle.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(18)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.music_note_rounded, size: 18),
                                const SizedBox(width: 6),
                                Flexible(child: Text(controller.musicTitle, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Action(icon: Icons.palette_rounded, label: 'Оформление', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileCustomizationScreen(controller: controller))))),
                      const SizedBox(width: 8),
                      Expanded(child: _Action(icon: Icons.card_giftcard_rounded, label: 'Подарки', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftsScreen(controller: controller))))),
                      const SizedBox(width: 8),
                      Expanded(child: _Action(icon: Icons.add_reaction_rounded, label: 'Emoji', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmojiStudioScreen(controller: controller))))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('О себе', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(controller.bio, style: const TextStyle(height: 1.45)),
                        if (controller.featuredChannel.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(children: [
                            const Icon(Icons.campaign_rounded, color: OneSpaseTheme.accent, size: 20),
                            const SizedBox(width: 8),
                            Text('@${controller.featuredChannel}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _Stat(value: '${controller.posts.length}', label: 'публикаций')),
                    const SizedBox(width: 8),
                    Expanded(child: _Stat(value: '${controller.gifts.length}', label: 'подарков')),
                    const SizedBox(width: 8),
                    Expanded(child: _Stat(value: '${controller.emojiPacks.length}', label: 'emoji-паков')),
                  ]),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: OneSpaseTheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
            child: Column(children: [Icon(icon), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))]),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: OneSpaseTheme.textSecondary, fontSize: 11))]),
        ),
      );
}
