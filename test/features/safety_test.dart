import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:protegeela/core/errors/app_exception.dart';
import 'package:protegeela/core/services/api_client.dart';
import 'package:protegeela/features/emergency/data/emergency_repository.dart';
import 'package:protegeela/features/emergency/data/pending_alert_store.dart';

import '../core/api_client_test.dart' show login;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'silent alert never requests public visibility; server error propagates',
    () async {
      final api = ApiClient(
        'https://api.example.invalid/api',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['is_silent'], isTrue);
          expect(body['public_visibility'], isFalse);
          expect(body['location'], isNull);
          expect(body['client_request_id'], 'test-request');
          return http.Response('{}', 503);
        }),
      );
      addTearDown(api.dispose);
      await login(api);
      await expectLater(
        EmergencyRepository(api).createAlert(
          clientRequestId: 'test-request',
          alertType: 'immediate_danger',
          isSilent: true,
          publicVisibility: true,
          locationStatus: 'location_denied',
        ),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'http_503')),
      );
    },
  );

  test(
    'pending alerts are account scoped, expire and contain no coordinates',
    () async {
      final store = PendingAlertStore('test-user');
      final pending = PendingAlert(
        clientRequestId: 'test-request',
        alertType: 'immediate_danger',
        isSilent: true,
        createdAt: DateTime.now().toUtc(),
      );
      await store.save(pending);
      expect((await store.read())?.clientRequestId, 'test-request');
      expect(await PendingAlertStore('other-test-user').read(), isNull);
      expect(pending.toJson().keys, isNot(contains('location')));
      await store.save(
        PendingAlert(
          clientRequestId: 'expired',
          alertType: 'immediate_danger',
          isSilent: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      );
      expect(await store.read(), isNull);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  test('corrupted pending data is discarded', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('protegeela.pending_alert.test-user', '{invalid');
    expect(await PendingAlertStore('test-user').read(), isNull);
    expect(prefs.getKeys(), isEmpty);
  });
}
