import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/protegeela_brand.dart';

class LoginIllustrationPanel extends StatelessWidget {
  const LoginIllustrationPanel({super.key, required this.registering});

  final bool registering;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = constraints.maxHeight * 0.78;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: ProtegeElaBrand(showTagline: true),
            ),
            Positioned(
              top: 138,
              left: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: registering ? 'Crie sua\n' : 'Entre na\n',
                        ),
                        TextSpan(
                          text: registering ? 'conta' : 'sua conta',
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 54,
                          height: 1.02,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    registering
                        ? 'Faça parte do ProtegeEla e fortaleça\nsua rede de segurança.'
                        : 'Acesse o ProtegeEla e continue\ncuidando da sua segurança.',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 18,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -14,
              bottom: -8,
              height: illustrationHeight,
              child: Image.asset(
                registering
                    ? 'assets/config/img/register-illustration.png'
                    : 'assets/config/img/login-illustration.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ],
        );
      },
    );
  }
}
