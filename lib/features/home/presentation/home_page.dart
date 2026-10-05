import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/services/network_status_service.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../../features/emergency/data/emergency_controller.dart';
import '../../../features/check_in/presentation/safety_check_in_card.dart';
import '../../emergency/domain/emergency_state.dart';
import '../../../features/emergency/presentation/emergency_button.dart';
import '../../../features/profile/data/profile_repository.dart';
import 'widgets/protection_readiness_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final emergency = ref.watch(emergencyControllerProvider);
    ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      if (previous?.valueOrNull == false &&
          next.valueOrNull == true &&
          emergency.valueOrNull?.clientRequestId != null &&
          emergency.valueOrNull?.activeAlert == null) {
        ref
            .read(emergencyControllerProvider.notifier)
            .syncPendingAlert()
            .catchError((_) {});
      }
    });

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const AppStateView(
          title: 'Algo deu errado',
          message: 'Não foi possível carregar seu perfil.',
        ),
        data: (profile) {
          if (profile == null) {
            return const AppStateView(
              title: 'Perfil incompleto',
              message: 'Conclua seu perfil para usar o ProtegeEla.',
            );
          }

          final activeAlert = emergency.valueOrNull?.activeAlert;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 760;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 38 : 20,
                    desktop ? 30 : 18,
                    desktop ? 38 : 20,
                    30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!desktop) ...[
                            const ProtegeElaBrand(compact: true),
                            const SizedBox(height: 24),
                          ],
                          _HomeHeader(
                            firstName: profile.firstName,
                            activeAlert: activeAlert?.isActive == true,
                            onAlertTap: () => context.go('/alerta-ativo'),
                            onProfileTap: () => context.go('/perfil'),
                          ),
                          const SizedBox(height: 28),
                          if (desktop)
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _EmergencyPanel(
                                      emergency: emergency,
                                      ref: ref,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  const Expanded(
                                    flex: 4,
                                    child: _SafetyMessage(),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _EmergencyPanel(emergency: emergency, ref: ref),
                            const SizedBox(height: 16),
                            const _SafetyMessage(),
                          ],
                          if (emergency.valueOrNull?.lastMessage != null &&
                              emergency.valueOrNull?.clientRequestId != null &&
                              emergency.valueOrNull?.activeAlert == null) ...[
                            const SizedBox(height: 18),
                            _PendingAlertCard(
                              message: emergency.valueOrNull!.lastMessage!,
                              lastAttemptAt:
                                  emergency.valueOrNull!.lastAttemptAt,
                              online: ref
                                      .watch(networkStatusProvider)
                                      .valueOrNull ??
                                  true,
                              onSync: () async {
                                try {
                                  await ref
                                      .read(
                                          emergencyControllerProvider.notifier)
                                      .syncPendingAlert();
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Não foi possível sincronizar. Tente novamente.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 22),
                          ProtectionReadinessCard(profile: profile),
                          const SizedBox(height: 22),
                          const SafetyCheckInCard(),
                          const SizedBox(height: 22),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: desktop ? 3 : 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: desktop ? 1.9 : 1.15,
                            children: [
                              _Shortcut(
                                icon: Icons.map_outlined,
                                label: 'Mapa e apoio',
                                description: 'Alertas e serviços próximos',
                                onTap: () => context.go('/mapa'),
                              ),
                              _Shortcut(
                                icon: Icons.people_outline_rounded,
                                label: 'Contatos',
                                description: 'Sua rede de apoio',
                                onTap: () => context.go('/contatos'),
                              ),
                              _Shortcut(
                                icon: Icons.shield_outlined,
                                label: 'Denúncia',
                                description: 'Canal seguro e anônimo',
                                onTap: () => context.go('/denuncia-anonima'),
                              ),
                              _Shortcut(
                                icon: Icons.woman_2_outlined,
                                label: 'Delegacia',
                                description: 'Atendimento especializado',
                                onTap: () => context.go('/delegacia-da-mulher'),
                              ),
                              _Shortcut(
                                icon: Icons.menu_book_outlined,
                                label: 'Orientações',
                                description: 'Informação para você',
                                onTap: () => context.go('/orientacoes'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.activeAlert,
    required this.onAlertTap,
    required this.onProfileTap,
  });

  final String firstName;
  final bool activeAlert;
  final VoidCallback onAlertTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 3),
              Text(
                activeAlert
                    ? 'Seu alerta está ativo.'
                    : 'Que bom ter você por aqui.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (activeAlert)
          FilledButton.icon(
            onPressed: onAlertTap,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Ver alerta'),
          )
        else ...[
          IconButton(
            key: const ValueKey('home-profile-button'),
            onPressed: onProfileTap,
            tooltip: 'Abrir perfil',
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.accent,
              child: Text(
                firstName.isEmpty ? 'U' : firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmergencyPanel extends StatelessWidget {
  const _EmergencyPanel({required this.emergency, required this.ref});

  final AsyncValue<EmergencyState> emergency;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (emergency.hasError) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Não foi possível consultar seu alerta no servidor.'),
                  TextButton(
                      onPressed: () =>
                          ref.invalidate(emergencyControllerProvider),
                      child: const Text('Tentar novamente')),
                ],
              )));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Center(
          child: EmergencyButton(
            enabled: !emergency.isLoading &&
                !emergency.hasError &&
                emergency.valueOrNull?.isSending != true,
            onConfirmed: (
                {required isSilent, required publicVisibility}) async {
              try {
                await ref
                    .read(emergencyControllerProvider.notifier)
                    .createAlert(
                        isSilent: isSilent, publicVisibility: publicVisibility);
                if (context.mounted) context.go('/alerta-ativo');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'O servidor não confirmou o alerta. Confira a conexão e tente novamente.')),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

class _SafetyMessage extends StatelessWidget {
  const _SafetyMessage();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceSoft,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Você não está sozinha.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'O ProtegeEla ajuda você a acionar sua rede de apoio. Ele não substitui a polícia, serviços oficiais de emergência ou atendimento médico.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAlertCard extends StatelessWidget {
  const _PendingAlertCard({
    required this.message,
    required this.onSync,
    required this.online,
    this.lastAttemptAt,
  });

  final String message;
  final VoidCallback onSync;
  final bool online;
  final DateTime? lastAttemptAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              online ? Icons.sync_problem_rounded : Icons.cloud_off_outlined,
              color: online ? AppColors.primary : AppColors.emergency,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(online
                      ? message
                      : 'Sem internet. Seu alerta está aguardando conexão.'),
                  if (lastAttemptAt != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Última tentativa: ${TimeOfDay.fromDateTime(lastAttemptAt!).format(context)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: online ? onSync : null,
              icon: const Icon(Icons.sync),
              label: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 29),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
