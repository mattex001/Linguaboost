import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../providers/auth_provider.dart';
import '../services/local_storage_service.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/personalization/screens/personalization_intro_screen.dart';
import '../../features/personalization/screens/name_screen.dart';
import '../../features/personalization/screens/target_language_screen.dart';
import '../../features/personalization/screens/voice_selection_screen.dart';
import '../../features/personalization/screens/what_is_your_goal_screen.dart';
import '../../features/personalization/screens/just_a_minute_screen.dart';
import '../../features/personalization/screens/notification_motivation_screen.dart';
import '../../features/personalization/screens/allow_notifications_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/new_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/home_themes_screen.dart';
import '../../features/notifications/screens/notification_prompt_screen.dart';
import '../../features/paywall/screens/paywall_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/profile_edit_screens.dart';
import '../../features/profile/screens/profile_static_screens.dart';
import '../../features/splash/screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String paywall = '/paywall';
  static const String dashboard = '/dashboard';
  static const String homeThemes = '/home-themes';
  static const String notificationPrompt = '/notification-prompt';
  static const String profile = '/profile';

  // Personalization flow
  static const String personalization = '/personalization';
  static const String personalizationName = '/personalization/name';
  static const String personalizationLanguage = '/personalization/language';
  static const String personalizationVoice = '/personalization/voice';
  static const String personalizationGoal = '/personalization/goal';
  static const String personalizationJustAMinute = '/personalization/just-a-minute';
  static const String personalizationNotifications = '/personalization/notifications';
  static const String personalizationMotivation = '/personalization/motivation';

  // Profile edit routes
  static const String profileEditLanguage = '/profile/edit/language';
  static const String profileEditGoal = '/profile/edit/goal';
  static const String profileEditName = '/profile/edit/name';
  static const String profileEditVoice = '/profile/edit/voice';
  static const String profileEditReviewLimit = '/profile/edit/review-limit';
  static const String profileNotifications = '/profile/notifications';
  static const String profileHelpFaq = '/profile/help';
  static const String profilePrivacyPolicy = '/profile/privacy';
  static const String profileTermsOfService = '/profile/terms';

  // Auth flow
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authOtp = '/auth/otp';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetOtp = '/auth/reset-otp';
  static const String authNewPassword = '/auth/new-password';
}

/// Riverpod provider that vends the [GoRouter] instance.
/// The router re-evaluates its redirect whenever the Supabase auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final signedIn =
          Supabase.instance.client.auth.currentSession != null;
      final path = state.matchedLocation;

      // These paths are always reachable regardless of auth state
      final isPublic = path == AppRoutes.splash ||
          path == AppRoutes.onboarding ||
          path.startsWith('/auth');

      // Kick unauthenticated users away from protected pages
      if (!signedIn && !isPublic) return AppRoutes.onboarding;

      // Signed-in users don't need onboarding/auth screens — except mid
      // password-reset, which legitimately runs on a recovery session while
      // still under /auth/*.
      final isPasswordResetStep = path == AppRoutes.authNewPassword;
      if (signedIn &&
          isPublic &&
          path != AppRoutes.splash &&
          !isPasswordResetStep) {
        final complete = LocalStorageService.instance.onboardingComplete;
        return complete ? AppRoutes.dashboard : AppRoutes.personalization;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.homeThemes,
        builder: (context, state) => const HomeThemesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationPrompt,
        builder: (context, state) => const NotificationPromptScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Personalization flow ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.personalization,
        builder: (context, state) => const PersonalizationIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationName,
        builder: (context, state) => const NameScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationLanguage,
        builder: (context, state) => const TargetLanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationVoice,
        builder: (context, state) => VoiceSelectionScreen(
          targetLanguageCode: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.personalizationGoal,
        builder: (context, state) => const WhatIsYourGoalScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationJustAMinute,
        builder: (context, state) => const JustAMinuteScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationNotifications,
        builder: (context, state) => const AllowNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalizationMotivation,
        builder: (context, state) => const NotificationMotivationScreen(),
      ),

      // ── Profile edit routes ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileEditLanguage,
        builder: (context, state) => const EditTargetLanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditGoal,
        builder: (context, state) => const EditLearningGoalScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditName,
        builder: (context, state) => const EditNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditVoice,
        builder: (context, state) => const EditVoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditReviewLimit,
        builder: (context, state) => const EditDailyReviewLimitScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications,
        builder: (context, state) => const ProfileNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileHelpFaq,
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilePrivacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileTermsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      // ── Auth flow ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.authLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.authSignup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.authOtp,
        builder: (context, state) {
          final email = (state.extra as String?) ?? '';
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.authForgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.authResetOtp,
        builder: (context, state) {
          final email = (state.extra as String?) ?? '';
          return OtpScreen(email: email, purpose: OtpPurpose.passwordReset);
        },
      ),
      GoRoute(
        path: AppRoutes.authNewPassword,
        builder: (context, state) {
          final email = (state.extra as String?) ?? '';
          return NewPasswordScreen(email: email);
        },
      ),
    ],
  );

  return router;
});
