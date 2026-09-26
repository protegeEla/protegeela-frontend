import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/quick_exit_button.dart';
import '../../../shared/models/safety_content.dart';
import '../data/safety_content_repository.dart';

class SafetyContentPage extends ConsumerWidget {
  const SafetyContentPage({super.key});

  Future<void> _call(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(safetyContentsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Orientações'),
        actions: const [QuickExitButton()],
      ),
      body: contents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppStateView(
          title: 'Erro',
          message: 'Não foi possível carregar as orientações.',
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(safetyContentsProvider),
        ),
        data: (items) => _SafetyGuide(
          items: items,
          onCall190: () => _call('190'),
          onCall180: () => _call('180'),
        ),
      ),
    );
  }
}

class _SafetyGuide extends StatelessWidget {
  const _SafetyGuide({
    required this.items,
    required this.onCall190,
    required this.onCall180,
  });

  final List<SafetyContent> items;
  final VoidCallback onCall190;
  final VoidCallback onCall180;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informação para agir com mais segurança',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Leia apenas quando for seguro. Adapte cada orientação à sua realidade e não faça nada que aumente o risco.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _EmergencyChannels(
                onCall190: onCall190,
                onCall180: onCall180,
              ),
              const SizedBox(height: 24),
              Text(
                'Guias práticos',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              const Text(
                'Abra um tema para ver ações objetivas e cuidados importantes.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const AppStateView(
                  title: 'Sem conteúdos publicados',
                  message:
                      'Os conteúdos podem ser gerenciados pelo painel administrativo.',
                )
              else
                for (var index = 0; index < items.length; index++) ...[
                  _GuideCard(item: items[index], expanded: index == 0),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 10),
              const _OfficialSources(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyChannels extends StatelessWidget {
  const _EmergencyChannels({
    required this.onCall190,
    required this.onCall180,
  });

  final VoidCallback onCall190;
  final VoidCallback onCall180;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final emergency = _CallCard(
          number: '190',
          title: 'Risco imediato',
          description:
              'Quando a violência estiver acontecendo ou houver risco à vida.',
          color: AppColors.emergency,
          icon: Icons.emergency_rounded,
          onTap: onCall190,
        );
        final guidance = _CallCard(
          number: '180',
          title: 'Orientação e rede',
          description:
              'Atendimento gratuito, 24 horas, para direitos, serviços e denúncias.',
          color: AppColors.primary,
          icon: Icons.support_agent_rounded,
          onTap: onCall180,
        );
        return wide
            ? Row(
                children: [
                  Expanded(child: emergency),
                  const SizedBox(width: 14),
                  Expanded(child: guidance),
                ],
              )
            : Column(
                children: [
                  emergency,
                  const SizedBox(height: 12),
                  guidance,
                ],
              );
      },
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String number;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number • $title',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.call_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.item, required this.expanded});

  final SafetyContent item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(item.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.surfaceSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(item.summary),
        ),
        children: [_ArticleBody(content: item.content)],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'safety_plan' => Icons.route_outlined,
      'support_network' => Icons.people_outline_rounded,
      'digital_security' => Icons.phonelink_lock_outlined,
      'evidence' => Icons.folder_copy_outlined,
      'health' => Icons.health_and_safety_outlined,
      'rights' => Icons.gavel_rounded,
      'channels' => Icons.contact_phone_outlined,
      _ => Icons.lightbulb_outline_rounded,
    };
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 10),
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
                Expanded(child: Text(line)),
              ],
            ),
          ),
      ],
    );
  }
}

class _OfficialSources extends StatelessWidget {
  const _OfficialSources();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceSoft,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fontes oficiais',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'As orientações são complementares e não substituem avaliação profissional.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.gov.br/mulheres/pt-br/ligue180'),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Ligue 180'),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(
                      'https://www.gov.br/mulheres/pt-br/central-de-conteudos/noticias/2026/agosto-defeso-eleitoral/medidas-protetivas-o-que-sao-como-funcionam-e-como-solicitar-em-casos-de-violencia-domestica-e-familiar',
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Medidas protetivas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
