import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

/// Provides the already-initialised [LocalStorageService] singleton.
/// Overridden in main() after init() completes.
final localStorageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService.instance,
);
