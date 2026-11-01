import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme/onespase_theme.dart';
import 'chats_screen.dart';
import 'feed_screen.dart';
import 'notifications_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(controller: widget.controller),
      ChatsScreen(controller: widget.controller),
      PeopleScreen(controller: widget.controller),
      const NotificationsScreen(),
      ProfileScreen(controller: widget.controller),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            height: 72,
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dynamic_feed_outlined),
                selectedIcon: Icon(Icons.dynamic_feed_rounded),
                label: 'Лента',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Чаты',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Люди',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'События',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton(
              backgroundColor: OneSpaseTheme.accent,
              foregroundColor: Colors.white,
              onPressed: () => setState(() => _index = 2),
              child: const Icon(Icons.add_comment_rounded),
            )
          : null,
    );
  }
}
