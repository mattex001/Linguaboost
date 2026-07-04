import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Singleton [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Live Supabase auth state stream — emits the signed-in [User?] on every
/// auth change (including the initial session on subscription).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref
      .watch(authServiceProvider)
      .authStateChanges
      .map((state) => state.session?.user),
);

/// A [ChangeNotifier] that fires whenever the Supabase auth state changes.
/// Used as GoRouter's [refreshListenable] so routes re-evaluate on sign-in/out.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier(
    ref.watch(authServiceProvider).authStateChanges,
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});
