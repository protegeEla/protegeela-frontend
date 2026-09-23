import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/protegeela_brand.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              right: 24,
              top: 24,
              child: _Glow(size: 320, color: Color(0x55F1BEDA)),
            ),
            const Positioned(
              left: 24,
              bottom: 24,
              child: _Glow(size: 260, color: Color(0x44E9B6D1)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 850;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 54 : 22,
                      vertical: desktop ? 32 : 22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ProtegeElaBrand(showTagline: true),
                            SizedBox(height: desktop ? 38 : 28),
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: AppColors.border),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x146F1D5F),
                                    blurRadius: 36,
                                    offset: Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: desktop
                                  ? const Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: _WelcomeContent(),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: _OnboardingArt(),
                                        ),
                                      ],
                                    )
                                  : const Column(
                                      children: [
                                        _OnboardingArt(),
                                        _WelcomeContent(),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    return Padding(
      padding: EdgeInsets.all(desktop ? 48 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vinda ao\nProtegeEla!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: desktop ? 46 : 36,
                ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mais proteção, informação e apoio para o seu dia a dia.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 30),
          const _FeatureLine(
            icon: Icons.people_outline_rounded,
            text: 'Acesse sua rede de apoio',
          ),
          const _FeatureLine(
            icon: Icons.location_on_outlined,
            text: 'Encontre locais seguros próximos',
          ),
          const _FeatureLine(
            icon: Icons.favorite_border_rounded,
            text: 'Peça ajuda rapidamente',
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/login'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Começar agora'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt();

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 850;
    return Container(
      height: desktop ? 560 : 330,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4FA), Color(0xFFF9DFED)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          desktop ? 10 : 30,
          desktop ? 26 : 20,
          desktop ? 10 : 30,
          0,
        ),
        child: Image.asset(
          'assets/config/img/onboarding.png',
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
