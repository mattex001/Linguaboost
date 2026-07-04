// Pure-Dart SM-2 spaced-repetition scheduling (FR-3.1). No imports — unit
// tested in test/sm2_test.dart.

enum ReviewRating { again, hard, easy }

class Sm2State {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;

  const Sm2State({
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
  });
}

class Sm2Result {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;

  const Sm2Result({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
  });
}

/// Applies one SM-2 rating. Ratings map to SM-2 quality scores:
/// again → 1, hard → 3, easy → 5.
///
/// - quality < 3 resets repetitions and makes the card due again today
///   (it re-enters the current session's queue).
/// - Otherwise intervals grow 1 → 6 → round(previous × EF).
/// - EF' = EF + (0.1 − (5−q)(0.08 + (5−q)·0.02)), floored at 1.3.
Sm2Result applySm2(Sm2State state, ReviewRating rating, {DateTime? now}) {
  final quality = switch (rating) {
    ReviewRating.again => 1,
    ReviewRating.hard => 3,
    ReviewRating.easy => 5,
  };

  var easeFactor = state.easeFactor +
      (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (easeFactor < 1.3) easeFactor = 1.3;

  int repetitions;
  int intervalDays;
  if (quality < 3) {
    repetitions = 0;
    intervalDays = 0;
  } else {
    repetitions = state.repetitions + 1;
    intervalDays = switch (repetitions) {
      1 => 1,
      2 => 6,
      _ => (state.intervalDays * easeFactor).round(),
    };
  }

  final current = now ?? DateTime.now();
  final startOfToday = DateTime(current.year, current.month, current.day);

  return Sm2Result(
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
    nextReviewAt: startOfToday.add(Duration(days: intervalDays)),
  );
}
