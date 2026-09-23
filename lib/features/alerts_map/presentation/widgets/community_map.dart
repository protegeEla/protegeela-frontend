import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../shared/models/support_point.dart';
import '../../../support_points/presentation/widgets/support_category.dart';
import '../../data/alerts_map_repository.dart';

class CommunityMap extends StatelessWidget {
  const CommunityMap({
    super.key,
    required this.controller,
    required this.center,
    required this.zoom,
    required this.points,
    required this.alerts,
    required this.selectedId,
    required this.loading,
    required this.error,
    required this.onSelected,
    required this.onRefresh,
    required this.onReady,
    required this.onMoved,
    this.tileProvider,
  });

  final MapController controller;
  final LatLng center;
  final double zoom;
  final List<SupportPoint> points;
  final List<PublicAlertMarker> alerts;
  final String? selectedId;
  final bool loading;
  final String? error;
  final ValueChanged<SupportPoint> onSelected;
  final VoidCallback onRefresh;
  final VoidCallback onReady;
  final VoidCallback onMoved;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onMapReady: onReady,
              onPositionChanged: (_, __) => onMoved(),
            ),
            children: [
              TileLayer(
                tileProvider: tileProvider,
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.protegeela.app',
              ),
              CircleLayer(circles: [
                for (final alert in alerts)
                  CircleMarker(
                    point: LatLng(alert.latitude, alert.longitude),
                    radius: alert.radiusMeters.toDouble(),
                    useRadiusInMeter: true,
                    color: AppColors.emergency.withValues(alpha: 0.16),
                    borderColor: AppColors.emergency,
                    borderStrokeWidth: 2,
                  ),
              ]),
              MarkerLayer(markers: [
                for (final point in points)
                  Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 48,
                    height: 48,
                    child: Tooltip(
                      message: point.name,
                      child: Material(
                        elevation: selectedId == point.id ? 6 : 2,
                        color: selectedId == point.id
                            ? AppColors.primary
                            : supportCategoryColor(point.category),
                        shape: const CircleBorder(
                            side: BorderSide(color: Colors.white, width: 3)),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onSelected(point),
                          child: Icon(supportCategoryIcon(point.category),
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
              ]),
              RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors',
                    onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'))),
              ]),
            ],
          ),
          Positioned(
              top: 12,
              right: 12,
              child: Column(children: [
                _MapAction(
                    icon: Icons.add_rounded,
                    label: 'Ampliar mapa',
                    onTap: () => controller.move(
                        controller.camera.center, controller.camera.zoom + 1)),
                const SizedBox(height: 6),
                _MapAction(
                    icon: Icons.remove_rounded,
                    label: 'Reduzir mapa',
                    onTap: () => controller.move(
                        controller.camera.center, controller.camera.zoom - 1)),
                const SizedBox(height: 6),
                _MapAction(
                    icon: Icons.center_focus_strong_rounded,
                    label: 'Centralizar mapa',
                    onTap: () => controller.move(center, zoom)),
              ])),
          Positioned(
              left: 12,
              right: 12,
              bottom: 34,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          error ??
                              'Os círculos de alerta indicam áreas aproximadas.',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted))),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Atualizar alertas',
                    onPressed: loading ? null : onRefresh,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                  ),
                ]),
              )),
        ]),
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  const _MapAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: IconButton(
            tooltip: label,
            onPressed: onTap,
            icon: Icon(icon, color: AppColors.primary)),
      );
}
