import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../../shared/models/shared_trip.dart';
import '../data/shared_trip_repository.dart';

class SharedTripPage extends ConsumerStatefulWidget {
  const SharedTripPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<SharedTripPage> createState() => _SharedTripPageState();
}

class _SharedTripPageState extends ConsumerState<SharedTripPage>
    with WidgetsBindingObserver {
  final _mapController = MapController();
  Timer? _refreshTimer;
  SharedTrip? _trip;
  bool _loading = true;
  bool _refreshing = false;
  bool _mapReady = false;
  bool _foreground = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_foreground && _trip?.status == 'active') _load(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final trip =
          await ref.read(sharedTripRepositoryProvider).get(widget.token);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _error = null;
        _loading = false;
      });
      _centerLatest();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'O link pode ter expirado ou ter sido substituído.';
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  void _centerLatest() {
    if (!_mapReady || _trip == null || _trip!.locations.isEmpty) return;
    final latest = _trip!.locations.last;
    _mapController.move(LatLng(latest.latitude, latest.longitude), 16);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _loading && _trip == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _trip == null
                    ? AppStateView(
                        title: 'Trajeto indisponível',
                        message: _error!,
                        actionLabel: 'Tentar novamente',
                        onAction: _load,
                      )
                    : _content(_trip!),
          ),
        ),
      ),
    );
  }

  Widget _content(SharedTrip trip) {
    final active = trip.status == 'active';
    final overdue = trip.status == 'overdue';
    final locations = trip.locations
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final config = ref.watch(appConfigProvider);
    final center = locations.isEmpty
        ? LatLng(config.defaultLatitude, config.defaultLongitude)
        : locations.last;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: ProtegeElaBrand(showTagline: true)),
        const SizedBox(height: 20),
        Card(
          color: overdue
              ? AppColors.emergency.withValues(alpha: 0.06)
              : AppColors.surfaceSoft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  active
                      ? Icons.navigation_rounded
                      : overdue
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                  color: overdue ? AppColors.emergency : AppColors.primary,
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle(trip),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusDescription(trip),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar trajeto',
                  onPressed: _refreshing ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (locations.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.location_searching_rounded,
                      color: AppColors.primary, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'Aguardando a primeira localização',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'O mapa será atualizado automaticamente quando o aparelho enviar a posição.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 470,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 16,
                  onMapReady: () {
                    _mapReady = true;
                    _centerLatest();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'org.protegeela.app',
                  ),
                  if (locations.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: locations,
                          strokeWidth: 5,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: locations.first,
                        width: 38,
                        height: 38,
                        child: const _MapMarker(
                          icon: Icons.trip_origin_rounded,
                          color: AppColors.safe,
                        ),
                      ),
                      Marker(
                        point: locations.last,
                        width: 48,
                        height: 48,
                        child: const _MapMarker(
                          icon: Icons.navigation_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          trip.lastLocationAt == null
              ? 'Nenhuma posição recebida ainda.'
              : 'Última atualização: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(trip.lastLocationAt!.toLocal())}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        const Text(
          'Este é um link privado. Não encaminhe para pessoas que não fazem parte da rede de confiança.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  String _statusTitle(SharedTrip trip) => switch (trip.status) {
        'active' => '${trip.travelerName} está a caminho',
        'completed' => '${trip.travelerName} chegou bem',
        'cancelled' => 'Acompanhamento cancelado',
        'overdue' => '${trip.travelerName} não confirmou a chegada',
        _ => 'Acompanhamento de trajeto',
      };

  String _statusDescription(SharedTrip trip) => switch (trip.status) {
        'active' =>
          'Chegada prevista para ${DateFormat('HH:mm').format(trip.expectedAt.toLocal())}. O mapa atualiza a cada poucos segundos.',
        'completed' =>
          'A chegada foi confirmada e o compartilhamento terminou.',
        'cancelled' => 'A pessoa encerrou o acompanhamento.',
        'overdue' =>
          'O prazo e a tolerância terminaram. Verifique se ela precisa de ajuda.',
        _ => 'Consulte abaixo a última posição disponível.',
      };
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 7),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      );
}
