import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_user.dart';
import 'api_client.dart';

final apiSessionChangesProvider = StreamProvider<void>((ref) {
  return ref.watch(apiClientProvider).sessionChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  ref.watch(apiSessionChangesProvider);
  final api = ref.watch(apiClientProvider);
  if (!api.isAuthenticated) return null;
  return AppUser(id: api.userId!, email: api.email);
});
