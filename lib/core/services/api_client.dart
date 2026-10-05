import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(ref.watch(appConfigProvider).apiBaseUrl);
  ref.onDispose(client.dispose);
  return client;
});

/// Keeps a regular session in memory and persists it only when requested.
class ApiClient {
  ApiClient(
    String baseUrl, {
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
        _client = client ?? http.Client(),
        _storage = storage;

  static const _persistentSessionKey = 'protegeela.auth.session.v1';

  final String _baseUrl;
  final http.Client _client;
  final FlutterSecureStorage? _storage;
  final _changes = StreamController<void>.broadcast();
  String? _token;
  int _sessionVersion = 0;
  String? userId;
  String? email;

  Stream<void> get sessionChanges => _changes.stream;
  bool get isAuthenticated => _token != null;

  Uri get alertsWebSocketUri {
    final base = Uri.parse('$_baseUrl/ws/alerts');
    return base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws');
  }

  // Authenticate in the first frame; never include the bearer token in a URL.
  String? realtimeAuthenticationFrame() => _token == null
      ? null
      : jsonEncode({'type': 'authenticate', 'token': _token});
  Future<void> restoreSession() async {
    final storage = _storage;
    if (storage == null) return;

    String? encoded;
    try {
      encoded = await storage.read(key: _persistentSessionKey);
    } catch (_) {
      return;
    }
    if (encoded == null) return;

    try {
      final data = jsonDecode(encoded);
      if (data is! Map ||
          data['token'] is! String ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(data['token'] as String) ||
          data['user_id'] is! String ||
          (data['user_id'] as String).isEmpty ||
          data['email'] is! String ||
          (data['email'] as String).isEmpty) {
        throw const FormatException();
      }
      _token = data['token'] as String;
      userId = data['user_id'] as String;
      email = data['email'] as String;
      _sessionVersion++;
    } catch (_) {
      _resetSession();
      try {
        await storage.delete(key: _persistentSessionKey);
      } catch (_) {}
    }
  }

  Future<void> setSession(Map<String, dynamic> data, String userEmail,
      {required bool rememberMe}) async {
    final token = data['token'];
    final profile = data['profile'];
    if (token is! String ||
        token.isEmpty ||
        profile is! Map ||
        profile['id'] is! String ||
        (profile['id'] as String).isEmpty) {
      throw const AppException('Resposta inválida do servidor.');
    }
    _token = token;
    _sessionVersion++;
    userId = profile['id'] as String;
    email = userEmail.trim();
    try {
      final storage = _storage;
      if (storage != null) {
        if (rememberMe) {
          await storage.write(
            key: _persistentSessionKey,
            value: jsonEncode({
              'token': _token,
              'user_id': userId,
              'email': email,
            }),
          );
        } else {
          await storage.delete(key: _persistentSessionKey);
        }
      }
    } catch (_) {
      _resetSession();
      throw const AppException(
          'N\u00e3o foi poss\u00edvel manter a sess\u00e3o neste dispositivo.');
    }
    _changes.add(null);
  }

  Future<void> clearSession() async {
    _resetSession();
    try {
      final storage = _storage;
      if (storage != null) {
        await storage.delete(key: _persistentSessionKey);
      }
    } finally {
      _changes.add(null);
    }
  }

  void _resetSession() {
    _sessionVersion++;
    _token = null;
    userId = null;
    email = null;
  }

  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, dynamic>? body, bool authenticated = true}) async {
    final token = _token;
    final sessionVersion = _sessionVersion;
    if (authenticated && token == null) {
      throw const AppException('Sessão expirada. Entre novamente.');
    }
    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'));
      request.headers['Accept'] = 'application/json';
      if (authenticated) request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      if (authenticated && sessionVersion != _sessionVersion) {
        throw const AppException(
            'A sessão mudou. Atualize a página antes de continuar.',
            code: 'session_changed');
      }
      if (response.statusCode == 401 && authenticated && _token == token) {
        await clearSession();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
            switch (response.statusCode) {
              401 => authenticated
                  ? 'Sessão expirada. Entre novamente.'
                  : 'E-mail ou senha inválidos.',
              409 => path == '/auth/register'
                  ? 'Este e-mail já está cadastrado.'
                  : 'A operação conflita com o estado atual. Atualize os dados e tente novamente.',
              400 => 'Confira os dados informados e tente novamente.',
              403 => 'Você não tem permissão para esta ação.',
              429 when path == '/auth/login' || path == '/auth/register' =>
                'Muitas tentativas. Aguarde 15 minutos e tente novamente.',
              _ => 'Não foi possível concluir a solicitação. Tente novamente.',
            },
            code: 'http_${response.statusCode}');
      }
      if (response.statusCode == 204) return {};
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      return data;
    } on TimeoutException {
      throw const AppException(
          'O servidor demorou a responder. Tente novamente.');
    } on http.ClientException {
      throw const AppException(
          'Não foi possível conectar ao servidor. Verifique sua conexão.');
    } on FormatException {
      throw const AppException('Resposta inválida do servidor.');
    }
  }

  void dispose() {
    _client.close();
    _changes.close();
  }

  Future<List<Map<String, dynamic>>> list(String path) async {
    final data = await request('GET', path);
    final items = data['items'];
    if (items is! List || items.any((item) => item is! Map<String, dynamic>)) {
      throw const AppException('Resposta inválida do servidor.');
    }
    return items.cast<Map<String, dynamic>>();
  }
}
