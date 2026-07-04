class AppConstants {
  AppConstants._();

  // Onboarding
  static const int totalOnboardingSteps = 6;

  // Translation
  static const int maxTranslationInputChars = 500;
  static const int aiResponseTimeoutSeconds = 30;

  // Subscription
  static const double subscriptionPriceNaira = 1500;
  static const int trialDays = 3;

  // Learning goals (relocation-oriented, display-only)
  static const List<String> goals = [
    'Settling into a new country',
    'Travel',
    'Work & business',
    'Family & friends',
    'Others',
  ];

  // Cache keys
  static const String onboardingStepKey = 'onboarding_step';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'selected_theme';
}
