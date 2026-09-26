import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/quick_exit_service.dart';

class QuickExitButton extends StatelessWidget {
  const QuickExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const ValueKey('quick-exit-button'),
      onPressed: () async {
        final leftSite = await leaveSensitiveContent();
        if (!leftSite && context.mounted) {
          GoRouter.of(context).go('/neutral');
        }
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      icon: const Icon(Icons.exit_to_app_rounded),
      label: const Text('Saída rápida'),
    );
  }
}
