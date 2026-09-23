import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim(), 'phone': phone.trim()},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth
        .signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> resetPassword(String email) async {
    final redirectTo = kIsWeb
        ? Uri.base.replace(fragment: '/atualizar-senha').toString()
        : null;
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String password) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('Link de recuperação inválido ou expirado.');
    }
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();
}
