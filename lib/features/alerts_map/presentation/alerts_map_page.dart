import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../shared/models/support_point.dart';
import '../../support_points/presentation/widgets/support_results_panel.dart';
import '../../support_points/presentation/widgets/support_category.dart';
import 'widgets/community_map.dart';
import '../../support_points/data/support_points_repository.dart';
import '../data/alerts_map_repository.dart';

class AlertsMapPage extends ConsumerStatefulWidget {
  const AlertsMapPage({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  ConsumerState<AlertsMapPage> createState() => _AlertsMapPageState();
}

class _AlertsMapPageState extends ConsumerState<AlertsMapPage>
    with WidgetsBindingObserver {
  final _mapController = MapController();
  final _search = TextEditingController();
  Timer? _refreshTimer;
  Timer? _moveDebounce;
  bool _mapReady = false;
  bool _foreground = true;
  bool _reloadPending = false;
  String? _loadError;
  bool _showAlerts = true;
  String _query = '';
  String _category = 'all';
  String? _selectedId;
  bool _mobileList = false;
  List<PublicAlertMarker> _alerts = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _foreground && _showAlerts && !_loading) _loadAlerts();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _moveDebounce?.cancel();
    if (!_mapReady || !_foreground || !_showAlerts) return;
    // A drag/zoom generates many camera updates: query only after it settles.
    _moveDebounce = Timer(const Duration(milliseconds: 350), _loadAlerts);
  }

  @override
  void dispose() {
    _search.dispose();
    _refreshTimer?.cancel();
    _moveDebounce?.cancel();
    _mapController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    if (!mounted || !_mapReady || !_foreground || !_showAlerts) return;
    if (_loading) {
      _reloadPending = true;
      return;
    }
    final bounds = _mapController.camera.visibleBounds;
    setState(() => _loading = true);
    try {
      final demoAlerts = await ref.read(publicAlertMarkersProvider.future);
      if (!mounted) return;
      final alerts = demoAlerts.isNotEmpty
          ? demoAlerts
          : await ref.read(alertsMapRepositoryProvider).publicAlertsInBounds(
                south: bounds.south.clamp(-90.0, 90.0),
                west: bounds.west.clamp(-180.0, 180.0),
                north: bounds.north.clamp(-90.0, 90.0),
                east: bounds.east.clamp(-180.0, 180.0),
              );
      if (!mounted) return;
      _alerts = alerts;
      _loadError = null;
    } catch (_) {
      if (!mounted) return;
      _loadError = 'Falha ao atualizar. Os últimos dados foram mantidos.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_reloadPending) {
          _reloadPending = false;
          _scheduleRefresh();
        }
      }
    }
  }

  void _selectPoint(SupportPoint point) {
    setState(() {
      _selectedId = point.id;
      _mobileList = false;
    });
    if (_mapReady) {
      _mapController.move(LatLng(point.latitude, point.longitude), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final points = ref.watch(supportPointsProvider);
    final items = (points.valueOrNull ?? const <SupportPoint>[]).where((point) {
      final text =
          '${point.name} ${point.address} ${point.city} ${supportCategoryLabel(point.category)}'
              .toLowerCase();
      return (_category == 'all' || point.category == _category) &&
          text.contains(_query.trim().toLowerCase());
    }).toList();
    final center = LatLng(config.defaultLatitude, config.defaultLongitude);
    final results = points.isLoading && !points.hasValue
        ? const Center(child: CircularProgressIndicator())
        : points.hasError
            ? AppStateView(
                title: 'Não foi possível carregar os locais',
                message: 'O mapa de alertas continua disponível.',
                actionLabel: 'Tentar novamente',
                onAction: () => ref.invalidate(supportPointsProvider))
            : SupportResultsPanel(
                items: items,
                selectedId: _selectedId,
                onSelected: _selectPoint);
    final map = CommunityMap(
      controller: _mapController,
      center: center,
      zoom: config.defaultZoom,
      tileProvider: widget.tileProvider,
      points: items,
      alerts: _showAlerts ? _alerts : const [],
      selectedId: _selectedId,
      loading: _loading,
      error: _loadError,
      onSelected: _selectPoint,
      onRefresh: _loadAlerts,
      onReady: () {
        _mapReady = true;
        _loadAlerts();
      },
      onMoved: _scheduleRefresh,
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return Padding(
            padding: EdgeInsets.all(wide ? 24 : 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppPageHeader(
                    title: 'Mapa e apoio',
                    subtitle:
                        'Alertas aproximados e serviços de apoio em um só lugar.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar ponto de apoio, bairro ou cidade...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      FilterChip(
                        label: const Text('Alertas aproximados'),
                        avatar: const Icon(Icons.radar_rounded,
                            size: 18, color: AppColors.emergency),
                        selected: _showAlerts,
                        onSelected: (value) {
                          setState(() => _showAlerts = value);
                          _scheduleRefresh();
                        },
                      ),
                      const SizedBox(width: 16),
                      for (final category in const [
                        'all',
                        'support_center',
                        'police_station',
                        'health',
                        'legal'
                      ]) ...[
                        ChoiceChip(
                          label: Text(category == 'all'
                              ? 'Todos os serviços'
                              : supportCategoryLabel(category)),
                          selected: _category == category,
                          onSelected: (_) => setState(() {
                            _category = category;
                            _selectedId = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: Text(
                      '${items.length} ${items.length == 1 ? 'ponto de apoio' : 'pontos de apoio'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    )),
                    if (!wide)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _mobileList = !_mobileList),
                        icon: Icon(_mobileList
                            ? Icons.map_outlined
                            : Icons.view_list_outlined),
                        label: Text(_mobileList ? 'Ver mapa' : 'Ver lista'),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Expanded(
                    child: wide
                        ? Row(children: [
                            Expanded(child: map),
                            const SizedBox(width: 18),
                            SizedBox(width: 350, child: results),
                          ])
                        : IndexedStack(
                            index: _mobileList ? 1 : 0,
                            children: [map, results]),
                  ),
                ]),
          );
        }),
      ),
    );
  }
}
