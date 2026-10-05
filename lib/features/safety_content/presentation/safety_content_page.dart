import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../shared/models/safety_content.dart';
import '../data/safety_content_repository.dart';
import '../data/safety_favorites_repository.dart';

class SafetyContentPage extends ConsumerStatefulWidget {
  const SafetyContentPage({super.key});

  @override
  ConsumerState<SafetyContentPage> createState() => _SafetyContentPageState();
}

class _SafetyContentPageState extends ConsumerState<SafetyContentPage>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  String _category = 'all';
  String? _speakingItemId;
  int _speechSession = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSpeech(updateState: false);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopSpeech();
    }
  }

  void _stopSpeech({bool updateState = true}) {
    _speechSession++;
    ref.read(textToSpeechServiceProvider).stop();
    if (updateState && mounted && _speakingItemId != null) {
      setState(() => _speakingItemId = null);
    } else {
      _speakingItemId = null;
    }
  }

  Future<void> _toggleSpeech(SafetyContent item) async {
    if (_speakingItemId == item.id) {
      _stopSpeech();
      return;
    }

    final speech = ref.read(textToSpeechServiceProvider);
    speech.stop();
    final session = ++_speechSession;
    setState(() => _speakingItemId = item.id);

    await speech.speak('${item.title}. ${item.summary}. ${item.content}');
    if (mounted && session == _speechSession) {
      setState(() => _speakingItemId = null);
    }
  }

  void _changeCategory(String value) {
    _stopSpeech();
    setState(() => _category = value);
  }

  Future<void> _call(String number) async {
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  @override
  Widget build(BuildContext context) {
    final contents = ref.watch(safetyContentsProvider);
    final favorites = ref.watch(safetyFavoritesProvider);
    final speech = ref.watch(textToSpeechServiceProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Orientações'),
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
          query: _search.text,
          selectedCategory: _category,
          favorites: favorites,
          speechSupported: speech.supported,
          speakingItemId: _speakingItemId,
          onSearchChanged: (_) => setState(() {}),
          searchController: _search,
          onCategoryChanged: _changeCategory,
          onFavorite: (id) =>
              ref.read(safetyFavoritesProvider.notifier).toggle(id),
          onSpeechToggle: _toggleSpeech,
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
    required this.query,
    required this.selectedCategory,
    required this.favorites,
    required this.speechSupported,
    required this.speakingItemId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onFavorite,
    required this.onSpeechToggle,
  });

  final List<SafetyContent> items;
  final VoidCallback onCall190;
  final VoidCallback onCall180;
  final String query;
  final String selectedCategory;
  final Set<String> favorites;
  final bool speechSupported;
  final String? speakingItemId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onFavorite;
  final ValueChanged<SafetyContent> onSpeechToggle;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = items.where((item) {
      final categoryMatches = selectedCategory == 'all' ||
          (selectedCategory == 'favorites'
              ? favorites.contains(item.id)
              : item.category == selectedCategory);
      final searchMatches = normalizedQuery.isEmpty ||
          '${item.title} ${item.summary} ${item.content}'
              .toLowerCase()
              .contains(normalizedQuery);
      return categoryMatches && searchMatches;
    }).toList();
    final categories = <String>[
      'all',
      'favorites',
      ...{for (final item in items) item.category},
    ];
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
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Pesquisar orientações',
                  hintText: 'Ex.: senha, medida protetiva, emergência',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in categories) ...[
                      FilterChip(
                        showCheckmark: false,
                        selected: selectedCategory == category,
                        onSelected: (_) => onCategoryChanged(category),
                        avatar: Icon(
                          category == 'favorites'
                              ? Icons.favorite_outline_rounded
                              : _categoryIcon(category),
                          size: 17,
                        ),
                        label: Text(_categoryLabel(category)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
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
              if (filtered.isEmpty)
                AppStateView(
                  title: 'Nenhuma orientação encontrada',
                  message: query.isEmpty
                      ? 'Não há conteúdos nesta categoria.'
                      : 'Tente pesquisar com outras palavras.',
                )
              else
                for (var index = 0; index < filtered.length; index++) ...[
                  _GuideCard(
                    item: filtered[index],
                    expanded: index == 0,
                    favorite: favorites.contains(filtered[index].id),
                    speechSupported: speechSupported,
                    isSpeaking: speakingItemId == filtered[index].id,
                    onFavorite: () => onFavorite(filtered[index].id),
                    onSpeechToggle: () => onSpeechToggle(filtered[index]),
                  ),
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

  static String _categoryLabel(String category) => switch (category) {
        'all' => 'Todos',
        'favorites' => 'Favoritos',
        'safety_plan' => 'Plano de segurança',
        'support_network' => 'Rede de apoio',
        'digital_security' => 'Segurança digital',
        'evidence' => 'Provas',
        'health' => 'Saúde',
        'rights' => 'Direitos',
        'channels' => 'Canais oficiais',
        _ => 'Outros',
      };

  static IconData _categoryIcon(String category) => switch (category) {
        'all' => Icons.apps_rounded,
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
  const _GuideCard({
    required this.item,
    required this.expanded,
    required this.favorite,
    required this.speechSupported,
    required this.isSpeaking,
    required this.onFavorite,
    required this.onSpeechToggle,
  });

  final SafetyContent item;
  final bool expanded;
  final bool favorite;
  final bool speechSupported;
  final bool isSpeaking;
  final VoidCallback onFavorite;
  final VoidCallback onSpeechToggle;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(item.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (expanded) {
          if (!expanded && isSpeaking) onSpeechToggle();
        },
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onFavorite,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  size: 18,
                ),
                label: Text(favorite ? 'Favorito' : 'Favoritar'),
              ),
              if (speechSupported)
                TextButton.icon(
                  onPressed: onSpeechToggle,
                  icon: Icon(
                    isSpeaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    size: 18,
                  ),
                  label: Text(isSpeaking ? 'Parar' : 'Ouvir'),
                ),
            ],
          ),
          _ArticleBody(content: item.content),
          if (item.sourceName != null || item.updatedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: AppColors.primary, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    [
                      if (item.sourceName != null) 'Fonte: ${item.sourceName}',
                      if (item.updatedAt != null)
                        'Revisado em ${DateFormat('dd/MM/yyyy').format(item.updatedAt!.toLocal())}',
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                if (item.sourceUrl != null)
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(item.sourceUrl!)),
                    tooltip: 'Abrir fonte oficial',
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  ),
              ],
            ),
          ],
        ],
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
