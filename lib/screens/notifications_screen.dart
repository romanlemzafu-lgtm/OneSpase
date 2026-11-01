import 'package:flutter/material.dart';

import '../theme/onespase_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
      (Icons.favorite_rounded, 'OneSpase Dev оценил твою публикацию', '2 мин'),
      (Icons.person_add_alt_1_rounded, 'Новая заявка в друзья', '18 мин'),
      (Icons.mode_comment_rounded, 'Новый комментарий под постом', '1 ч'),
      (Icons.rocket_launch_rounded, 'Добро пожаловать в OneSpase v0.4', 'сегодня'),
    ];

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text(
            'События',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
          sliver: SliverList.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = events[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: OneSpaseTheme.accentSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(item.$1, color: OneSpaseTheme.accent),
                  ),
                  title: Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    item.$3,
                    style: const TextStyle(
                      color: OneSpaseTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
