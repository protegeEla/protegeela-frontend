import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:protegeela/core/errors/app_exception.dart';
import 'package:protegeela/core/services/api_client.dart';

Future<void> login(ApiClient api, {String id = 'test-user'}) => api.setSession(
  {
    'token': 'a' * 43,
    'profile': {'id': id},
  },
  'test@example.invalid',
  rememberMe: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'public login does not send a bearer; protected calls require login',
    () async {
      var calls = 0;
      final api = ApiClient(
        'https://api.example.invalid/api/',
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/auth/login');
          expect(request.headers['Authorization'], isNull);
          expect(jsonDecode(request.body), {'email': 'test@example.invalid'});
          return http.Response('{}', 200);
        }),
      );
      addTearDown(api.dispose);
      await expectLater(
        api.request('GET', '/profile'),
        throwsA(isA<AppException>()),
      );
      expect(calls, 0);
      await api.request(
        'POST',
        '/auth/login',
        authenticated: false,
        body: {'email': 'test@example.invalid'},
      );
      expect(calls, 1);
    },
  );

  test('401 clears session and notifies listeners', () async {
    final api = ApiClient(
      'https://api.example.invalid/api',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer ${'a' * 43}');
        return http.Response('{}', 401);
      }),
    );
    addTearDown(api.dispose);
    await login(api);
    final changed = api.sessionChanges.first;
    await expectLater(
      api.request('GET', '/profile'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'http_401')),
    );
    await changed;
    expect(api.isAuthenticated, isFalse);
    expect(api.userId, isNull);
  });

  test('response from previous account cannot expire a new session', () async {
    final response = Completer<http.Response>();
    final api = ApiClient(
      'https://api.example.invalid/api',
      client: MockClient((_) => response.future),
    );
    addTearDown(api.dispose);
    await login(api);
    final request = api.request('GET', '/profile');
    final assertion = expectLater(
      request,
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'session_changed'),
      ),
    );
    await login(api, id: 'other-test-user');
    response.complete(http.Response('{}', 401));
    await assertion;
    expect(api.userId, 'other-test-user');
    expect(api.isAuthenticated, isTrue);
  });

  for (final body in ['not json', '[]']) {
    test('invalid response is reported safely: $body', () async {
      final api = ApiClient(
        'https://api.example.invalid/api',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.dispose);
      await expectLater(
        api.request('GET', '/public', authenticated: false),
        throwsA(isA<AppException>()),
      );
    });
  }

  test('network errors are surfaced without server details', () async {
    final api = ApiClient(
      'https://api.example.invalid/api',
      client: MockClient(
        (_) async => throw http.ClientException('internal detail'),
      ),
    );
    addTearDown(api.dispose);
    await expectLater(
      api.request('GET', '/public', authenticated: false),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          isNot(contains('internal detail')),
        ),
      ),
    );
  });

  test('remembered session restores and is removed by logout', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final api = ApiClient('https://api.example.invalid/api', storage: storage);
    addTearDown(api.dispose);
    await api.setSession(
      {
        'token': 'a' * 43,
        'profile': {'id': 'test-user'},
      },
      'test@example.invalid',
      rememberMe: true,
    );
    final restored = ApiClient(
      'https://api.example.invalid/api',
      storage: storage,
    );
    addTearDown(restored.dispose);
    await restored.restoreSession();
    expect(restored.userId, 'test-user');
    expect(
      restored.alertsWebSocketUri.toString(),
      'wss://api.example.invalid/api/ws/alerts',
    );
    expect(restored.alertsWebSocketUri.query, isEmpty);
    await restored.clearSession();
    expect(await storage.readAll(), isEmpty);
  });
}
