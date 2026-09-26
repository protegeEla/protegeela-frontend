import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/features/emergency/presentation/emergency_button.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets('releasing early cancels, reduced motion: $reducedMotion',
        (tester) async {
      var sent = false;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(body:
            EmergencyButton(onConfirmed: ({required bool isSilent}) async {
          sent = true;
        })),
      )));
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('PEDIR AJUDA')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.byType(EmergencyConfirmationDialog), findsNothing);
      expect(sent, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'shows confirmation after holding for five seconds and allows cancellation',
      (tester) async {
    var sent = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyButton(
            onConfirmed: ({required bool isSilent}) async {
              sent = true;
            },
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('PEDIR AJUDA')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Continue segurando'), findsOneWidget);
    for (var elapsed = 100; elapsed < 5100; elapsed += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(find.textContaining('Enviar alerta'), findsWidgets);

    await gesture.up();
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(sent, isFalse);
  });
}
