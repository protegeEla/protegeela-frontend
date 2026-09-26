import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../profile/data/profile_repository.dart';
import '../data/admin_repository.dart';

final adminMetricsProvider = FutureProvider<AdminDashboardMetrics>((ref) {
  return ref.watch(adminRepositoryProvider).metrics();
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile?.isAdmin != true) {
      return const Scaffold(
          body: AppStateView(
              title: 'Acesso restrito',
              message: 'Somente administradores podem acessar este painel.'));
    }

    final metrics = ref.watch(adminMetricsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Administracao'),
      ),
      body: metrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppStateView(
          title: 'Erro',
          message: 'Não foi possível carregar indicadores.',
          actionLabel: 'Tentar novamente',
          onAction: () => ref.invalidate(adminMetricsProvider),
        ),
        data: (data) => GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _Metric(label: 'Alertas', value: data.totalAlerts),
            _Metric(label: 'Ativos', value: data.activeAlerts),
            _Metric(label: 'Encerrados', value: data.closedAlerts),
            _Metric(
                label: 'Pontos verificados', value: data.verifiedSupportPoints),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}
