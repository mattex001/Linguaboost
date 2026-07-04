import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/providers/storage_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/user_provider.dart';
import 'shared/models/user_model.dart';
import 'core/router/app_router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── Supabase ───────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // ── Notifications ──────────────────────────────────────────────────────────
  await NotificationService.instance.initialize();

  // ── RevenueCat ─────────────────────────────────────────────────────────────
  // Replace API keys in purchase_service.dart with your RevenueCat dashboard keys.
  try {
    await PurchaseService.instance.configure();
  } catch (_) {
    // RC not yet configured — purchases will fail gracefully at runtime.
  }

  // ── Local storage ──────────────────────────────────────────────────────────
  final storage = await LocalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const LinguaBoostApp(),
    ),
  );
}

class LinguaBoostApp extends ConsumerWidget {
  const LinguaBoostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // When user data changes: reschedule the daily review reminder
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          NotificationService.instance.cancelAll();
          return;
        }
        NotificationService.instance.scheduleReviewReminder(user);
      });
    });

    // Resolve effective brightness so system nav-bar icons stay legible
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'LinguaBoost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
