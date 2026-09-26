import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/core/config/app_config.dart';

void main() {
  test('uses demo defaults when dotenv was not loaded', () {
    expect(dotenv.isInitialized, isFalse);

    final config = AppConfig.fromEnvironment();

    expect(config.isDemoMode, isTrue);
    expect(config.appEnvironment, 'development');
    expect(config.defaultLatitude, -3.1190);
    expect(config.defaultLongitude, -60.0217);
    expect(config.defaultZoom, 12);
  });
}
