import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/safety_check_in.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../../emergency/data/emergency_controller.dart';
import '../data/safety_check_in_repository.dart';
import 'check_in_location_tracker.dart';

class SafetyCheckInCard extends ConsumerWidget {
  const SafetyCheckInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(currentSafetyCheckInProvider);
    final trackingStatus = ref.watch(checkInTrackingStatusProvider);
    return checkIn.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Expanded(
                child: Text('Não foi possível consultar o acompanhamento.'),
              ),
              TextButton(
                onPressed: () => ref.invalidate(currentSafetyCheckInProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (value) => value == null
          ? _StartCheckInCard(onStart: () => _start(context, ref))
          : _ActiveCheckInCard(
              checkIn: value,
              onComplete: () => _finish(context, ref, complete: true),
              onCancel: () => _finish(context, ref, complete: false),
              trackingStatus: trackingStatus,
              onShare: () => _shareTrip(context, ref, value),
              onRefresh: () {
                ref.invalidate(currentSafetyCheckInProvider);
                ref.invalidate(emergencyControllerProvider);
              },
            ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    if (await ref.read(demoSessionProvider.future)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Entre em uma conta para iniciar um acompanhamento.'),
        ));
      }
      return;
    }
    if (!context.mounted) return;
    final setup = await showDialog<_CheckInSetup>(
      context: context,
      builder: (context) => const _DurationDialog(),
    );
    if (setup == null || !context.mounted) return;
    try {
      final location = setup.shareLocation
          ? await ref.read(locationServiceProvider).captureCurrent()
          : null;
      final checkIn = await ref.read(safetyCheckInRepositoryProvider).start(
            durationMinutes: setup.minutes,
            shareLocation: setup.shareLocation,
            location: location,
          );
      ref.invalidate(currentSafetyCheckInProvider);
      if (checkIn.shareUrl != null && context.mounted) {
        await _showShareDialog(context, checkIn.shareUrl!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Acompanhamento iniciado por ${setup.minutes} minutos.',
            ),
          ),
        );
      }
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível iniciar o acompanhamento.'),
        ));
      }
    }
  }

  Future<void> _shareTrip(
    BuildContext context,
    WidgetRef ref,
    SafetyCheckIn checkIn,
  ) async {
    try {
      final url = checkIn.shareUrl ??
          await ref
              .read(safetyCheckInRepositoryProvider)
              .createShareLink(checkIn.id);
      ref.invalidate(currentSafetyCheckInProvider);
      if (context.mounted) await _showShareDialog(context, url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível criar o link do trajeto.'),
        ));
      }
    }
  }

  Future<void> _showShareDialog(BuildContext context, String url) async {
    final message = Uri.encodeComponent(
      'Acompanhe meu trajeto no ProtegeEla: $url',
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartilhar trajeto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Envie este link somente para pessoas de confiança. Elas verão sua posição e o caminho percorrido.',
            ),
            const SizedBox(height: 14),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar'),
          ),
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://wa.me/?text=$message'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref, {
    required bool complete,
  }) async {
    try {
      final repository = ref.read(safetyCheckInRepositoryProvider);
      if (complete) {
        await repository.complete();
      } else {
        await repository.cancel();
      }
      ref.invalidate(currentSafetyCheckInProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(complete
              ? 'Que bom que você chegou bem. Acompanhamento encerrado.'
              : 'Acompanhamento cancelado.'),
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível confirmar a ação.'),
        ));
      }
    }
  }
}

