import 'dart:io';

/// Netlify build configuration contains public origins only, never credentials.
Uri validateEndpoint(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !RegExp(r'^https://[a-zA-Z0-9.\-\[\]:]+/api/?$').hasMatch(value) ||
      const {
        'localhost',
        '127.0.0.1',
        '::1',
        '[::1]',
      }.contains(uri.host.toLowerCase())) {
    throw ArgumentError(
      'API_BASE_URL deve ser uma URL publica HTTPS terminada em /api.',
    );
  }
  return uri;
}

String securityPolicy(Uri api) {
  final websocket = api.origin.replaceFirst('https:', 'wss:');
  return "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; "
      "style-src 'self' 'unsafe-inline'; "
      "img-src 'self' data: blob: https://tile.openstreetmap.org; "
      "connect-src 'self' ${api.origin} $websocket https://tile.openstreetmap.org; "
      "font-src 'self' data:; worker-src 'self' blob:; manifest-src 'self'; "
      "frame-ancestors 'none'; base-uri 'self'; form-action 'self'";
}

// Only known application paths are rewritten. Missing JS, assets and /api
// remain 404 instead of returning index.html with a misleading HTTP 200.
String routeRewrites(String routerSource) {
  final paths =
      RegExp(r"path: '([^']+)'")
          .allMatches(routerSource)
          .map((match) => match.group(1)!)
          .where((path) => path != '/')
          .toSet()
          .toList()
        ..sort();
  return '${paths.map((path) => '$path /index.html 200').join('\n')}\n';
}

void main(List<String> args) {
  final api = validateEndpoint(Platform.environment['API_BASE_URL'] ?? '');
  if (args.contains('--validate-only')) return;
  final output = Directory('build/web');
  if (!output.existsSync()) {
    throw StateError('Execute flutter build web antes de configurar o host.');
  }
  File('${output.path}/_headers').writeAsStringSync(
    '/*\n  Content-Security-Policy: ${securityPolicy(api)}\n'
    '/index.html\n  Cache-Control: no-cache\n'
    '/flutter_bootstrap.js\n  Cache-Control: no-cache\n'
    '/flutter_service_worker.js\n  Cache-Control: no-cache\n',
  );
  File('${output.path}/_redirects').writeAsStringSync(
    routeRewrites(File('lib/app/router.dart').readAsStringSync()),
  );
}
