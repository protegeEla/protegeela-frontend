import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/quick_exit_button.dart';

class WomenPolicePage extends StatelessWidget {
  const WomenPolicePage({super.key});

  Future<void> _call180() async {
    await launchUrl(Uri(scheme: 'tel', path: '180'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Delegacia da Mulher'),
        actions: const [QuickExitButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.local_police_outlined,
                        color: AppColors.primary,
                        size: 46,
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atendimento especializado',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'A Delegacia da Mulher registra ocorrências, solicita medidas protetivas e encaminha para a rede de atendimento.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _InformationSection(
                  icon: Icons.directions_walk_rounded,
                  title: 'Quando procurar uma delegacia',
                  items: [
                    'Para registrar ameaça, agressão, perseguição, violência sexual, psicológica, patrimonial ou digital.',
                    'Quando precisar solicitar uma medida protetiva de urgência.',
                    'Para complementar um registro com novas provas ou informar o descumprimento de uma medida.',
                  ],
                ),
                const SizedBox(height: 14),
                const _InformationSection(
                  icon: Icons.folder_copy_outlined,
                  title: 'O que levar, se estiver seguro',
                  items: [
                    'Documento de identificação — a falta dele não deve impedir o pedido de ajuda.',
                    'Mensagens, fotos, vídeos, áudios, nomes de testemunhas e números de protocolos anteriores.',
                    'Informações sobre filhos, dependentes, endereço e formas seguras de contato.',
                  ],
                ),
                const SizedBox(height: 14),
                const _InformationSection(
                  icon: Icons.gavel_rounded,
                  title: 'O que você pode solicitar',
                  items: [
                    'Registro do boletim de ocorrência e orientação sobre os próximos passos.',
                    'Avaliação de medida protetiva, como afastamento e proibição de contato.',
                    'Encaminhamento para saúde, assistência social, abrigo ou orientação jurídica.',
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final buttons = [
                      FilledButton.icon(
                        onPressed: () => context.go('/mapa'),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver pontos de apoio no mapa'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _call180,
                        icon: const Icon(Icons.support_agent_rounded),
                        label: const Text('Ligar para 180'),
                      ),
                    ];
                    return wide
                        ? Row(
                            children: [
                              Expanded(child: buttons[0]),
                              const SizedBox(width: 12),
                              Expanded(child: buttons[1]),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buttons[0],
                              const SizedBox(height: 10),
                              buttons[1],
                            ],
                          );
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Se houver risco imediato, ligue para 190 e procure um local seguro. Não confronte o agressor para reunir documentos ou provas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        color: AppColors.secondary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
