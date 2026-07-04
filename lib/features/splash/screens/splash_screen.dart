import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final storage = LocalStorageService.instance;

    if (session != null) {
      // Active session — skip auth entirely
      if (storage.onboardingComplete) {
        context.go(AppRoutes.dashboard);
      } else {
        // Signed in but personalization not finished — resume it
        context.go(AppRoutes.personalization);
      }
    } else {
      // No active session — show onboarding / auth
      context.go(AppRoutes.onboarding);
    }
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
