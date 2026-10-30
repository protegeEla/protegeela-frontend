// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'network_status_service.dart';

NetworkStatusService createNetworkStatusService() => _WebNetworkStatusService();

class _WebNetworkStatusService implements NetworkStatusService {
  _WebNetworkStatusService() {
    _onlineSubscription = html.window.onOnline.listen((_) {
      _current = true;
      _controller.add(true);
    });
    _offlineSubscription = html.window.onOffline.listen((_) {
      _current = false;
      _controller.add(false);
    });
  }

  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription<html.Event> _onlineSubscription;
  late final StreamSubscription<html.Event> _offlineSubscription;
  bool _current = html.window.navigator.onLine ?? true;

  @override
  bool get current => _current;

  @override
  Stream<bool> get changes => _controller.stream.distinct();

  @override
  void dispose() {
    _onlineSubscription.cancel();
    _offlineSubscription.cancel();
    _controller.close();
  }
}
