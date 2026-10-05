import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_providers.dart';

final pendingAlertStoreProvider = Provider<PendingAlertStore>(
    (ref) => PendingAlertStore(ref.watch(currentUserProvider)?.id));

class PendingAlertStore {
  static const maxAge = Duration(hours: 24);

  PendingAlertStore(String? userId)
      : _key = 'protegeela.pending_alert.${userId ?? 'anonymous'}';
  final String _key;

  Future<void> save(PendingAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(alert.toJson()));
  }

  Future<PendingAlert?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(_key);
        return null;
      }
      final alert = PendingAlert.fromJson(decoded);
      final now = DateTime.now().toUtc();
      final createdAt = alert.createdAt.toUtc();
      if (createdAt.isAfter(now) || now.difference(createdAt) >= maxAge) {
        await prefs.remove(_key);
        return null;
      }
      return alert;
    } on FormatException {
      await prefs.remove(_key);
      return null;
    } on TypeError {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class PendingAlert {
  const PendingAlert({
    required this.clientRequestId,
    required this.alertType,
    required this.isSilent,
    required this.createdAt,
    this.publicVisibility = false,
  });

  final String clientRequestId;
  final String alertType;
  final bool isSilent;
  final DateTime createdAt;
  final bool publicVisibility;

  Map<String, dynamic> toJson() => {
        'client_request_id': clientRequestId,
        'alert_type': alertType,
        'is_silent': isSilent,
        'public_visibility': publicVisibility,
        'created_at': createdAt.toIso8601String(),
      };

  factory PendingAlert.fromJson(Map<String, dynamic> json) => PendingAlert(
        clientRequestId: json['client_request_id'] as String,
        alertType: json['alert_type'] as String,
        isSilent: json['is_silent'] as bool? ?? false,
        publicVisibility: json['public_visibility'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
