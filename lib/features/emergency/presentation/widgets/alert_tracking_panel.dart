import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../../../shared/models/alert_location.dart';
import '../../../../shared/models/emergency_alert.dart';
import '../../../../shared/models/trusted_contact.dart';

class AlertTrackingPanel extends StatelessWidget {
  const AlertTrackingPanel({
    super.key,
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
            description: DateFormat(
              'dd/MM/yyyy • HH:mm:ss',
            ).format(alert.startedAt.toLocal()),
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
          Text('Rede de apoio', style: Theme.of(context).textTheme.titleMedium),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
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