class _StartCheckInCard extends StatelessWidget {
  const _StartCheckInCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.surfaceSoft,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.route_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cheguei bem',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    const Text(
                      'Defina quando pretende chegar. Se você não confirmar após a tolerância, um alerta será criado pelo servidor.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.timer_outlined),
                      label: const Text('Acompanhar trajeto'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActiveCheckInCard extends StatefulWidget {
  const _ActiveCheckInCard({
    required this.checkIn,
    required this.onComplete,
    required this.onCancel,
    required this.onRefresh,
    required this.trackingStatus,
    required this.onShare,
  });

  final SafetyCheckIn checkIn;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final CheckInTrackingStatus trackingStatus;
  final VoidCallback onShare;

  @override
  State<_ActiveCheckInCard> createState() => _ActiveCheckInCardState();
}

class _ActiveCheckInCardState extends State<_ActiveCheckInCard> {
  Timer? _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ticks++);
      if (_ticks % 15 == 0 &&
          DateTime.now().isAfter(widget.checkIn.expiresAt)) {
        widget.onRefresh();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final untilExpected = widget.checkIn.expectedAt.toLocal().difference(now);
    final untilExpiry = widget.checkIn.expiresAt.toLocal().difference(now);
    final inGrace = untilExpected.isNegative && !untilExpiry.isNegative;
    final remaining = inGrace ? untilExpiry : untilExpected;
    final expired = untilExpiry.isNegative;
    final totalSeconds = remaining.inSeconds.abs();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final timerText = expired
        ? 'Tolerância encerrada'
        : '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Card(
      color: inGrace || expired
          ? AppColors.emergency.withValues(alpha: 0.045)
          : AppColors.surfaceSoft,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  inGrace || expired
                      ? Icons.warning_amber_rounded
                      : Icons.route,
                  color: inGrace || expired
                      ? AppColors.emergency
                      : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    inGrace ? 'Confirme que chegou bem' : 'Trajeto acompanhado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  timerText,
                  style: TextStyle(
                    color: inGrace || expired
                        ? AppColors.emergency
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              expired
                  ? 'O servidor está verificando o atraso e poderá criar um alerta.'
                  : inGrace
                      ? 'Você está no período de tolerância de ${widget.checkIn.graceMinutes} minutos.'
                      : 'Chegada prevista para ${DateFormat('HH:mm').format(widget.checkIn.expectedAt.toLocal())}.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            if (widget.checkIn.shareLocation) ...[
              _TrackingStatus(
                status: widget.trackingStatus,
                lastLocationAt: widget.checkIn.lastLocationAt,
                onShare: widget.onShare,
              ),
              const SizedBox(height: 14),
            ] else ...[
              OutlinedButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Compartilhar meu trajeto'),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: expired ? null : widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: expired ? null : widget.onComplete,
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.safe),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Cheguei bem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog();

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  int _minutes = 30;
  bool _shareLocation = true;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Quando você pretende chegar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolha o tempo do trajeto. Haverá mais 5 minutos de tolerância para confirmação.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const [15, 30, 60, 120])
                  ChoiceChip(
                    showCheckmark: false,
                    selected: _minutes == option,
                    onSelected: (_) => setState(() => _minutes = option),
                    label:
                        Text(option < 60 ? '$option min' : '${option ~/ 60} h'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _shareLocation,
              onChanged: (value) => setState(() => _shareLocation = value),
              secondary: const Icon(Icons.location_on_outlined),
              title: const Text('Compartilhar trajeto'),
              subtitle: const Text(
                'Sua rede de confiança poderá acompanhar sua localização por um link privado.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _CheckInSetup(_minutes, _shareLocation),
            ),
            child: const Text('Iniciar'),
          ),
        ],
      );
}

class _CheckInSetup {
  const _CheckInSetup(this.minutes, this.shareLocation);

  final int minutes;
  final bool shareLocation;
}

class _TrackingStatus extends StatelessWidget {
  const _TrackingStatus({
    required this.status,
    required this.lastLocationAt,
    required this.onShare,
  });

  final CheckInTrackingStatus status;
  final DateTime? lastLocationAt;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final unavailable = status == CheckInTrackingStatus.unavailable;
    final updating = status == CheckInTrackingStatus.updating;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            unavailable
                ? Icons.location_off_outlined
                : Icons.location_on_rounded,
            color: unavailable ? AppColors.emergency : AppColors.safe,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unavailable
                      ? 'Localização temporariamente indisponível'
                      : updating
                          ? 'Atualizando localização...'
                          : 'Trajeto compartilhado',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (lastLocationAt != null)
                  Text(
                    'Último envio às ${DateFormat('HH:mm:ss').format(lastLocationAt!.toLocal())}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Enviar link'),
          ),
        ],
      ),
    );
  }
}
