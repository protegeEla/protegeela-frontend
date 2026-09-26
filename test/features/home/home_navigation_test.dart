import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protegeela/features/emergency/data/emergency_controller.dart';
import 'package:protegeela/features/emergency/domain/emergency_state.dart';
import 'package:protegeela/features/home/presentation/home_page.dart';
import 'package:protegeela/features/profile/data/profile_repository.dart';
import 'package:protegeela/shared/models/app_profile.dart';

class _EmergencyController extends EmergencyController {
  @override
  Future<EmergencyState> build() async => const EmergencyState();
}

void main() {
  testWidgets('user avatar opens profile', (tester) async {
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomePage()),
      GoRoute(
        path: '/perfil',
        builder: (_, __) => const Scaffold(body: Text('Perfil aberto')),
      ),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => const AppProfile(
              id: 'test',
              fullName: 'Beatriz Teste',
              phone: '(00) 00000-0000',
              role: 'user',
              privacyMode: 'standard',
            )),
        emergencyControllerProvider.overrideWith(_EmergencyController.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Perfil aberto'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/perfil');
  });
}
