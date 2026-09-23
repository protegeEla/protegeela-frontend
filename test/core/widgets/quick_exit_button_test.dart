import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protegeela/core/widgets/quick_exit_button.dart';
import 'package:protegeela/features/onboarding/presentation/neutral_page.dart';

void main() {
  testWidgets('quick exit replaces sensitive content with neutral page',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/sensitive',
      routes: [
        GoRoute(
          path: '/sensitive',
          builder: (_, __) => const Scaffold(
            body: Column(
              children: [
                QuickExitButton(),
                Text('Conteúdo sensível'),
              ],
            ),
          ),
        ),
        GoRoute(path: '/neutral', builder: (_, __) => const NeutralPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byKey(const ValueKey('quick-exit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Conteúdo sensível'), findsNothing);
    expect(find.text('Página inicial'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/neutral');
  });
}
