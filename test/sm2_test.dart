import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_boost/features/review/domain/sm2.dart';

void main() {
  final now = DateTime(2026, 7, 4, 15, 30);
  final startOfToday = DateTime(2026, 7, 4);

  group('applySm2', () {
    test('first easy rating schedules 1 day out', () {
      final result = applySm2(const Sm2State(), ReviewRating.easy, now: now);
      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.nextReviewAt, startOfToday.add(const Duration(days: 1)));
      expect(result.easeFactor, closeTo(2.6, 0.001));
    });

    test('second successful rating schedules 6 days out', () {
      const afterFirst =
          Sm2State(easeFactor: 2.6, intervalDays: 1, repetitions: 1);
      final result = applySm2(afterFirst, ReviewRating.easy, now: now);
      expect(result.repetitions, 2);
      expect(result.intervalDays, 6);
      expect(result.nextReviewAt, startOfToday.add(const Duration(days: 6)));
    });

    test('third successful rating scales by ease factor', () {
      const afterSecond =
          Sm2State(easeFactor: 2.7, intervalDays: 6, repetitions: 2);
      final result = applySm2(afterSecond, ReviewRating.easy, now: now);
      expect(result.repetitions, 3);
      // 6 × EF' where EF' = 2.7 + 0.1 = 2.8 → round(16.8) = 17
      expect(result.intervalDays, 17);
    });

    test('again resets repetitions and is due today', () {
      const mature =
          Sm2State(easeFactor: 2.5, intervalDays: 17, repetitions: 3);
      final result = applySm2(mature, ReviewRating.again, now: now);
      expect(result.repetitions, 0);
      expect(result.intervalDays, 0);
      expect(result.nextReviewAt, startOfToday);
      // quality 1 → EF drops by 0.54
      expect(result.easeFactor, closeTo(1.96, 0.001));
    });

    test('hard still advances but reduces ease factor', () {
      const state =
          Sm2State(easeFactor: 2.5, intervalDays: 6, repetitions: 2);
      final result = applySm2(state, ReviewRating.hard, now: now);
      expect(result.repetitions, 3);
      // quality 3 → EF drops by 0.14
      expect(result.easeFactor, closeTo(2.36, 0.001));
      expect(result.intervalDays, (6 * 2.36).round());
    });

    test('ease factor never drops below 1.3', () {
      const struggling =
          Sm2State(easeFactor: 1.3, intervalDays: 1, repetitions: 1);
      final result = applySm2(struggling, ReviewRating.again, now: now);
      expect(result.easeFactor, 1.3);
    });
  });
}
