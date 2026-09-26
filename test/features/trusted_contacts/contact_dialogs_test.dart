import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/app/theme.dart';
import 'package:protegeela/features/trusted_contacts/presentation/contact_dialogs.dart';
import 'package:protegeela/shared/models/trusted_contact.dart';

const _contact = TrustedContact(
  id: 'contact-id',
  ownerUserId: 'owner-id',
  name: 'Maria',
  phone: '(92) 99999-9999',
  email: 'maria@example.com',
  relationship: 'amiga',
  invitationStatus: 'accepted',
  canViewExactLocation: true,
  isPrimary: false,
);

Widget _host(VoidCallback onPressed) {
  return MaterialApp(
    theme: buildProtegeElaTheme(),
    home: Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: onPressed,
          child: const Text('Abrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('edit dialog returns validated contact data', (tester) async {
    ContactFormValue? result;
    await tester.pumpWidget(
      _host(() async {
        result = await showContactFormDialog(
          tester.element(find.text('Abrir')),
          contact: _contact,
        );
      }),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Editar contato'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Maria Silva');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Maria Silva');
    expect(result?.relationship, 'amiga');
  });

  testWidgets('access dialog returns the selected permission', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _host(() async {
        result = await showContactAccessDialog(
          tester.element(find.text('Abrir')),
          contact: _contact,
        );
      }),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Salvar permissão'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('remove dialog requires explicit confirmation', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _host(() async {
        result = await showRemoveContactDialog(
          tester.element(find.text('Abrir')),
          contact: _contact,
        );
      }),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Remover contato?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
