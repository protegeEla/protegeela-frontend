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
  bool _requestingPermission = false;
  bool _permissionGranted = false;
  String? _permissionMessage;

  Future<void> _requestLocationPermission() async {
    if (_requestingPermission) return;
    setState(() {
      _requestingPermission = true;
      _permissionMessage = null;
    });
    try {
      final permission = await Geolocator.requestPermission();
      if (!mounted) return;
      setState(() {
        _permissionGranted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        _permissionMessage = switch (permission) {
          LocationPermission.always ||
          LocationPermission.whileInUse =>
            'Permissão concedida. Você pode criar sua conta ou entrar.',
          LocationPermission.deniedForever =>
            'Localização bloqueada. Você pode liberar nas configurações do navegador ou continuar sem permitir.',
          LocationPermission.denied =>
            'Você pode continuar sem permitir localização e decidir novamente ao pedir ajuda.',
          _ =>
            'Não foi possível confirmar a permissão. Você pode continuar sem localização.',
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() => _permissionMessage =
            'Não foi possível solicitar a localização. Tente novamente ou continue sem permitir.');
      }
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/privacidade'),
        title: const Text('Localização'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.location_on_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text('Você decide quando permitir',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text(
                    'Você pode permitir localização agora ou somente ao pedir ajuda. Ausência de GPS nunca bloqueia a criação do alerta.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _requestingPermission || _permissionGranted
                        ? null
                        : _requestLocationPermission,
                    icon: _requestingPermission
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_permissionGranted
                            ? Icons.check_rounded
                            : Icons.location_on_outlined),
                    label: Text(_permissionGranted
                        ? 'Localização permitida'
                        : 'Permitir localização'),
                  ),
                  if (_permissionMessage != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(_permissionMessage!,
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 16),
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
      ),
    );
  }
}
