import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:protegeela/features/alerts_map/data/alerts_map_repository.dart';
import 'package:protegeela/features/alerts_map/presentation/alerts_map_page.dart';
import 'package:protegeela/features/support_points/data/support_points_repository.dart';
import 'package:protegeela/shared/models/support_point.dart';
import 'package:protegeela/app/theme.dart';

class _Alerts extends Mock implements AlertsMapRepository {}

// Deterministic local tiles: the polling test never accesses the network.
class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/config/img/logo.png');
}

void main() {
  for (final size in [const Size(1400, 900), const Size(390, 844)]) {
    testWidgets('unified map searches and selects support at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Alerts();
      when(() => repository.publicAlertsInBounds(
          south: any(named: 'south'),
          west: any(named: 'west'),
          north: any(named: 'north'),
          east: any(named: 'east'))).thenAnswer((_) async => []);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            alertsMapRepositoryProvider.overrideWithValue(repository),
            publicAlertMarkersProvider.overrideWith((ref) async => []),
            supportPointsProvider.overrideWith((ref) async => const [
                  SupportPoint(
                      id: 'a',
                      name: 'Acolhimento de teste',
                      category: 'support_center',
                      address: 'Rua de teste',
                      city: 'Manaus',
                      state: 'AM',
                      latitude: -3.12,
                      longitude: -60.02,
                      isVerified: false),
                  SupportPoint(
                      id: 'b',
                      name: 'Unidade de saúde',
                      category: 'health',
                      address: 'Rua de teste',
                      city: 'Manaus',
                      state: 'AM',
                      latitude: -3.13,
                      longitude: -60.03,
                      isVerified: false),
                ]),
          ],
          child: MaterialApp(
              theme: buildProtegeElaTheme(),
              home: AlertsMapPage(tileProvider: _Tiles()))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('2 pontos de apoio'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'acolhimento');
      await tester.pump();
      expect(find.text('1 ponto de apoio'), findsOneWidget);
      if (size.width < 980) {
        await tester.tap(find.text('Ver lista'));
        await tester.pump();
      }
      await tester.tap(find.text('Acolhimento de teste'));
      await tester.pump();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.mapController!.camera.center.latitude, closeTo(-3.12, 0.001));
      expect(map.mapController!.camera.zoom, 15);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets(
      'queries viewport, avoids overlapping requests and pauses in background',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Alerts();
    final pending = Completer<List<PublicAlertMarker>>();
    var calls = 0;
    final bounds = <double>[];
    when(() => repository.publicAlertsInBounds(
          south: any(named: 'south'),
          west: any(named: 'west'),
          north: any(named: 'north'),
          east: any(named: 'east'),
        )).thenAnswer((invocation) {
      calls++;
      bounds.addAll([
        invocation.namedArguments[#south] as double,
        invocation.namedArguments[#west] as double,
        invocation.namedArguments[#north] as double,
        invocation.namedArguments[#east] as double,
      ]);
      return pending.future;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        alertsMapRepositoryProvider.overrideWithValue(repository),
        publicAlertMarkersProvider.overrideWith((ref) async => []),
        supportPointsProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp(home: AlertsMapPage(tileProvider: _Tiles())),
    ));
    await tester.pump();
    expect(calls, 1);
    expect(bounds[2] - bounds[0], lessThan(10));
    expect(bounds[3] - bounds[1], lessThan(10));

    await tester.pump(const Duration(seconds: 16));
    expect(calls, 1,
        reason: 'Do not start another fetch while the first is pending');
    pending.complete([]);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 24));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });
}
