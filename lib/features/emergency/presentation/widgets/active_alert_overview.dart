import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../features/notifications/data/notification_center_repository.dart';
import '../../../../shared/models/alert_location.dart';
import '../../../../shared/models/emergency_alert.dart';
import '../../../../shared/models/trusted_contact.dart';

class ActiveAlertOverview extends StatelessWidget {
  const ActiveAlertOverview({
    super.key,
    required this.alert,
    required this.location,
    required this.center,
    required this.demo,
    required this.busy,
    required this.locationLoading,
    required this.locationError,
    required this.contacts,
    required this.contactsLoading,
    required this.contactsError,
    required this.notification,
    required this.notificationLoading,
    required this.notificationError,
    required this.onRefreshStatus,
    required this.onCall,
    required this.onUpdate,
    required this.onSafe,
    required this.onClose,
    required this.onSupport,
    this.tileProvider,
  });

  final EmergencyAlert alert;
  final AlertLocation? location;
  final LatLng center;
  final bool demo;
  final bool busy;
  final bool locationLoading;
  final bool locationError;
  final List<TrustedContact> contacts;
  final bool contactsLoading;
  final bool contactsError;
  final AlertNotificationSummary? notification;
  final bool notificationLoading;
  final bool notificationError;
  final VoidCallback onRefreshStatus;
  final VoidCallback onCall;
  final VoidCallback onUpdate;
  final VoidCallback onSafe;
  final VoidCallback onClose;
  final VoidCallback onSupport;
  final TileProvider? tileProvider;

  bool get _hasPosition =>
      location != null ||
      (alert.publicLatitude != null && alert.publicLongitude != null);

  String get _positionLabel {
    if (demo) return 'Posição demonstrativa';
    if (locationLoading) return 'Buscando localização';
    if (locationError) return 'Não foi possível atualizar';
    if (location != null) return 'Precisão de ${location!.accuracy.round()} m';
    return _hasPosition ? 'Localização aproximada' : 'Localização indisponível';
  }

  String get _notificationHeadline {
    if (demo) return 'Nenhum envio real';
    if (notificationLoading) return 'Consultando envios';
    if (notificationError || notification == null) return 'Status indisponível';
    if (notification!.sent) return 'Envio solicitado';
    if (!notification!.isConfigured) return 'Envio não configurado';
    return switch (notification!.status) {
      'queued' || 'pending' => 'Aguardando envio',
      'failed' => 'Falha no envio',
      _ => 'Nenhum envio confirmado',
    };
  }

