import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:protegeela/core/services/supabase_providers.dart';
import 'package:protegeela/features/authentication/data/demo_session_repository.dart';
import 'package:protegeela/features/profile/data/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Profiles extends Mock implements ProfileRepository {}

User _user(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-09-21T00:00:00Z',
    );

void main() {
  test('refreshing the same user does not refetch; switching users does',
      () async {
    final identity = StateProvider<User?>((ref) => _user('first'));
    final profiles = _Profiles();
    when(profiles.currentProfile).thenAnswer((_) async => null);
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWith((ref) => ref.watch(identity)),
      demoSessionProvider.overrideWith((ref) async => false),
      profileRepositoryProvider.overrideWithValue(profiles),
    ]);
    addTearDown(container.dispose);

    await container.read(currentProfileProvider.future);
    verify(profiles.currentProfile).called(1);
    container.read(identity.notifier).state = _user('first');
    await container.read(currentProfileProvider.future);
    verifyNever(profiles.currentProfile);

    container.read(identity.notifier).state = _user('second');
    await container.read(currentProfileProvider.future);
    verify(profiles.currentProfile).called(1);
  });
}
