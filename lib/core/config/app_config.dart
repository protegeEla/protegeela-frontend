import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.appEnvironment,
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.defaultZoom,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appEnvironment;
  final double defaultLatitude;
  final double defaultLongitude;
  final double defaultZoom;

  bool get isDemoMode =>
      supabaseUrl.contains('your-project-ref') ||
      supabaseAnonKey.startsWith('your-public');

  factory AppConfig.fromEnvironment() {
    String read(String key, String fallback) {
      const env = String.fromEnvironment('APP_ENV');
      final value = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
      if (key == 'APP_ENV' && env.isNotEmpty) return env;
      return value == null || value.isEmpty ? fallback : value;
    }

    double readDouble(String key, double fallback) {
      final value = read(key, fallback.toString());
      return double.tryParse(value) ?? fallback;
    }

    const supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

    return AppConfig(
      supabaseUrl: supabaseUrlDefine.isNotEmpty
          ? supabaseUrlDefine
          : read('SUPABASE_URL', 'https://your-project-ref.supabase.co'),
      supabaseAnonKey: supabaseAnonDefine.isNotEmpty
          ? supabaseAnonDefine
          : read('SUPABASE_ANON_KEY', 'your-public-anon-key'),
      appEnvironment: read('APP_ENV', 'development'),
      defaultLatitude: readDouble('APP_DEFAULT_LATITUDE', -3.1190),
      defaultLongitude: readDouble('APP_DEFAULT_LONGITUDE', -60.0217),
      defaultZoom: readDouble('APP_DEFAULT_ZOOM', 12),
    );
  }
}
