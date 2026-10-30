import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_status_service_stub.dart'
    if (dart.library.html) 'network_status_service_web.dart';

final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final service = createNetworkStatusService();
  ref.onDispose(service.dispose);
  return service;
});

final networkStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(networkStatusServiceProvider);
  yield service.current;
  yield* service.changes;
});

abstract class NetworkStatusService {
  bool get current;
  Stream<bool> get changes;
  void dispose();
}
