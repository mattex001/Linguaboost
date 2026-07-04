import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import '../../shared/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Singleton [UserRepository] instance.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

/// Watches the `profiles` row for the currently signed-in user.
/// Returns null when no user is signed in or the row doesn't exist yet.
final currentUserProvider = StreamProvider<UserModel?>(
  (ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const Stream.empty();
        return ref.watch(userRepositoryProvider).watchUser(user.id);
      },
      loading: () => const Stream.empty(),
      error: (_, _) => const Stream.empty(),
    );
  },
);

/// Simple synchronous snapshot of the current user (may be null while loading).
final userSnapshotProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider).asData?.value;
});
