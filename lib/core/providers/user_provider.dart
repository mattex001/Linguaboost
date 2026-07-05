import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../shared/models/user_model.dart';
import '../../shared/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Singleton [UserRepository] instance.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

/// The signed-in user's id. Uses `select` so downstream providers rebuild
/// only when the id actually changes — NOT on every auth event (token
/// refreshes etc.), which would tear down and re-create live streams.
final authUserIdProvider = Provider<String?>((ref) {
  final id = ref.watch(
    authStateProvider.select((state) => state.asData?.value?.id),
  );
  // Before the first auth event arrives the stream is still loading; fall
  // back to the synchronously-available session so startup doesn't flash a
  // signed-out frame.
  return id ?? Supabase.instance.client.auth.currentSession?.user.id;
});

/// Watches the `profiles` row for the currently signed-in user.
/// Returns null when no user is signed in or the row doesn't exist yet.
final currentUserProvider = StreamProvider<UserModel?>(
  (ref) {
    final uid = ref.watch(authUserIdProvider);
    if (uid == null) return Stream.value(null);
    return ref.watch(userRepositoryProvider).watchUser(uid);
  },
);

/// Simple synchronous snapshot of the current user (may be null while loading).
final userSnapshotProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider).asData?.value;
});
