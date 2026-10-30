import '../../../core/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/support_point.dart';
import '../../authentication/data/demo_session_repository.dart';

final supportPointsRepositoryProvider =
    Provider<SupportPointsRepository>((ref) {
  return SupportPointsRepository(ref.watch(apiClientProvider));
});

final supportPointsProvider = FutureProvider<List<SupportPoint>>((ref) async {
  final demoActive = await ref.watch(demoSessionProvider.future);
  if (demoActive) {
    return const [
      SupportPoint(
        id: 'demo-support-center',
        name: 'Centro de acolhimento (demonstração)',
        category: 'support_center',
        description:
            'Exemplo fictício de local com escuta, acolhimento e orientação.',
        address: 'Endereço demonstrativo — Centro',
        city: 'Manaus',
        state: 'AM',
        latitude: -3.1190,
        longitude: -60.0217,
        isVerified: false,
        openingHours: 'Exemplo: atendimento 24 horas',
      ),
      SupportPoint(
        id: 'demo-police-station',
        name: 'Atendimento policial (demonstração)',
        category: 'police_station',
        description:
            'Exemplo fictício de unidade para registro e orientação imediata.',
        address: 'Endereço demonstrativo — Adrianópolis',
        city: 'Manaus',
        state: 'AM',
        latitude: -3.1018,
        longitude: -60.0112,
        isVerified: false,
        openingHours: 'Exemplo: todos os dias',
      ),
      SupportPoint(
        id: 'demo-health',
        name: 'Unidade de saúde (demonstração)',
        category: 'health',
        description:
            'Exemplo fictício de atendimento de saúde e suporte emergencial.',
        address: 'Endereço demonstrativo — Praça 14',
        city: 'Manaus',
        state: 'AM',
        latitude: -3.1278,
        longitude: -60.0097,
        isVerified: false,
        openingHours: 'Exemplo: 7h às 19h',
      ),
      SupportPoint(
        id: 'demo-legal',
        name: 'Orientação jurídica (demonstração)',
        category: 'legal',
        description:
            'Exemplo fictício de apoio jurídico e orientação sobre direitos.',
        address: 'Endereço demonstrativo — Aleixo',
        city: 'Manaus',
        state: 'AM',
        latitude: -3.0952,
        longitude: -59.9875,
        isVerified: false,
        openingHours: 'Exemplo: segunda a sexta',
      ),
    ];
  }
  return ref.watch(supportPointsRepositoryProvider).list();
});

class SupportPointsRepository {
  const SupportPointsRepository(this._api);
  final ApiClient _api;

  Future<List<SupportPoint>> list() async =>
      (await _api.list('/support-points')).map(SupportPoint.fromJson).toList();
}