  String get _notificationDetail {
    if (demo) return 'Experiência demonstrativa';
    if (notificationLoading) return 'Atualizando o status da rede de apoio.';
    if (notificationError || notification == null) {
      return 'Toque em atualizar para consultar novamente.';
    }
    if (notification!.sent) {
      return 'O servidor confirmou o envio, não a leitura.';
    }
    if (!notification!.isConfigured) {
      return 'WhatsApp, SMS e push ainda não estão configurados.';
    }
    return 'O servidor ainda não confirmou uma entrega.';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 950;
      final mapHeight =
          wide ? (constraints.maxHeight - 370).clamp(260.0, 410.0) : 300.0;
      final map = _map(context, mapHeight);
      final actions = _actions(context);
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 10, wide ? 32 : 16, 20),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFEEEE), Color(0xFFFFF7FA)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF4D2D5)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.sos_rounded,
                      color: AppColors.emergency, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          demo
                              ? 'Alerta em demonstração'
                              : 'Seu alerta está ativo',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(
                          demo
                              ? 'Você está explorando o fluxo. Nenhum contato real foi avisado.'
                              : _notificationDetail,
                          style: const TextStyle(color: AppColors.textMuted)),
                    ])),
              ]),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, size) {
              final columns = size.maxWidth >= 750 ? 3 : 1;
              final width = (size.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(spacing: 12, runSpacing: 10, children: [
                SizedBox(
                    width: width,
                    child: _Detail(
                      icon: Icons.radio_button_checked_rounded,
                      title: 'Status do alerta',
                      value: switch (alert.status) {
                        'active' => 'Ativo',
                        'acknowledged' => 'Recebimento confirmado',
                        'closed' => 'Encerrado',
                        _ => 'Em acompanhamento',
                      },
                      detail: alert.isSilent
                          ? 'Modo silencioso'
                          : 'Acompanhamento do alerta',
                    )),
                SizedBox(
                    width: width,
                    child: _Detail(
                      icon: Icons.schedule_rounded,
                      title: 'Iniciado às',
                      value:
                          DateFormat('HH:mm').format(alert.startedAt.toLocal()),
                      detail: DateFormat('dd/MM/yyyy')
                          .format(alert.startedAt.toLocal()),
                    )),
                SizedBox(
                    width: width,
                    child: _Detail(
                      icon: Icons.people_outline_rounded,
                      title: 'Sua rede de apoio',
                      value: demo ? 'Nenhum envio real' : _notificationHeadline,
                      detail: _notificationDetail,
                    )),
              ]);
            }),
            const SizedBox(height: 18),
            _AlertTrackingPanel(
              alert: alert,
              location: location,
              locationLoading: locationLoading,
              locationError: locationError,
              notificationHeadline: _notificationHeadline,
              notificationDetail: _notificationDetail,
              notificationSent: notification?.sent == true,
              notificationLoading: notificationLoading,
              notificationError: notificationError,
              contacts: contacts,
              contactsLoading: contactsLoading,
              contactsError: contactsError,
              demo: demo,
              onRefresh: onRefreshStatus,
            ),
            const SizedBox(height: 18),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: map),
                const SizedBox(width: 18),
                SizedBox(width: 330, child: actions),
              ])
            else ...[map, const SizedBox(height: 16), actions],
            const SizedBox(height: 14),
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.textMuted, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                'O ProtegeEla não substitui serviços oficiais. O navegador pode limitar atualizações quando estiver fechado.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              )),
            ]),
          ]),
        )),
      );
    });
  }

  Widget _map(BuildContext context, double height) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.my_location_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        demo
                            ? 'Localização de demonstração'
                            : 'Última localização disponível',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(_positionLabel,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ])),
              if (locationLoading)
                const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ])),
        SizedBox(
            height: height,
            child: Stack(children: [
              FlutterMap(
                // Recenter after a new capture, not after unrelated UI rebuilds.
                key: ValueKey(
                    '${alert.id}:${center.latitude}:${center.longitude}'),
                options: MapOptions(
                    initialCenter: center, initialZoom: _hasPosition ? 15 : 12),
                children: [
                  TileLayer(
                      tileProvider: tileProvider,
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.protegeela.app'),
                  if (_hasPosition)
                    MarkerLayer(markers: [
                      Marker(
                          point: center,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                                color:
                                    AppColors.emergency.withValues(alpha: 0.15),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.emergency, size: 44),
                          )),
                    ]),
                  RichAttributionWidget(attributions: [
                    TextSourceAttribution('OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse(
                            'https://www.openstreetmap.org/copyright'))),
                  ]),
                ],
              ),
              if (!_hasPosition)
                Positioned(
                    left: 16,
                    right: 16,
                    bottom: 40,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Mapa de referência. Sua posição ainda não está disponível.',
                            textAlign: TextAlign.center,
                          )),
                    )),
            ])),
      ]),
    );
  }

  Widget _actions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Como você está agora?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Escolha o próximo passo quando for seguro.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: busy ? null : onCall,
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            icon: const Icon(Icons.phone_in_talk_outlined),
            label: const Text('Ligar para emergência')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            onPressed: busy ? null : onUpdate,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Atualizar localização')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            onPressed: busy ? null : onSupport,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Encontrar apoio')),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        FilledButton.icon(
            onPressed: busy ? null : onSafe,
            style: FilledButton.styleFrom(backgroundColor: AppColors.safe),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Estou em local seguro')),
        const SizedBox(height: 6),
        TextButton(
            onPressed: busy ? null : onClose,
            child: const Text('Encerrar alerta')),
        if (busy)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator()),
      ]),
    );
  }
}

class _AlertTrackingPanel extends StatelessWidget {
  const _AlertTrackingPanel({
    required this.alert,
    required this.location,
    required this.locationLoading,
    required this.locationError,
    required this.notificationHeadline,
    required this.notificationDetail,
    required this.notificationSent,
    required this.notificationLoading,
    required this.notificationError,
    required this.contacts,
    required this.contactsLoading,
    required this.contactsError,
    required this.demo,
    required this.onRefresh,
  });

