import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/location_service.dart';

class PlacesSearchPage extends ConsumerStatefulWidget {
  const PlacesSearchPage({super.key});

  @override
  ConsumerState<PlacesSearchPage> createState() => _PlacesSearchPageState();
}

class _PlacesSearchPageState extends ConsumerState<PlacesSearchPage> {
  final _query = TextEditingController();
  String _category = 'women_police';
  bool _busy = false;
  bool _searched = false;

  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search({required bool nearby}) async {
    if (_busy) return;
    final api = ref.read(apiClientProvider);
    if (!api.isAuthenticated) {
      setState(() => _error =
          'Entre em uma conta para buscar locais reais. A busca não está disponível no modo demonstração.');
      return;
    }
    final query = _query.text.trim();
    if (!nearby && query.isEmpty) {
      setState(() => _error = 'Digite o nome exato da cidade.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _items = [];
      _searched = false;
    });
    try {
      final location = nearby
          ? await ref.read(locationServiceProvider).captureCurrent()
          : null;
      if (!mounted) return;
      final data =
          await api.request('POST', '/support-points/places/search', body: {
        'query': query,
        'category': _category,
        if (location != null) ...{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radius': 10000,
        },
      });
      final items = data['items'];
      if (items is! List ||
          items.any((item) => item is! Map<String, dynamic>)) {
        throw const AppException('Resposta inválida do serviço de locais.');
      }
      if (!mounted) return;
      setState(() {
        _items = items.cast<Map<String, dynamic>>();

        _searched = true;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = switch (error.code) {
            'http_503' =>
              'O serviço gratuito está temporariamente indisponível.',
            'http_429' =>
              'Limite temporário do serviço gratuito. Tente mais tarde.',
            'http_502' =>
              'Não foi possível consultar o OpenStreetMap. Tente mais tarde.',
            'http_504' =>
              'O OpenStreetMap demorou a responder. Tente novamente.',
            _ => error.message,
          });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Não foi possível buscar. Confira a permissão de localização e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show a recoverable error without exposing external response details.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buscar pontos de apoio')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
                'Encontre delegacias da mulher, centros de apoio, hospitais e Defensoria Pública.'),
            const SizedBox(height: 16),
            const Text(
                'Dados colaborativos: a cobertura pode ser incompleta. Na busca por cidade, use o nome exato; cidades com o mesmo nome podem aparecer juntas.'),
            TextField(
              controller: _query,
              enabled: !_busy,
              maxLength: 200,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(nearby: false),
              decoration: const InputDecoration(
                  labelText: 'Nome exato da cidade',
                  hintText: 'Ex.: Manaus',
                  prefixIcon: Icon(Icons.search)),
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: const [
                DropdownMenuItem(
                    value: 'women_police', child: Text('Delegacia da Mulher')),
                DropdownMenuItem(
                    value: 'support_center',
                    child: Text('Centro de apoio à mulher')),
                DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                DropdownMenuItem(
                    value: 'legal', child: Text('Defensoria Pública')),
              ],
              onChanged:
                  _busy ? null : (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 12),
            const Text(
                'Ao buscar perto de você, sua localização será enviada ao OpenStreetMap. A categoria selecionada será usada na busca. A busca por proximidade ignora a cidade digitada.'),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 8, children: [
              FilledButton.icon(
                  onPressed: _busy ? null : () => _search(nearby: true),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Buscar perto de mim')),
              OutlinedButton(
                  onPressed: _busy ? null : () => _search(nearby: false),
                  child: const Text('Buscar na cidade')),
            ]),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_error!, semanticsLabel: _error)),
            if (_searched) ...[
              const Text('OpenStreetMap',
                  style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5E5E5E))),
              if (_items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Nenhum local cadastrado encontrado. Isso não significa que não existam serviços na região.')),
              for (final item in _items) _place(item),
            ],
            const SizedBox(height: 12),
            Wrap(children: [
              TextButton(
                  onPressed: () =>
                      _open('https://www.openstreetmap.org/copyright'),
                  child: const Text('© Colaboradores do OpenStreetMap')),
              TextButton(
                  onPressed: () =>
                      _open('https://osmfoundation.org/wiki/Privacy_Policy'),
                  child: const Text('Privacidade do OpenStreetMap')),
            ]),
          ],
        ),
      );

  Widget _place(Map<String, dynamic> item) {
    final name = item['name'];
    final link = item['map_url'];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${name ?? 'Local de apoio'}',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('${item['address'] ?? 'Endereço não informado'}'),
                if (link is String)
                  TextButton.icon(
                      onPressed: () => _open(link),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir no OpenStreetMap')),
              ],
            )));
  }
}
