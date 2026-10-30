import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/app/app.dart';
import 'package:protegeela/app/router.dart';
import 'package:protegeela/core/services/api_client.dart';
import 'package:protegeela/features/authentication/presentation/login_page.dart';
import 'package:protegeela/features/onboarding/presentation/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(390, 844),
    const Size(1440, 900),
    const Size(1366, 768),
  ]) {
    testWidgets('startup, protected routing and registration at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient('https://api.example.invalid/api');
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ProtegeElaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPage), findsOneWidget);
      final router = container.read(routerProvider);
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/login');
      router.go('/cadastro');
      await tester.pumpAndSettle();
      expect(find.text('Nome completo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/recuperar-senha');
      await tester.pumpAndSettle();
      expect(find.text('Funcionalidade indisponível'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
