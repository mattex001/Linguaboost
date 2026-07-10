import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../../shared/models/user_model.dart';
import '../../shared/repositories/user_repository.dart';
import '../services/local_storage_service.dart';
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
/// Every value that arrives is cached to disk (see [userSnapshotProvider])
/// so a dropped connection doesn't make the UI fall back to a guest state.
final currentUserProvider = StreamProvider<UserModel?>(
  (ref) {
    final uid = ref.watch(authUserIdProvider);
    if (uid == null) return Stream.value(null);
    return ref.watch(userRepositoryProvider).watchUser(uid).map((user) {
      if (user != null) {
        LocalStorageService.instance.setCachedProfileJson(
          jsonEncode(user.toJson()),
        );
      }
      return user;
    });
  },
);

/// Synchronous snapshot of the current user. Prefers the live stream value
/// — including its last-known value while reconnecting or erroring, via
/// [AsyncValue.value] (which in Riverpod 3 keeps previous data through
/// loading/error states) rather than [AsyncValue.asData] — and only
/// falls back to the on-disk cache when the stream has never delivered
/// anything at all (e.g. app launched with no connectivity).
final userSnapshotProvider = Provider<UserModel?>((ref) {
  final live = ref.watch(currentUserProvider).value;
  if (live != null) return live;

  final cached = LocalStorageService.instance.cachedProfileJson;
  if (cached == null) return null;
  try {
    return UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

/// The user's current active practicing language code (e.g. 'es'). Null
/// before onboarding sets one. Phrasebook, Review, and the Home/Profile
/// stats all scope to this — switching it anywhere (Translate, Phrasebook,
/// Review all share one switcher) changes what the whole app considers
/// "current" everywhere at once.
final activeLanguageCodeProvider = Provider<String?>((ref) {
  return ref.watch(userSnapshotProvider)?.targetLanguage;
});
