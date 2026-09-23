import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/protegeela_brand.dart';

class PrivacyIntroPage extends StatelessWidget {
  const PrivacyIntroPage({super.key, this.inSettings = false});

  final bool inSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 850;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 54 : 20,
                vertical: desktop ? 30 : 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppBackButton(
                            fallbackLocation:
                                inSettings ? '/perfil' : '/apresentacao',
                          ),
                          const SizedBox(width: 8),
                          const ProtegeElaBrand(compact: true),
                          const Spacer(),
                          Text(
                            inSettings ? 'Privacidade da conta' : 'Privacidade',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      SizedBox(height: desktop ? 42 : 26),
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 700),
                          padding: EdgeInsets.all(desktop ? 46 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x126F1D5F),
                                blurRadius: 30,
                                offset: Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Sua localização exata\nnão é pública',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: desktop ? 30 : 26),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'O mapa comunitário mostra apenas áreas aproximadas. Sua localização exata fica disponível apenas para você e para contatos autorizados durante um alerta ativo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Navegadores podem limitar a geolocalização, notificações e atualizações quando o app estiver fechado.',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => context.go(
                                    inSettings ? '/perfil' : '/localizacao',
                                  ),
                                  child: Text(
                                    inSettings ? 'Voltar ao perfil' : 'Entendi',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
