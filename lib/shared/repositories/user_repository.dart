import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  UserRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseQueryBuilder get _profiles => _client.from('profiles');

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final row = await _profiles.select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return UserModel.fromJson(row);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _profiles.stream(primaryKey: ['id']).eq('id', uid).map(
          (rows) => rows.isEmpty ? null : UserModel.fromJson(rows.first),
        );
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _profiles.update(data).eq('id', uid);

  Future<void> setOnboardingStep(String uid, int step) =>
      updateUser(uid, {'onboarding_step': step});

  Future<void> completeOnboarding(String uid) =>
      updateUser(uid, {'onboarding_step': AppConstants.totalOnboardingSteps});

  Future<void> updateName(String uid, String name) =>
      updateUser(uid, {'name': name});

  Future<void> updateTargetLanguage(String uid, String code) =>
      updateUser(uid, {'target_language': code});

  Future<void> updateLearningGoal(String uid, String goal) =>
      updateUser(uid, {'learning_goal': goal});

  // ── Streak ─────────────────────────────────────────────────────────────────

  /// Increments streak by 1 only if it hasn't been recorded today yet.
  /// Also appends today's date (YYYY-MM-DD) to active_dates.
  Future<void> recordStreakDay(String uid) async {
    final user = await getUser(uid);
    if (user == null) return;

    final today = DateTime.now();
    final todayKey = _todayKey();
    final activeDates = user.activeDates.contains(todayKey)
        ? user.activeDates
        : [...user.activeDates, todayKey];

    final last = user.lastActiveDate;
    final alreadyToday = last != null &&
        last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;

    if (alreadyToday) {
      await updateUser(uid, {'active_dates': activeDates});
      return;
    }

    await updateUser(uid, {
      'streak_count': user.streak + 1,
      'last_active_date': todayKey,
      'active_dates': activeDates,
    });
  }

  /// Adds today's date to active_dates without incrementing streak.
  Future<void> recordActivityDay(String uid) async {
    final user = await getUser(uid);
    if (user == null) return;
    final todayKey = _todayKey();
    if (user.activeDates.contains(todayKey)) return;
    await updateUser(uid, {
      'active_dates': [...user.activeDates, todayKey],
    });
  }

  // ── Subscription ───────────────────────────────────────────────────────────

  Future<void> activateTrial(String uid) => updateUser(uid, {
        'is_premium': true,
        'trial_start_date': DateTime.now().toUtc().toIso8601String(),
      });

  Future<void> activatePremium(String uid) =>
      updateUser(uid, {'is_premium': true});

  Future<void> revokePremium(String uid) =>
      updateUser(uid, {'is_premium': false});

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
