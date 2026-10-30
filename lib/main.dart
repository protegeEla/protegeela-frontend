import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final api = ApiClient(
    config.apiBaseUrl,
    storage: const FlutterSecureStorage(),
  );
  await api.restoreSession();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        apiClientProvider.overrideWith((ref) {
          ref.onDispose(api.dispose);
          return api;
        }),
      ],
      child: const ProtegeElaApp(),
    ),
  );
}
