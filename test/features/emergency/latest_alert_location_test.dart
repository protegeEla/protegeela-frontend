import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:protegeela/core/services/supabase_providers.dart';
import 'package:protegeela/features/authentication/data/demo_session_repository.dart';
import 'package:protegeela/features/emergency/data/emergency_repository.dart';

class _Repository extends Mock implements EmergencyRepository {}

void main() {
  test('location is reused until explicitly refreshed', () async {
    final repository = _Repository();
    when(() => repository.latestLocation('alert'))
        .thenAnswer((_) async => null);
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(null),
      demoSessionProvider.overrideWith((ref) async => false),
      emergencyRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(
      latestAlertLocationProvider('alert'),
      (_, __) {},
    );
    addTearDown(subscription.close);

    await container.read(latestAlertLocationProvider('alert').future);
    await container.read(latestAlertLocationProvider('alert').future);
    verify(() => repository.latestLocation('alert')).called(1);

    container.invalidate(latestAlertLocationProvider('alert'));
    await container.read(latestAlertLocationProvider('alert').future);
    verify(() => repository.latestLocation('alert')).called(1);
  });

  test('demo does not query the backend for a fictional alert', () async {
    final repository = _Repository();
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(null),
      demoSessionProvider.overrideWith((ref) async => true),
      emergencyRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    expect(
        await container.read(latestAlertLocationProvider('demo-alert').future),
        isNull);
    verifyNever(() => repository.latestLocation(any()));
  });
}