  final EmergencyAlert alert;
  final AlertLocation? location;
  final bool locationLoading;
  final bool locationError;
  final String notificationHeadline;
  final String notificationDetail;
  final bool notificationSent;
  final bool notificationLoading;
  final bool notificationError;
  final List<TrustedContact> contacts;
  final bool contactsLoading;
  final bool contactsError;
  final bool demo;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acompanhamento do alerta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Veja o que foi confirmado pelo sistema.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: notificationLoading ? null : onRefresh,
                tooltip: 'Atualizar acompanhamento',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TrackingStep(
            icon: Icons.check_circle_rounded,
            color: AppColors.safe,
            title: 'Alerta registrado',
            description: DateFormat('dd/MM/yyyy • HH:mm:ss')
                .format(alert.startedAt.toLocal()),
            complete: true,
          ),
          _TrackingConnector(
            complete: location != null || alert.locationStatus == 'captured',
          ),
          _TrackingStep(
            icon: locationError
                ? Icons.location_off_outlined
                : Icons.my_location_rounded,
            color: locationError ? AppColors.warning : AppColors.primary,
            title: locationLoading
                ? 'Atualizando localização…'
                : location != null
                    ? 'Localização atualizada'
                    : 'Localização não confirmada',
            description: location != null
                ? 'Último registro em ${DateFormat('HH:mm:ss').format(location!.capturedAt.toLocal())}.'
                : 'O alerta permanece ativo mesmo sem localização.',
            complete: location != null || alert.locationStatus == 'captured',
            loading: locationLoading,
          ),
          _TrackingConnector(complete: notificationSent),
          _TrackingStep(
            icon: notificationSent
                ? Icons.mark_chat_read_outlined
                : notificationError
                    ? Icons.error_outline_rounded
                    : Icons.chat_bubble_outline_rounded,
            color: notificationSent
                ? AppColors.safe
                : notificationError
                    ? AppColors.emergency
                    : AppColors.warning,
            title: notificationHeadline,
            description: notificationDetail,
            complete: notificationSent,
            loading: notificationLoading,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 17),
            child: Divider(),
          ),
          Text(
            'Rede de apoio',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            contactsLoading
                ? 'Carregando contatos…'
                : contactsError
                    ? 'Não foi possível consultar seus contatos.'
                    : contacts.isEmpty
                        ? 'Nenhum contato cadastrado.'
                        : '${contacts.length} contato${contacts.length == 1 ? '' : 's'} nesta rede.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          if (contactsLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ] else if (contacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < contacts.length; index++) ...[
              _ContactDeliveryRow(
                contact: contacts[index],
                demo: demo,
                notificationSent: notificationSent,
                notificationError: notificationError,
              ),
              if (index != contacts.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.complete,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool complete;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
        if (complete)
          const Icon(Icons.check_rounded, color: AppColors.safe, size: 20),
      ],
    );
  }
}

class _TrackingConnector extends StatelessWidget {
  const _TrackingConnector({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) => Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 18, top: 3, bottom: 3),
        color: complete ? AppColors.safe : AppColors.border,
      );
}

class _ContactDeliveryRow extends StatelessWidget {
  const _ContactDeliveryRow({
    required this.contact,
    required this.demo,
    required this.notificationSent,
    required this.notificationError,
  });

  final TrustedContact contact;
  final bool demo;
  final bool notificationSent;
  final bool notificationError;

  @override
  Widget build(BuildContext context) {
    final label = demo
        ? 'Demonstração'
        : notificationSent
            ? 'Envio solicitado'
            : notificationError
                ? 'Status indisponível'
                : 'Não enviado';
    final color = notificationSent ? AppColors.safe : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(
              contact.name.trim().isEmpty
                  ? '?'
                  : contact.name.trim()[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  contact.isPrimary
                      ? 'Contato principal'
                      : contact.relationship,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(
      {required this.icon,
      required this.title,
      required this.value,
      required this.detail});
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ])),
        ]),
      );
}
