import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:protegeela/app/theme.dart';
import 'package:protegeela/features/emergency/presentation/widgets/active_alert_overview.dart';
import 'package:protegeela/shared/models/emergency_alert.dart';

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/config/img/logo.png');
}

void main() {
  for (final size in [const Size(1440, 900), const Size(390, 844)]) {
    testWidgets('active alert fits width and exposes actions at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var safe = false;
      await tester.pumpWidget(MaterialApp(
          theme: buildProtegeElaTheme(),
          home: Scaffold(
            body: ActiveAlertOverview(
              alert: EmergencyAlert(
                  id: 'demo-alert-1',
                  userId: 'demo',
                  alertType: 'immediate_danger',
                  status: 'active',
                  isSilent: false,
                  locationStatus: 'unavailable',
                  startedAt: DateTime(2026, 9, 21, 15, 30),
                  publicVisibility: true),
              location: null,
              center: const LatLng(-3.119, -60.022),
              demo: true,
              busy: false,
              locationLoading: false,
              locationError: false,
              onCall: () {},
              onUpdate: () {},
              onSafe: () => safe = true,
              onClose: () {},
              onSupport: () {},
              tileProvider: _Tiles(),
            ),
          )));
      await tester.pump();
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('15:30'), findsOneWidget);
      expect(find.text('Nenhum envio real'), findsOneWidget);
      expect(find.byType(MarkerLayer), findsNothing,
          reason: 'Unknown location must not be displayed as a real position');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Estou em local seguro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estou em local seguro'));
      expect(safe, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
