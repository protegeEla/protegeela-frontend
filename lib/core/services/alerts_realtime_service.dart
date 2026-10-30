import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

/// WebSocket carries invalidations only. Alert data is fetched through REST.
class AlertsRealtimeService {
  AlertsRealtimeService(this._api, {required this.onChanged}) {
    _session = _api.sessionChanges.listen((_) {
      _disconnect();
      if (_enabled && _api.isAuthenticated) _connect();
    });
  }

  final ApiClient _api;
  final void Function() onChanged;
  late final StreamSubscription<void> _session;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messages;
  Timer? _retry;
  Timer? _heartbeat;
  Timer? _authTimeout;
  int _generation = 0;
  int _attempt = 0;
  bool _enabled = false;
  bool _disposed = false;
  bool isConnected = false;
  DateTime _lastPong = DateTime.now();

  void start() {
    if (_disposed) return;
    _enabled = true;
    if (_channel == null && _retry == null && _api.isAuthenticated) _connect();
  }

  void pause() {
    _enabled = false;
    _disconnect();
  }

  Future<void> _connect() async {
    if (!_enabled || _disposed || !_api.isAuthenticated) return;
    final generation = ++_generation;
    try {
      final channel = WebSocketChannel.connect(_api.alertsWebSocketUri);
      _channel = channel;
      _messages = channel.stream.listen(
        (message) {
          if (generation != _generation) return;
          try {
            final data = jsonDecode(message as String);
            if (data is! Map) throw const FormatException();
            switch (data['type']) {
              case 'ready':
                _authTimeout?.cancel();
                isConnected = true;
                _attempt = 0;
                _lastPong = DateTime.now();
                onChanged(); // Recover updates missed while disconnected.
                _heartbeat?.cancel();
                _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
                  if (DateTime.now().difference(_lastPong).inSeconds > 40) {
                    _failed(generation);
                  } else {
                    try {
                      channel.sink.add('{"type":"ping"}');
                    } catch (_) {
                      _failed(generation);
                    }
                  }
                });
              case 'pong':
                _lastPong = DateTime.now();
              case 'alerts_changed':
                if (isConnected) onChanged();
            }
          } catch (_) {
            _failed(generation);
          }
        },
        onError: (_) => _failed(generation),
        onDone: () => _failed(generation),
      );
      await channel.ready.timeout(const Duration(seconds: 8));
      if (generation != _generation) return;
      final frame = _api.realtimeAuthenticationFrame();
      if (frame == null) {
        _disconnect();
        return;
      }
      channel.sink.add(frame);
      _authTimeout =
          Timer(const Duration(seconds: 8), () => _failed(generation));
    } catch (_) {
      _failed(generation);
    }
  }

  void _failed(int generation) {
    if (generation != _generation) return;
    _disconnect();
    if (!_enabled || _disposed || !_api.isAuthenticated) return;
    final delay = [2, 5, 10, 20, 30][_attempt.clamp(0, 4)];
    _attempt++;
    _retry = Timer(Duration(seconds: delay), () {
      _retry = null;
      _connect();
    });
  }

  void _disconnect() {
    _generation++;
    isConnected = false;
    _retry?.cancel();
    _retry = null;
    _heartbeat?.cancel();
    _authTimeout?.cancel();
    final messages = _messages;
    _messages = null;
    if (messages != null) unawaited(messages.cancel());
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close().catchError((_) {}));
  }

  void dispose() {
    _disposed = true;
    pause();
    unawaited(_session.cancel());
  }
}
