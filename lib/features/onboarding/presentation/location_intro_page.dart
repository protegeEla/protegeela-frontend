import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_back_button.dart';

class LocationIntroPage extends StatefulWidget {
  const LocationIntroPage({super.key});

  @override
  State<LocationIntroPage> createState() => _LocationIntroPageState();
}

class _LocationIntroPageState extends State<LocationIntroPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final permission = await Geolocator.requestPermission();
      if (mounted && permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Localizacao foi bloqueada. Voce pode liberar nas configuracoes do dispositivo.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/privacidade'),
        title: const Text('Localizacao'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.location_on_outlined, size: 56),
                const SizedBox(height: 16),
                Text('Permissao contextual',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Você pode permitir localização agora ou somente ao pedir ajuda. Ausência de GPS nunca bloqueia a criação do alerta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: () => context.go('/cadastro'),
                    child: const Text('Criar conta')),
                TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Entrar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
