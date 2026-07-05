import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Minimum display time so the logo doesn't flash
    final minDelay = Future.delayed(const Duration(milliseconds: 1800));

    final session = Supabase.instance.client.auth.currentSession;
    final storage = LocalStorageService.instance;

    if (session == null) {
      await minDelay;
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
      return;
    }

    // Onboarding completion comes from the server profile (a chosen target
    // language), not just the device flag — SharedPreferences survive app
    // upgrades and could otherwise skip onboarding for fresh accounts.
    bool complete = storage.onboardingComplete;
    try {
      final profile =
          await ref.read(userRepositoryProvider).getUser(session.user.id);
      if (profile != null) {
        complete = profile.targetLanguage != null;
        if (complete) {
          await storage.setOnboardingComplete();
        } else {
          await storage.clearOnboardingComplete();
        }
      }
    } catch (_) {
      // Offline — fall back to the device flag.
    }

    await minDelay;
    if (!mounted) return;
    context.go(complete ? AppRoutes.dashboard : AppRoutes.personalization);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundInverseLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/LinguaBoost_logo.svg',
              height: 48,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0, duration: 600.ms),

            const SizedBox(height: 12),

            Text(
              'Learn the language your life actually needs',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

            const SizedBox(height: 48),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandPrimary,
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
