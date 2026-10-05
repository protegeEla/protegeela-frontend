import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../shared/models/app_user.dart';
import '../../emergency/data/pending_alert_store.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
      ref.watch(apiClientProvider), ref.watch(pendingAlertStoreProvider));
});

class AuthRepository {
  const AuthRepository(this._api, this._pendingAlerts);

  final ApiClient _api;
  final PendingAlertStore _pendingAlerts;

  AppUser? get currentUser => _api.isAuthenticated
      ? AppUser(id: _api.userId!, email: _api.email)
      : null;

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _api
        .request('POST', '/auth/register', authenticated: false, body: {
      'name': name.trim(),
      'email': email.trim(),
      'phone': PhoneNumberFormatter.digitsOnly(phone),
      'password': password,
    });
    await _api.setSession(data, email, rememberMe: false);
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final data =
        await _api.request('POST', '/auth/login', authenticated: false, body: {
      'email': email.trim(),
      'password': password,
      'remember_me': rememberMe,
    });
    await _api.setSession(data, email, rememberMe: rememberMe);
  }

  Future<void> resetPassword(String email) async {
    throw const AppException(
        'Recuperação de senha ainda não está disponível na API Java.');
  }

  Future<void> updatePassword(String password) async {
    throw const AppException(
        'Recuperação de senha ainda não está disponível na API Java.');
  }

  Future<void> signOut() async {
    try {
      await _api.request('POST', '/auth/logout');
    } finally {
      await _api.clearSession();
      await _pendingAlerts.clear();
    }
  }
}
