import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    super.key,
    required this.type,
    this.size = 18,
  });

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'blue' => const Color(0xFF2296F3),
      'red' => const Color(0xFFFF3B4D),
      'purple' => const Color(0xFF8B4DFF),
      _ => Colors.transparent,
    };

    if (type == 'none') return const SizedBox.shrink();

    return Tooltip(
      message: switch (type) {
        'blue' => 'Подтверждённый аккаунт',
        'red' => 'Официальный аккаунт OneSpase',
        'purple' => 'Особый статус OneSpase',
        _ => '',
      },
      child: Icon(Icons.verified_rounded, color: color, size: size),
    );
  }
}
