import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/protegeela_brand.dart';
import '../../../shared/models/app_profile.dart';
import '../../authentication/data/auth_repository.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../data/profile_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                desktop ? 38 : 18,
                desktop ? 28 : 16,
                desktop ? 38 : 18,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!desktop) ...[
                        const ProtegeElaBrand(compact: true),
                        const SizedBox(height: 20),
                      ],
                      const AppPageHeader(
                        title: 'Perfil',
                        subtitle: 'Preferências, privacidade e segurança.',
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: profile.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, __) => const AppStateView(
                            title: 'Erro',
                            message: 'Não foi possível carregar seu perfil.',
                          ),
                          data: (value) {
                            if (value == null) {
                              return AppStateView(
                                title: 'Perfil incompleto',
                                message: 'Crie seu perfil para continuar.',
                                actionLabel: 'Criar perfil',
                                onAction: () => context.go('/criar-perfil'),
                              );
                            }
                            return _ProfileContent(
                              profile: value,
                              onPrivacyChanged: (enabled) =>
                                  _updatePrivacyMode(ref, enabled),
                              onSignOut: () => _signOut(context, ref),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _updatePrivacyMode(
    WidgetRef ref,
    bool enabled,
  ) async {
    final demoActive = await ref.read(demoSessionProvider.future);
    final privacyMode = enabled ? 'discreet' : 'standard';
    if (demoActive) {
      final current = ref.read(demoProfileProvider);
      ref.read(demoProfileProvider.notifier).state = current.copyWith(
        privacyMode: privacyMode,
      );
      return;
    }
    await ref.read(profileRepositoryProvider).updatePrivacyMode(privacyMode);
    ref.invalidate(currentProfileProvider);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final demoActive = await ref.read(demoSessionProvider.future);
    if (demoActive) {
      await ref.read(demoSessionRepositoryProvider).end();
      ref.invalidate(demoSessionProvider);
    } else {
      await ref.read(authRepositoryProvider).signOut();
    }
    if (context.mounted) context.go('/login');
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onPrivacyChanged,
    required this.onSignOut,
  });

  final AppProfile profile;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial =
        profile.firstName.isEmpty ? 'U' : profile.firstName[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.id == 'demo-user'
                            ? 'Conta de demonstração'
                            : profile.phone,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/editar-perfil'),
                  child: const Text('Editar perfil'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Preferências e privacidade',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _PreferenceTile(
                title: 'Textos discretos nas notificações',
                subtitle: 'Exibe mensagens sem detalhes sensíveis.',
                value: profile.privacyMode == 'discreet',
                onChanged: onPrivacyChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Privacidade'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/privacidade-conta'),
              ),
              if (profile.isAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Painel administrativo'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/admin'),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Sair'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
