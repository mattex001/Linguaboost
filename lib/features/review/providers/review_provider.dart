import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/dashboard_provider.dart';
import '../../phrasebook/models/phrase.dart';
import '../../phrasebook/providers/phrasebook_provider.dart';
import '../domain/sm2.dart';

/// Real-time count of phrases due for review (FR-3.2) — derived from the
/// same stream that powers the phrasebook list, scoped to the active
/// practicing language so a review session never mixes languages.
final dueCountProvider = Provider<int>((ref) {
  return ref
      .watch(phrasesForActiveLanguageProvider)
      .where((phrase) => phrase.isDue)
      .length;
});

// ── Review session ────────────────────────────────────────────────────────────

class ReviewSessionState {
  final List<Phrase> queue;
  final int index;
  final bool revealed;
  final int completed;
  final bool active;
  final bool finished;

  const ReviewSessionState({
    this.queue = const [],
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
    int? index,
    bool? revealed,
    int? completed,
    bool? active,
    bool? finished,
  }) =>
      ReviewSessionState(
        queue: queue ?? this.queue,
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
    final due = ref
        .read(phrasesForActiveLanguageProvider)
        .where((phrase) => phrase.isDue)
        .toList();
    state = ReviewSessionState(queue: due, active: due.isNotEmpty);
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
