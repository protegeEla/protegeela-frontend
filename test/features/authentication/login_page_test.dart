import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protegeela/features/authentication/presentation/login_page.dart';

void main() {
  testWidgets('shows the complete login and demo access options',
      (tester) async {
    tester.view.physicalSize = const Size(1536, 788);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.text('Entrar temporariamente'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('keeps the branded layout when switching to account creation',
      (tester) async {
    tester.view.physicalSize = const Size(1536, 788);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(
          path: '/cadastro',
          builder: (_, __) => const LoginPage(
            initialView: AuthenticationView.register,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua\nconta'), findsOneWidget);
    expect(find.text('Preencha seus dados para começar com segurança.'),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(find.text('Já tem uma conta? '), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
