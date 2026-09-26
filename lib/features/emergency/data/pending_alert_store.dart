import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pendingAlertStoreProvider =
    Provider<PendingAlertStore>((ref) => PendingAlertStore());

class PendingAlertStore {
  static const _key = 'protegeela.pending_alert';

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
      return PendingAlert.fromJson(decoded);
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
  });

  final String clientRequestId;
  final String alertType;
  final bool isSilent;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'client_request_id': clientRequestId,
        'alert_type': alertType,
        'is_silent': isSilent,
        'created_at': createdAt.toIso8601String(),
      };

  factory PendingAlert.fromJson(Map<String, dynamic> json) => PendingAlert(
        clientRequestId: json['client_request_id'] as String,
        alertType: json['alert_type'] as String,
        isSilent: json['is_silent'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
