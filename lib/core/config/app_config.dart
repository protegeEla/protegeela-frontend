import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'http://localhost:8080/api',
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.defaultZoom,
  });

  final String apiBaseUrl;

  final double defaultLatitude;
  final double defaultLongitude;
  final double defaultZoom;

  factory AppConfig.fromEnvironment() {
    const apiDefine = String.fromEnvironment('API_BASE_URL');
    final apiUrl =
        apiDefine.isNotEmpty ? apiDefine : 'http://localhost:8080/api';
    if (apiUrl.isNotEmpty) {
      final uri = Uri.tryParse(apiUrl);
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          uri.userInfo.isNotEmpty) {
        throw ArgumentError(
            'API_BASE_URL deve ser uma URL HTTP(S) sem credenciais, query ou fragmento.');
      }
      final loopback = const {'localhost', '127.0.0.1', '::1', '[::1]'}
          .contains(uri.host.toLowerCase());
      if (uri.scheme != 'https' && !loopback) {
        throw ArgumentError(
            'API_BASE_URL deve usar HTTPS fora do computador local.');
      }
    }
    return AppConfig(
      apiBaseUrl: apiUrl,
      defaultLatitude: double.tryParse(
              const String.fromEnvironment('APP_DEFAULT_LATITUDE')) ??
          -3.1190,
      defaultLongitude: double.tryParse(
              const String.fromEnvironment('APP_DEFAULT_LONGITUDE')) ??
          -60.0217,
      defaultZoom:
          double.tryParse(const String.fromEnvironment('APP_DEFAULT_ZOOM')) ??
              12,
    );
  }
}
