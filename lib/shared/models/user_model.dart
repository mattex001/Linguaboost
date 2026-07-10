/// Profile row from the Supabase `profiles` table (snake_case columns).
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? targetLanguage; // ISO code, null until onboarding completes
  final String sourceLanguage; // ISO code of the user's own spoken language
  final String? voiceName; // device TTS voice name, null = OS default
  final String? voiceLocale; // locale the voice was picked for, e.g. 'it-IT'
  final String learningGoal;
  final String notificationStartTime; // HH:mm
  final String notificationEndTime; // HH:mm
  final bool notificationsEnabled;
  final String selectedTheme; // theme_1 … theme_6
  final bool isPremium;
  final DateTime? trialStartDate;
  final int streak;
  final DateTime? lastActiveDate;
  final int onboardingStep;
  final List<String> activeDates; // YYYY-MM-DD keys
  final int dailyReviewLimit; // 2-10 phrases served per day
  final int reviewsCompletedToday;
  final DateTime? reviewsCompletedDate; // date the counter is valid for

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.targetLanguage,
    this.sourceLanguage = 'en',
    this.voiceName,
    this.voiceLocale,
    this.learningGoal = '',
    this.notificationStartTime = '08:00',
    this.notificationEndTime = '20:00',
    this.notificationsEnabled = false,
    this.selectedTheme = 'theme_1',
    this.isPremium = false,
    this.trialStartDate,
    this.streak = 0,
    this.lastActiveDate,
    this.onboardingStep = 0,
    this.activeDates = const [],
    this.dailyReviewLimit = 5,
    this.reviewsCompletedToday = 0,
    this.reviewsCompletedDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      targetLanguage: json['target_language'] as String?,
      sourceLanguage: (json['source_language'] as String?) ?? 'en',
      voiceName: json['voice_name'] as String?,
      voiceLocale: json['voice_locale'] as String?,
      learningGoal: (json['learning_goal'] as String?) ?? '',
      notificationStartTime:
          (json['notification_start'] as String?) ?? '08:00',
      notificationEndTime: (json['notification_end'] as String?) ?? '20:00',
      notificationsEnabled: (json['notifications_enabled'] as bool?) ?? false,
      selectedTheme: (json['selected_theme'] as String?) ?? 'theme_1',
      isPremium: (json['is_premium'] as bool?) ?? false,
      trialStartDate: _parseDate(json['trial_start_date']),
      streak: (json['streak_count'] as num?)?.toInt() ?? 0,
      lastActiveDate: _parseDate(json['last_active_date']),
      onboardingStep: (json['onboarding_step'] as num?)?.toInt() ?? 0,
      activeDates: (json['active_dates'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dailyReviewLimit: (json['daily_review_limit'] as num?)?.toInt() ?? 5,
      reviewsCompletedToday:
          (json['reviews_completed_today'] as num?)?.toInt() ?? 0,
      reviewsCompletedDate: _parseDate(json['reviews_completed_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'target_language': targetLanguage,
        'source_language': sourceLanguage,
        'voice_name': voiceName,
        'voice_locale': voiceLocale,
        'learning_goal': learningGoal,
        'notification_start': notificationStartTime,
        'notification_end': notificationEndTime,
        'notifications_enabled': notificationsEnabled,
        'selected_theme': selectedTheme,
        'is_premium': isPremium,
        'trial_start_date': trialStartDate?.toIso8601String(),
        'streak_count': streak,
        'last_active_date': lastActiveDate != null
            ? _dateKey(lastActiveDate!)
            : null,
        'onboarding_step': onboardingStep,
        'active_dates': activeDates,
        'daily_review_limit': dailyReviewLimit,
        'reviews_completed_today': reviewsCompletedToday,
        'reviews_completed_date': reviewsCompletedDate != null
            ? _dateKey(reviewsCompletedDate!)
            : null,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? targetLanguage,
    String? sourceLanguage,
    String? voiceName,
    String? voiceLocale,
    String? learningGoal,
    String? notificationStartTime,
    String? notificationEndTime,
    bool? notificationsEnabled,
    String? selectedTheme,
    bool? isPremium,
    DateTime? trialStartDate,
    int? streak,
    DateTime? lastActiveDate,
    int? onboardingStep,
    List<String>? activeDates,
    int? dailyReviewLimit,
    int? reviewsCompletedToday,
    DateTime? reviewsCompletedDate,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        targetLanguage: targetLanguage ?? this.targetLanguage,
        sourceLanguage: sourceLanguage ?? this.sourceLanguage,
        voiceName: voiceName ?? this.voiceName,
        voiceLocale: voiceLocale ?? this.voiceLocale,
        learningGoal: learningGoal ?? this.learningGoal,
        notificationStartTime:
            notificationStartTime ?? this.notificationStartTime,
        notificationEndTime: notificationEndTime ?? this.notificationEndTime,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        selectedTheme: selectedTheme ?? this.selectedTheme,
        isPremium: isPremium ?? this.isPremium,
        trialStartDate: trialStartDate ?? this.trialStartDate,
        streak: streak ?? this.streak,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        onboardingStep: onboardingStep ?? this.onboardingStep,
        activeDates: activeDates ?? this.activeDates,
        dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
        reviewsCompletedToday:
            reviewsCompletedToday ?? this.reviewsCompletedToday,
        reviewsCompletedDate: reviewsCompletedDate ?? this.reviewsCompletedDate,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
