import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protegeela/core/services/api_client.dart';
import 'package:protegeela/core/services/location_service.dart';
import 'package:protegeela/features/check_in/data/safety_check_in_repository.dart';
import 'package:protegeela/features/check_in/presentation/check_in_location_tracker.dart';
import 'package:protegeela/shared/models/safety_check_in.dart';

import '../core/api_client_test.dart' show login;

class DelayedLocation extends LocationService {
  final capture = Completer<LocationCapture>();
  @override
  Future<LocationCapture> captureCurrent() => capture.future;
}

class TrackingRepository extends SafetyCheckInRepository {
  TrackingRepository(super.api);
  int updates = 0;
  @override
  Future<void> updateLocation(LocationCapture location) async => updates++;
}

void main() {
  testWidgets(
    'GPS captured before account change is never uploaded afterwards',
    (tester) async {
      final api = ApiClient('https://api.example.invalid/api');
      addTearDown(api.dispose);
      await login(api);
      final location = DelayedLocation();
      final repository = TrackingRepository(api);
      final now = DateTime.now();
      final checkIn = SafetyCheckIn(
        id: 'test-check-in',
        expectedAt: now.add(const Duration(minutes: 5)),
        expiresAt: now.add(const Duration(minutes: 10)),
        graceMinutes: 5,
        status: 'active',
        createdAt: now,
        shareLocation: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(api),
            locationServiceProvider.overrideWithValue(location),
            safetyCheckInRepositoryProvider.overrideWithValue(repository),
            currentSafetyCheckInProvider.overrideWith((ref) async => checkIn),
          ],
          child: const MaterialApp(
            home: CheckInLocationTracker(child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await login(api, id: 'other-test-user');
      await tester.pump();
      location.capture.complete(
        LocationCapture(
          latitude: 0,
          longitude: 0,
          accuracy: 10,
          capturedAt: now,
          source: 'test',
        ),
      );
      await tester.pump();
      expect(repository.updates, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
