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
          AuthStep.emailLogin => _EmailStep(controller: controller, register: false),
          AuthStep.emailRegister => _EmailStep(controller: controller, register: true),
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
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (leading != null)
              Positioned(left: 8, top: 6, child: leading!),
            Center(
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
          ],
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
      title: controller.accountAuthMode ? 'Добавить аккаунт' : 'Добро пожаловать в OneSpase',
      subtitle: controller.onlineConfigured
          ? 'Регистрация и вход работают прямо в приложении — отдельный сайт не нужен.'
          : 'Эта APK пока без Supabase. Можно открыть демо-интерфейс.',
      leading: controller.accountAuthMode
          ? IconButton(
              tooltip: 'Отмена',
              onPressed: controller.cancelAddAccount,
              icon: const Icon(Icons.close_rounded),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: controller.authBusy || !controller.onlineConfigured
                ? null
                : controller.showEmailRegister,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Создать аккаунт'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.authBusy || !controller.onlineConfigured
                ? null
                : controller.showEmailLogin,
            icon: const Icon(Icons.login_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Войти по email'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
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
          TextButton.icon(
            onPressed: controller.authBusy || !controller.onlineConfigured
                ? null
                : controller.startGuest,
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text('Гостевой аккаунт'),
          ),
          if (!controller.accountAuthMode) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: controller.authBusy ? null : controller.startDemo,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Открыть демо'),
            ),
          ],
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
            'Для версии без писем отключи Confirm email в Supabase. Пароль хранится в Supabase Auth, приложение его не сохраняет.',
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

class _EmailStep extends StatefulWidget {
  const _EmailStep({required this.controller, required this.register});
  final AppController controller;
  final bool register;

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: widget.register ? 'Создать аккаунт' : 'Войти в OneSpase',
      subtitle: widget.register
          ? 'Почта нужна для входа на других устройствах. Отдельный сайт не нужен.'
          : 'Введи почту и пароль своего аккаунта.',
      leading: IconButton(
        onPressed: widget.controller.showAuthChoice,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Пароль',
              helperText: widget.register ? 'Минимум 8 символов' : null,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          ),
          if (widget.register) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Повтори пароль',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
          ],
          if (widget.controller.authError != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(text: widget.controller.authError!),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: widget.controller.authBusy ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(widget.register ? 'Зарегистрироваться' : 'Войти'),
            ),
          ),
          if (widget.controller.authBusy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.register && _password.text != _repeat.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают.')),
      );
      return;
    }
    if (widget.register) {
      await widget.controller.registerWithEmail(
        email: _email.text,
        password: _password.text,
      );
    } else {
      await widget.controller.loginWithEmail(
        email: _email.text,
        password: _password.text,
      );
    }
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
              helperText: 'Латиница, цифры и _. Некоторые имена зарезервированы.',
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
