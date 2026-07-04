import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../shared/models/user_model.dart';

// ── Week activity ─────────────────────────────────────────────────────────────

final weekActivityProvider = Provider<List<bool>>((ref) {
  final user = ref.watch(userSnapshotProvider);
  return _computeWeekActivity(user);
});

List<bool> _computeWeekActivity(UserModel? user) {
  final today = DateTime.now();
  // Days back to most recent Saturday (Sat=6 in Dart weekday)
  final daysBackToSat = (today.weekday - 6 + 7) % 7;
  final saturdayOfWeek = today.subtract(Duration(days: daysBackToSat));

  final activeDates = user?.activeDates ?? [];

  return List.generate(7, (i) {
    final day = saturdayOfWeek.add(Duration(days: i));
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    if (dayOnly.isAfter(todayOnly)) return false;
    // If activeDates is populated, use it for accurate tracking
    if (activeDates.isNotEmpty) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return activeDates.contains(key);
    }
    // Fallback: infer from streak + lastActiveDate
    final lastActive = user?.lastActiveDate;
    final streak = user?.streak ?? 0;
    if (lastActive == null || streak == 0) return false;
    final lastActiveOnly =
        DateTime(lastActive.year, lastActive.month, lastActive.day);
    final streakStart = lastActiveOnly.subtract(Duration(days: streak - 1));
    return !dayOnly.isBefore(streakStart) && !dayOnly.isAfter(lastActiveOnly);
  });
}

// ── Display name ──────────────────────────────────────────────────────────────

final displayNameProvider = Provider<String>((ref) {
  final user = ref.watch(userSnapshotProvider);
  if (user == null) return 'there';
  final name = user.name;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final prefix = (user.email ?? '').split('@').first;
  if (prefix.isEmpty) return 'there';
  return prefix[0].toUpperCase() + prefix.substring(1);
});

// ── Background theme ──────────────────────────────────────────────────────────

/// -1 = no theme (default). 0-4 = one of the 5 premium background images.
class BackgroundThemeNotifier extends Notifier<int> {
  @override
  int build() => -1;

  void select(int index) {
    assert(index >= -1 && index <= 4);
    state = index;
  }

  void clear() => state = -1;
}

final backgroundThemeProvider = NotifierProvider<BackgroundThemeNotifier, int>(
  BackgroundThemeNotifier.new,
);

// ── Active nav tab ─────────────────────────────────────────────────────────────

class ActiveNavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final activeNavTabProvider = NotifierProvider<ActiveNavTabNotifier, int>(
  ActiveNavTabNotifier.new,
);

// ── Daily progress ────────────────────────────────────────────────────────────

class DailyProgressState {
  final bool streakJustCompleted;

  const DailyProgressState({this.streakJustCompleted = false});

  DailyProgressState copyWith({bool? streakJustCompleted}) =>
      DailyProgressState(
        streakJustCompleted: streakJustCompleted ?? this.streakJustCompleted,
      );
}

class DailyProgressNotifier extends Notifier<DailyProgressState> {
  @override
  DailyProgressState build() => const DailyProgressState();

  /// Call after each learning action (successful translation or review
  /// rating). Records the streak once per day; the first action of the day
  /// triggers the streak-success modal.
  Future<void> recordLearningAction() async {
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid == null) return;

    final user = ref.read(userSnapshotProvider);
    final now = DateTime.now();
    final last = user?.lastActiveDate;
    final alreadyToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;

    await ref.read(userRepositoryProvider).recordStreakDay(uid);

    if (!alreadyToday && !state.streakJustCompleted) {
      state = state.copyWith(streakJustCompleted: true);
    }
  }

  /// Dismiss the streak success modal.
  void dismissStreakModal() =>
      state = state.copyWith(streakJustCompleted: false);
}

final dailyProgressProvider =
    NotifierProvider<DailyProgressNotifier, DailyProgressState>(
  DailyProgressNotifier.new,
);
