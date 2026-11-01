import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../theme/onespase_theme.dart';

class AuthFlowScreen extends StatelessWidget {
  const AuthFlowScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return switch (controller.authStep) {
          AuthStep.choose => _ChooseStep(controller: controller),
          AuthStep.profile => _ProfileStep(controller: controller),
        };
      },
    );
  }
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x447A3CFF),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/onespase_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: OneSpaseTheme.textSecondary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChooseStep extends StatelessWidget {
  const _ChooseStep({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Добро пожаловать в OneSpase',
      subtitle: controller.onlineConfigured
          ? 'Вход без паролей: Google или быстрый гостевой аккаунт.'
          : 'Эта APK пока без Supabase. Можно открыть демо-интерфейс.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: controller.authBusy || !controller.onlineConfigured
                ? null
                : controller.startGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Продолжить с Google'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.authBusy || !controller.onlineConfigured
                ? null
                : controller.startGuest,
            icon: const Icon(Icons.person_outline_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Войти как гость'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: controller.authBusy ? null : controller.startDemo,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Открыть демо'),
          ),
          if (controller.authBusy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          if (controller.authError != null) ...[
            const SizedBox(height: 14),
            _ErrorBox(text: controller.authError!),
          ],
          const SizedBox(height: 18),
          const Text(
            'Гостевой аккаунт работает как настоящий онлайн-аккаунт, но его нельзя восстановить после удаления приложения или выхода. Позже его можно будет привязать к Google.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OneSpaseTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.controller});
  final AppController controller;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _status = TextEditingController(text: 'В OneSpase');

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Создай своё пространство',
      subtitle: 'Выбери имя, уникальный @username и короткий статус.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Имя',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _handle,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: '@username',
              prefixText: '@',
              helperText: 'Латиница, цифры и _',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _status,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Статус',
              counterText: '',
              prefixIcon: Icon(Icons.bolt_rounded),
            ),
          ),
          if (widget.controller.authError != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(text: widget.controller.authError!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: widget.controller.authBusy ? null : _save,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('В OneSpase'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() => widget.controller.completeProfile(
        name: _name.text,
        handle: _handle.text,
        newStatus: _status.text,
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0x22FF5166),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55FF5166)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFFA5B0), height: 1.35),
      ),
    );
  }
}
