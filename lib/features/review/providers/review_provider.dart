import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../phrasebook/models/phrase.dart';
import '../../phrasebook/providers/phrasebook_provider.dart';
import '../domain/sm2.dart';

/// Real-time count of phrases due for review (FR-3.2) — derived from the
/// same stream that powers the phrasebook list, scoped to the active
/// practicing language so a review session never mixes languages.
///
/// This is the *uncapped* backlog size. What the user sees as "due today"
/// is [reviewsRemainingTodayProvider], which applies their daily limit.
final dueCountProvider = Provider<int>((ref) {
  return ref
      .watch(phrasesForActiveLanguageProvider)
      .where((phrase) => phrase.isDue)
      .length;
});

/// How many phrases the user still gets served today: their daily limit
/// (2-10, chosen in Profile) minus what they've already reviewed today,
/// bounded by the actual backlog. A counter stamped with a previous day
/// counts as zero — same date-comparison reset the streak system uses, so
/// no explicit "reset at midnight" write is ever needed.
final reviewsRemainingTodayProvider = Provider<int>((ref) {
  final user = ref.watch(userSnapshotProvider);
  if (user == null) return 0;

  final today = DateTime.now();
  final date = user.reviewsCompletedDate;
  final isToday = date != null &&
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  final completed = isToday ? user.reviewsCompletedToday : 0;
  final remaining = user.dailyReviewLimit - completed;
  final due = ref.watch(dueCountProvider);
  return remaining < 0 ? 0 : (remaining < due ? remaining : due);
});

// ── Review session ────────────────────────────────────────────────────────────

class ReviewSessionState {
  final List<Phrase> queue;

  /// Queue length as sliced at [ReviewSessionNotifier.start] — entries below
  /// this index count toward the daily cap; entries at or beyond it are
  /// re-queued "Again" retries, which are free.
  final int originalQueueLength;
  final int index;
  final bool revealed;
  final int completed;
  final bool active;
  final bool finished;

  const ReviewSessionState({
    this.queue = const [],
    this.originalQueueLength = 0,
    this.index = 0,
    this.revealed = false,
    this.completed = 0,
    this.active = false,
    this.finished = false,
  });

  Phrase? get current =>
      active && index < queue.length ? queue[index] : null;

  int get remaining => queue.length - index;

  ReviewSessionState copyWith({
    List<Phrase>? queue,
    int? originalQueueLength,
    int? index,
    bool? revealed,
    int? completed,
    bool? active,
    bool? finished,
  }) =>
      ReviewSessionState(
        queue: queue ?? this.queue,
        originalQueueLength: originalQueueLength ?? this.originalQueueLength,
        index: index ?? this.index,
        revealed: revealed ?? this.revealed,
        completed: completed ?? this.completed,
        active: active ?? this.active,
        finished: finished ?? this.finished,
      );
}

/// Drives a review session (FR-3.3..3.6). Each rating is written to the
/// phrase row immediately, so quitting mid-session loses nothing — re-entering
/// rebuilds the queue from the remaining due phrases.
class ReviewSessionNotifier extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() => const ReviewSessionState();

  void start() {
    // Most-overdue first, sliced to what's left of today's daily limit —
    // anything beyond the cap simply stays due and surfaces tomorrow.
    final due = ref
        .read(phrasesForActiveLanguageProvider)
        .where((phrase) => phrase.isDue)
        .toList()
      ..sort((a, b) => a.review.nextReviewAt.compareTo(b.review.nextReviewAt));
    final queue = due.take(ref.read(reviewsRemainingTodayProvider)).toList();
    state = ReviewSessionState(
      queue: queue,
      originalQueueLength: queue.length,
      active: queue.isNotEmpty,
    );

    // Warm the whole session's pronunciation audio in the background so
    // every card's play button responds instantly. Sequential on purpose —
    // one in-flight synthesis at a time, no burst on the edge function.
    final player = ref.read(pronunciationPlayerProvider);
    Future(() async {
      for (final phrase in queue) {
        await player.prefetch(phrase.translatedText, phrase.targetLang);
      }
    });
  }

  void reveal() => state = state.copyWith(revealed: true);

  Future<void> rate(ReviewRating rating) async {
    final phrase = state.current;
    if (phrase == null) return;

    final result = applySm2(
      Sm2State(
        easeFactor: phrase.review.easeFactor,
        intervalDays: phrase.review.intervalDays,
        repetitions: phrase.review.repetitions,
      ),
      rating,
    );

    // Persist immediately — this is what makes sessions exit-safe (FR-3.6).
    await ref.read(phraseRepositoryProvider).updateReview(
          phraseId: phrase.id,
          easeFactor: result.easeFactor,
          intervalDays: result.intervalDays,
          repetitions: result.repetitions,
          nextReviewAt: result.nextReviewAt,
          lastResult: rating.name,
        );

    // Only original slots consume the daily budget — indices past
    // originalQueueLength are re-queued "Again" retries, which are free.
    if (state.index < state.originalQueueLength) {
      final uid = ref.read(authStateProvider).asData?.value?.id;
      if (uid != null) {
        await ref
            .read(userRepositoryProvider)
            .incrementReviewsCompletedToday(uid);
      }
    }

    // "Again" cards re-enter the back of the in-session queue.
    final queue = List<Phrase>.from(state.queue);
    if (rating == ReviewRating.again) {
      queue.add(phrase);
    }

    final nextIndex = state.index + 1;
    if (nextIndex >= queue.length) {
      state = state.copyWith(
        queue: queue,
        index: nextIndex,
        revealed: false,
        completed: state.completed + 1,
        active: false,
        finished: true,
      );
      // Streak: finishing today's reviews counts as a learning action.
      await ref.read(dailyProgressProvider.notifier).recordLearningAction();
    } else {
      state = state.copyWith(
        queue: queue,
        index: nextIndex,
        revealed: false,
        completed: state.completed + 1,
      );
    }
  }

  /// Exit without losing progress — rated cards are already persisted.
  void exit() => state = const ReviewSessionState();
}

final reviewSessionProvider =
    NotifierProvider<ReviewSessionNotifier, ReviewSessionState>(
  ReviewSessionNotifier.new,
);
