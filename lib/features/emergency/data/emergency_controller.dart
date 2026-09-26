import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/emergency_alert.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../../notifications/data/notification_center_repository.dart';
import '../domain/emergency_state.dart';
import 'emergency_repository.dart';
import 'pending_alert_store.dart';

final emergencyControllerProvider =
    AsyncNotifierProvider<EmergencyController, EmergencyState>(
  EmergencyController.new,
);

class EmergencyController extends AsyncNotifier<EmergencyState> {
  static const _uuid = Uuid();

  @override
  Future<EmergencyState> build() async {
    final demoActive = await ref.watch(demoSessionProvider.future);
    if (demoActive) return const EmergencyState();
    final alert = await ref.watch(emergencyRepositoryProvider).activeAlert();
    return EmergencyState(activeAlert: alert);
  }

  Future<void> createAlert(
      {String alertType = 'immediate_danger', bool isSilent = false}) async {
    final current = state.valueOrNull;
    if (current?.isSending == true || current?.activeAlert?.isActive == true) {
      return;
    }

    final requestId = _uuid.v4();
    state =
        AsyncData(EmergencyState(isSending: true, clientRequestId: requestId));

    final demoActive = await ref.read(demoSessionProvider.future);
    if (demoActive) {
      double publicLatitude = -3.119;
      double publicLongitude = -60.022;
      try {
        final location =
            await ref.read(locationServiceProvider).captureCurrent();
        publicLatitude = location.latitude;
        publicLongitude = location.longitude;
      } catch (_) {
        // Mantém a posição padrão da demonstração quando a
        // geolocalização não está disponível.
      }

      final alert = EmergencyAlert(
        id: 'demo-alert-$requestId',
        userId: 'demo-user',
        alertType: alertType,
        status: 'active',
        isSilent: isSilent,
        locationStatus: 'captured',
        startedAt: DateTime.now().toUtc(),
        publicVisibility: true,
        publicLatitude: publicLatitude,
        publicLongitude: publicLongitude,
      );
      await ref.read(notificationServiceProvider).notifyAlertCreated(alert.id);
      state = AsyncData(
        EmergencyState(
          activeAlert: alert,
          lastMessage:
              'Alerta temporário criado apenas neste navegador. Nenhum contato real foi avisado.',
        ),
      );
      return;
    }

    LocationCapture? location;
    var locationStatus = 'location_unavailable';
    try {
      location = await ref.read(locationServiceProvider).captureCurrent();
      locationStatus = 'captured';
    } on AppException catch (error) {
      locationStatus = error.code ?? 'location_unavailable';
    }

    try {
      final alert = await ref.read(emergencyRepositoryProvider).createAlert(
            clientRequestId: requestId,
            alertType: alertType,
            isSilent: isSilent,
            location: location,
            locationStatus: locationStatus,
          );
      await ref.read(notificationServiceProvider).notifyAlertCreated(alert.id);
      try {
        await ref
            .read(notificationCenterRepositoryProvider)
            .markAlertNotificationsSent(alert.id);
      } catch (_) {
        await ref
            .read(notificationServiceProvider)
            .notifyAlertCreated('notification_fallback:${alert.id}');
      }
      state = AsyncData(EmergencyState(
          activeAlert: alert, lastMessage: 'Alerta confirmado pelo servidor.'));
    } catch (_) {
      await ref.read(pendingAlertStoreProvider).save(
            PendingAlert(
              clientRequestId: requestId,
              alertType: alertType,
              isSilent: isSilent,
              createdAt: DateTime.now().toUtc(),
            ),
          );
      state = AsyncData(
        EmergencyState(
          isSending: false,
          clientRequestId: requestId,
          lastMessage:
              'Sem confirmação do servidor. Tente sincronizar assim que a conexão voltar.',
        ),
      );
      rethrow;
    }
  }

  Future<void> closeAlert({required String reason, String? pin}) async {
    final alert = state.valueOrNull?.activeAlert;
    if (alert == null) return;
    final demoActive = await ref.read(demoSessionProvider.future);
    if (demoActive) {
      state = const AsyncData(
        EmergencyState(lastMessage: 'Alerta temporário encerrado.'),
      );
      return;
    }
    await ref
        .read(emergencyRepositoryProvider)
        .closeAlert(alertId: alert.id, reason: reason, pin: pin);
    state = const AsyncData(EmergencyState(lastMessage: 'Alerta encerrado.'));
  }

  Future<void> syncPendingAlert() async {
    final pending = await ref.read(pendingAlertStoreProvider).read();
    if (pending == null) return;
    final alert = await ref.read(emergencyRepositoryProvider).createAlert(
          clientRequestId: pending.clientRequestId,
          alertType: pending.alertType,
          isSilent: pending.isSilent,
          location: null,
          locationStatus: 'pending_sync',
        );
    await ref.read(pendingAlertStoreProvider).clear();
    await ref.read(notificationServiceProvider).notifyAlertCreated(alert.id);
    state = AsyncData(EmergencyState(
        activeAlert: alert, lastMessage: 'Alerta pendente sincronizado.'));
  }
}
