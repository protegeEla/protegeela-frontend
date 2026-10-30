import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/safety_check_in.dart';
import '../data/safety_check_in_repository.dart';

enum CheckInTrackingStatus { idle, updating, active, unavailable }

final checkInTrackingStatusProvider =
    StateProvider<CheckInTrackingStatus>((ref) => CheckInTrackingStatus.idle);

class CheckInLocationTracker extends ConsumerStatefulWidget {
  const CheckInLocationTracker({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CheckInLocationTracker> createState() =>
      _CheckInLocationTrackerState();
}

class _CheckInLocationTrackerState extends ConsumerState<CheckInLocationTracker>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sessionSubscription;
  Timer? _timer;
  SafetyCheckIn? _tracked;
  bool _capturing = false;
  bool _foreground = true;
  late bool _authenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final api = ref.read(apiClientProvider);
    _authenticated = api.isAuthenticated;
    _sessionSubscription = api.sessionChanges.listen((_) {
      if (!mounted) return;
      setState(() => _authenticated = api.isAuthenticated);
      ref.invalidate(currentSafetyCheckInProvider);
      if (!api.isAuthenticated) _configure(null);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _restartTimer();
      _capture();
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      final current = ref.watch(currentSafetyCheckInProvider);
      if (current.hasValue) {
        final next = current.valueOrNull;
        if (_needsConfiguration(next)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _configure(next));
        }
      }
    }
    return widget.child;
  }

  bool _needsConfiguration(SafetyCheckIn? next) =>
      _tracked?.id != next?.id ||
      _tracked?.shareLocation != next?.shareLocation;

  void _configure(SafetyCheckIn? checkIn) {
    if (!mounted) return;
    _timer?.cancel();
    _tracked = checkIn;
    if (checkIn == null ||
        !checkIn.shareLocation ||
        DateTime.now().isAfter(checkIn.expiresAt.toLocal())) {
      ref.read(checkInTrackingStatusProvider.notifier).state =
          CheckInTrackingStatus.idle;
      return;
    }
    _restartTimer();
    _capture();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_foreground || _tracked == null || !_tracked!.shareLocation) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _capture());
  }

  Future<void> _capture() async {
    final checkIn = _tracked;
    if (!_foreground || _capturing || checkIn == null) return;
    if (DateTime.now().isAfter(checkIn.expiresAt.toLocal())) {
      _configure(null);
      ref.invalidate(currentSafetyCheckInProvider);
      return;
    }
    _capturing = true;
    ref.read(checkInTrackingStatusProvider.notifier).state =
        CheckInTrackingStatus.updating;
    try {
      final location = await ref.read(locationServiceProvider).captureCurrent();
      await ref.read(safetyCheckInRepositoryProvider).updateLocation(location);
      if (!mounted || _tracked?.id != checkIn.id) return;
      ref.read(checkInTrackingStatusProvider.notifier).state =
          CheckInTrackingStatus.active;
      ref.invalidate(currentSafetyCheckInProvider);
    } catch (_) {
      if (mounted && _tracked?.id == checkIn.id) {
        ref.read(checkInTrackingStatusProvider.notifier).state =
            CheckInTrackingStatus.unavailable;
      }
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
