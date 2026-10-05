import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_back_button.dart';

class AnonymousReportPage extends StatelessWidget {
  const AnonymousReportPage({super.key});

  Future<void> _call(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Denúncia anônima'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                const _HeroCard(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final channels = [
                      _ChannelCard(
                        icon: Icons.phone_in_talk_rounded,
                        number: '181',
                        title: 'Disque Denúncia',
                        description:
                            'Relate fatos sem precisar se identificar.',
                        onTap: () => _call('181'),
                      ),
                      _ChannelCard(
                        icon: Icons.support_agent_rounded,
                        number: '180',
                        title: 'Central da Mulher',
                        description:
                            'Receba orientação e conheça a rede de atendimento.',
                        onTap: () => _call('180'),
                      ),
                    ];
                    return wide
                        ? Row(
                            children: [
                              Expanded(child: channels[0]),
                              const SizedBox(width: 14),
                              Expanded(child: channels[1]),
                            ],
                          )
                        : Column(
                            children: [
                              channels[0],
                              const SizedBox(height: 12),
                              channels[1],
                            ],
                          );
                  },
                ),
                const SizedBox(height: 18),
                const _ChecklistCard(
                  title: 'Antes de fazer o relato',
                  icon: Icons.fact_check_outlined,
                  items: [
                    'Anote endereço, horário e uma descrição objetiva do que aconteceu.',
                    'Informe características que ajudem a localizar as pessoas envolvidas.',
                    'Guarde fotos, mensagens e áudios em um local seguro, sem se colocar em risco.',
                    'Não confronte a pessoa denunciada para obter mais informações.',
                  ],
                ),
                const SizedBox(height: 14),
                const _ChecklistCard(
                  title: 'O que esperar',
                  icon: Icons.shield_outlined,
                  items: [
                    'A denúncia gera um registro para análise do órgão responsável.',
                    'Quanto mais precisas as informações, maior a possibilidade de apuração.',
                    'Uma denúncia anônima não substitui o pedido de socorro em uma emergência.',
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        color: AppColors.emergency,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Risco imediato?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.emergency,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Vá para um local seguro e ligue para 190. Não espere a apuração de uma denúncia anônima.',
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => _call('190'),
                              icon: const Icon(Icons.phone_rounded),
                              label: const Text('Ligar para 190'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.emergency,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relate sem se identificar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Use os canais oficiais para comunicar uma situação e fornecer informações úteis para a apuração.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.number,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String number;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number • $title',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.call_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
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
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
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
                        Icons.check_circle_outline_rounded,
                        color: AppColors.safe,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
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
