import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a network path (Wi-Fi, cellular, …).
///
/// Note: connectivity ≠ reachability — a captive portal can report online —
/// but it's the right signal for choosing the offline translation fallback
/// and for sweeping pending phrases once a connection comes back.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  await for (final results in connectivity.onConnectivityChanged) {
    yield _hasNetwork(results);
  }
});

bool _hasNetwork(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);
