import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/auth_providers.dart';
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
    final userId = ref.watch(currentUserProvider.select((user) => user?.id));
    final demoActive = await ref.watch(demoSessionProvider.future);
    if (demoActive) return const EmergencyState();
    if (userId == null) return const EmergencyState();
    final alert = await ref.watch(emergencyRepositoryProvider).activeAlert();
    return EmergencyState(activeAlert: alert);
  }

  Future<void> createAlert(
      {String alertType = 'immediate_danger',
      bool isSilent = false,
      bool publicVisibility = false}) async {
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
        publicVisibility: publicVisibility && !isSilent,
        publicLatitude: publicLatitude,
        publicLongitude: publicLongitude,
      );
      state = AsyncData(
        EmergencyState(
          activeAlert: alert,
          lastMessage:
              'Alerta temporário criado apenas neste navegador. Nenhum contato real foi avisado.',
        ),
      );
      return;
    }

    final userId = ref.read(currentUserProvider)?.id;
    final pendingStore = ref.read(pendingAlertStoreProvider);
    LocationCapture? location;
    var locationStatus = 'location_unavailable';
    try {
      location = await ref.read(locationServiceProvider).captureCurrent();
      locationStatus = 'captured';
    } on AppException catch (error) {
      locationStatus = error.code ?? 'location_unavailable';
    } catch (_) {
      locationStatus = 'location_unavailable';
    }

    if (userId == null || ref.read(currentUserProvider)?.id != userId) return;

    try {
      final alert = await ref.read(emergencyRepositoryProvider).createAlert(
            clientRequestId: requestId,
            alertType: alertType,
            isSilent: isSilent,
            publicVisibility: publicVisibility,
            location: location,
            locationStatus: locationStatus,
          );
      if (ref.read(currentUserProvider)?.id != userId) return;
      await pendingStore.clear();
      bool notified = false;
      try {
        notified = await ref
            .read(notificationCenterRepositoryProvider)
            .wasAlertNotificationSent(alert.id);
      } catch (_) {}
      if (ref.read(currentUserProvider)?.id != userId) return;
      state = AsyncData(EmergencyState(
          activeAlert: alert,
          lastMessage: notified
              ? 'Alerta confirmado pelo servidor.'
              : 'Alerta salvo. Nenhuma notificação externa foi enviada.'));
    } catch (error) {
      if (ref.read(currentUserProvider)?.id != userId) return;
      if (error is AppException && error.code?.startsWith('http_4') == true) {
        state = const AsyncData(EmergencyState());
        if (error.code == 'http_409') {
          final active =
              await ref.read(emergencyRepositoryProvider).activeAlert();
          if (ref.read(currentUserProvider)?.id != userId) return;
          state = AsyncData(EmergencyState(activeAlert: active));
          if (active != null) {
            await pendingStore.clear();
            return;
          }
        }
        rethrow;
      }
      await pendingStore.save(
        PendingAlert(
          clientRequestId: requestId,
          alertType: alertType,
          isSilent: isSilent,
          publicVisibility: publicVisibility,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      state = AsyncData(
        EmergencyState(
          isSending: false,
          clientRequestId: requestId,
          lastMessage:
              'Sem confirmação do servidor. Tente sincronizar assim que a conexão voltar.',
          lastAttemptAt: DateTime.now(),
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
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final pendingStore = ref.read(pendingAlertStoreProvider);
    final pending = await pendingStore.read();
    if (pending == null) return;
    if (ref.read(currentUserProvider)?.id != userId) return;
    final alert = await ref.read(emergencyRepositoryProvider).createAlert(
          clientRequestId: pending.clientRequestId,
          alertType: pending.alertType,
          isSilent: pending.isSilent,
          publicVisibility: pending.publicVisibility,
          location: null,
          locationStatus: 'pending_sync',
        );
    await pendingStore.clear();
    if (ref.read(currentUserProvider)?.id != userId) return;
    state = AsyncData(EmergencyState(
        activeAlert: alert.isActive ? alert : null,
        lastMessage:
            'Alerta sincronizado. Nenhuma notificação externa foi enviada.',
        lastAttemptAt: DateTime.now()));
  }
}
