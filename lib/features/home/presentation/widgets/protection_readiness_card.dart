import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/models/app_profile.dart';
import '../../../trusted_contacts/data/trusted_contacts_repository.dart';

class ProtectionReadinessCard extends ConsumerWidget {
  const ProtectionReadinessCard({super.key, required this.profile});

  final AppProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(trustedContactsProvider);
    final location = ref.watch(locationReadinessProvider);
    final contactList = contacts.valueOrNull ?? const [];
    final profileReady = profile.fullName.trim().isNotEmpty &&
        profile.phone.replaceAll(RegExp(r'\D'), '').length >= 10;
    final contactsReady = contactList.length >= 2;
    final confirmedContact = contactList.any(
      (contact) => contact.invitationStatus == 'accepted',
    );
    final locationReady = location.valueOrNull == LocationReadiness.ready;
    final completed = [
      profileReady,
      locationReady,
      contactsReady,
      confirmedContact,
    ].where((ready) => ready).length;

    final steps = [
      _ReadinessStep(
        title: 'Dados pessoais preenchidos',
        description: profileReady
            ? 'Nome e telefone estão prontos.'
            : 'Complete seu nome e telefone.',
        complete: profileReady,
        onTap: profileReady ? null : () => context.go('/editar-perfil'),
      ),
      _ReadinessStep(
        title: 'Localização autorizada',
        description: _locationDescription(location),
        complete: locationReady,
        loading: location.isLoading,
        onTap: locationReady || location.isLoading
            ? null
            : () => _requestLocation(context, ref),
      ),
      _ReadinessStep(
        title: 'Dois contatos cadastrados',
        description: contacts.isLoading
            ? 'Consultando sua rede de apoio…'
            : '${contactList.length} de 2 contatos cadastrados.',
        complete: contactsReady,
        loading: contacts.isLoading,
        onTap: contactsReady ? null : () => context.go('/contatos'),
      ),
      _ReadinessStep(
        title: 'Contato confirmado',
        description: contacts.hasError
            ? 'Não foi possível consultar os contatos.'
            : confirmedContact
                ? 'Sua rede possui um contato confirmado.'
                : 'Convites estarão disponíveis com o envio de mensagens.',
        complete: confirmedContact,
        loading: contacts.isLoading,
        onTap: confirmedContact ? null : () => context.go('/contatos'),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: completed == steps.length
                        ? AppColors.safe.withValues(alpha: 0.1)
                        : AppColors.accent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    completed == steps.length
                        ? Icons.verified_user_rounded
                        : Icons.shield_outlined,
                    color: completed == steps.length
                        ? AppColors.safe
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minha proteção está pronta?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        completed == steps.length
                            ? 'As etapas disponíveis estão concluídas.'
                            : '$completed de ${steps.length} etapas concluídas',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(completed / steps.length * 100).round()}%',
                  style: TextStyle(
                    color: completed == steps.length
                        ? AppColors.safe
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: completed / steps.length,
                minHeight: 8,
                color: completed == steps.length
                    ? AppColors.safe
                    : AppColors.primary,
                backgroundColor: AppColors.surfaceSoft,
              ),
            ),
            const SizedBox(height: 17),
            for (var index = 0; index < steps.length; index++) ...[
              _ReadinessRow(step: steps[index]),
              if (index != steps.length - 1) const SizedBox(height: 9),
            ],
            const SizedBox(height: 14),
            const Text(
              'O checklist ajuda na preparação, mas não garante o envio de mensagens nem substitui serviços de emergência.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  String _locationDescription(AsyncValue<LocationReadiness> value) {
    if (value.isLoading) return 'Verificando a permissão…';
    if (value.hasError) return 'Não foi possível verificar a permissão.';
    return switch (value.valueOrNull) {
      LocationReadiness.ready => 'Permissão disponível para os alertas.',
      LocationReadiness.serviceDisabled =>
        'A localização está desativada no dispositivo.',
      LocationReadiness.blocked =>
        'A permissão está bloqueada nas configurações do navegador.',
      _ => 'Permita o uso da localização quando for seguro.',
    };
  }

  Future<void> _requestLocation(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(locationServiceProvider).requestAccess();
      ref.invalidate(locationReadinessProvider);
      if (!context.mounted || result == LocationReadiness.ready) return;
      final message = switch (result) {
        LocationReadiness.serviceDisabled =>
          'Ative a localização do dispositivo e tente novamente.',
        LocationReadiness.blocked =>
          'Libere a localização nas configurações do navegador.',
        _ => 'A localização não foi autorizada.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível solicitar a localização.'),
          ),
        );
      }
    }
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.step});

  final _ReadinessStep step;

  @override
  Widget build(BuildContext context) {
    final color = step.complete ? AppColors.safe : AppColors.textMuted;
    return Material(
      color: step.complete
          ? AppColors.safe.withValues(alpha: 0.045)
          : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: step.onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              if (step.loading)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  step.complete
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: color,
                  size: 22,
                ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (step.onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessStep {
  const _ReadinessStep({
    required this.title,
    required this.description,
    required this.complete,
    this.loading = false,
    this.onTap,
  });

  final String title;
  final String description;
  final bool complete;
  final bool loading;
  final VoidCallback? onTap;
}
