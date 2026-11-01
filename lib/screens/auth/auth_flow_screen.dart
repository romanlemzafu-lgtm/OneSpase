import 'dart:async';

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
          AuthStep.email => _EmailStep(controller: controller),
          AuthStep.otp => _OtpStep(controller: controller),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (leading != null) ...[
                    Align(alignment: Alignment.centerLeft, child: leading!),
                    const SizedBox(height: 14),
                  ],
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: OneSpaseTheme.surface,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/images/onespase_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
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

class _EmailStep extends StatefulWidget {
  const _EmailStep({required this.controller});
  final AppController controller;

  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<_EmailStep> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      title: 'Добро пожаловать в OneSpase',
      subtitle: widget.controller.onlineConfigured
          ? 'Введи почту — мы отправим одноразовый код для входа или регистрации.'
          : 'Онлайн-сервер ещё не подключён к этой сборке. Интерфейс можно открыть в демо-режиме.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Почта',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            onSubmitted: (_) => _send(),
          ),
          if (widget.controller.authError != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(text: widget.controller.authError!),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.controller.authBusy ? null : _send,
            icon: widget.controller.authBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mail_outline_rounded),
            label: const Text('Получить код'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.controller.authBusy
                ? null
                : () => widget.controller.startDemo(),
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Открыть демо OneSpase'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Пароль не нужен: вход будет подтверждаться кодом из письма.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OneSpaseTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() => widget.controller.requestEmailOtp(_email.text);
}

class _OtpStep extends StatefulWidget {
  const _OtpStep({required this.controller});
  final AppController controller;

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final _code = TextEditingController();
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      leading: IconButton.filledTonal(
        onPressed: widget.controller.backToEmail,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: 'Проверь почту',
      subtitle: 'Код отправлен на ${widget.controller.pendingEmail}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 8,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '000000',
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (widget.controller.authError != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(text: widget.controller.authError!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.controller.authBusy ? null : _verify,
            child: widget.controller.authBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Подтвердить'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _seconds == 0 && !widget.controller.authBusy
                ? () async {
                    await widget.controller.resendOtp();
                    _startTimer();
                  }
                : null,
            child: Text(
              _seconds == 0
                  ? 'Отправить код ещё раз'
                  : 'Повторная отправка через $_seconds сек.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() => widget.controller.verifyOtp(_code.text);
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
      title: 'Создай профиль',
      subtitle: 'Последний шаг — имя, уникальный @username и статус.',
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
              prefixIcon: Icon(Icons.alternate_email_rounded),
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.controller.authBusy ? null : _finish,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Войти в OneSpase'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() => widget.controller.completeProfile(
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OneSpaseTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: OneSpaseTheme.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
