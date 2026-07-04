/// Profile row from the Supabase `profiles` table (snake_case columns).
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? targetLanguage; // ISO code, null until onboarding completes
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

  const UserModel({
    required this.id,
    this.name,
    this.email,
    this.targetLanguage,
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      targetLanguage: json['target_language'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'target_language': targetLanguage,
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
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? targetLanguage,
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
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        targetLanguage: targetLanguage ?? this.targetLanguage,
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
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
