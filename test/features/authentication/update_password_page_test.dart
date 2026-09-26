import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/features/authentication/presentation/update_password_page.dart';

void main() {
  testWidgets('shows the complete new password form', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UpdatePasswordPage()),
      ),
    );

    expect(find.text('Crie uma nova senha'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Salvar nova senha'), findsOneWidget);
    expect(find.text('Solicitar outro link'), findsOneWidget);
  });

  testWidgets('validates password confirmation before submitting',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UpdatePasswordPage()),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'senha-segura-123',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'senha-diferente',
    );
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pump();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
  });
}
