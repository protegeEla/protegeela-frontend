import 'network_status_service.dart';

NetworkStatusService createNetworkStatusService() =>
    _AlwaysOnlineNetworkStatusService();

class _AlwaysOnlineNetworkStatusService implements NetworkStatusService {
  @override
  bool get current => true;

  @override
  Stream<bool> get changes => const Stream.empty();

  @override
  void dispose() {}
}
