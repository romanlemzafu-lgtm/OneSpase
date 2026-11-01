import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_controller.dart';
import 'screens/auth/auth_flow_screen.dart';
import 'screens/home_shell.dart';
import 'services/supabase_service.dart';
import 'theme/onespase_theme.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final onlineConfigured =
      _supabaseUrl.trim().isNotEmpty && _supabaseAnonKey.trim().isNotEmpty;

  if (onlineConfigured) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  final controller = AppController(
    supabase: SupabaseService(enabled: onlineConfigured),
  );
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
          theme: OneSpaseTheme.dark(),
          home: controller.isSignedIn
              ? HomeShell(controller: controller)
              : AuthFlowScreen(controller: controller),
        );
      },
    );
  }
}
