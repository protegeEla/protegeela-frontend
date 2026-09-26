import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_back_button.dart';

class FirstContactPage extends StatelessWidget {
  const FirstContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Primeiro contato'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Voce pode cadastrar um contato agora ou fazer isso depois pela rede de apoio. Convites dependem de consentimento.'),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: () => context.go('/contatos'),
                    child: const Text('Cadastrar contato')),
                TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Fazer depois')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
