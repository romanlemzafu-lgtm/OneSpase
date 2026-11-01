import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  await controller.load();

  runApp(OneSpaseApp(controller: controller));
}

class OneSpaseApp extends StatelessWidget {
  const OneSpaseApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OneSpase',
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.dark,
            ).copyWith(
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: const Color(0xFFBFC3C8),
              surface: const Color(0xFF17191E),
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0C0F),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF17191E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.white54),
              ),
            ),
          ),
          home: controller.userName == null
              ? AuthScreen(controller: controller)
              : HomeShell(controller: controller),
        );
      },
    );
  }
}
