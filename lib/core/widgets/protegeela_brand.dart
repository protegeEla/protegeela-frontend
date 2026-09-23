import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ProtegeElaBrand extends StatelessWidget {
  const ProtegeElaBrand({
    super.key,
    this.compact = false,
    this.showTagline = false,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 34.0 : 48.0;
    final fontSize = compact ? 21.0 : 30.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/config/img/logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Protege'),
                    TextSpan(
                      text: 'Ela',
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              if (showTagline)
                const Text(
                  'Mais segurança. Mais liberdade.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 16), action!],
      ],
    );
  }
}
