import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/configure_web_host.dart';

void main() {
  test('deployment requires public HTTPS API and rejects policy injection', () {
    for (final value in [
      '',
      'http://example.invalid/api',
      'https://localhost/api',
      'https://a.invalid/api?token=x',
      'https://user:pass@a.invalid/api',
      'https://a.invalid/api; script-src *',
    ]) {
      expect(() => validateEndpoint(value), throwsArgumentError);
    }
    expect(validateEndpoint('https://api.example.invalid:8443/api').port, 8443);
  });

  test('CSP permits configured HTTPS, WSS and self-hosted map resources', () {
    final policy = securityPolicy(
      validateEndpoint('https://api.example.invalid/api'),
    );
    expect(
      policy,
      contains(
        "connect-src 'self' https://api.example.invalid wss://api.example.invalid https://tile.openstreetmap.org",
      ),
    );
    expect(policy, contains("frame-ancestors 'none'"));
  });

  test('SPA rewrites cover actual routes without swallowing assets or API', () {
    final rewrites = routeRewrites(
      File('lib/app/router.dart').readAsStringSync(),
    );
    expect(rewrites, contains('/home /index.html 200'));
    expect(rewrites, contains('/convite/:token /index.html 200'));
    expect(rewrites, contains('/trajeto/:token /index.html 200'));
    expect(rewrites, isNot(contains('/*')));
    expect(rewrites, isNot(contains('/api')));
  });
}
