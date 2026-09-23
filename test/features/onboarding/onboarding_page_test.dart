import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protegeela/features/onboarding/presentation/onboarding_page.dart';

void main() {
  testWidgets('starts onboarding directly at the login page', (tester) async {
    final router = GoRouter(
      initialLocation: '/apresentacao',
      routes: [
        GoRoute(
          path: '/apresentacao',
          builder: (_, __) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Tela de login')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Começar agora'), findsOneWidget);
    expect(find.text('Já tenho conta'), findsNothing);

    await tester.ensureVisible(find.text('Começar agora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();

    expect(find.text('Tela de login'), findsOneWidget);
  });
}
