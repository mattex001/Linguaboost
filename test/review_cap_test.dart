import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:lingua_boost/core/providers/auth_provider.dart';
import 'package:lingua_boost/core/providers/user_provider.dart';
import 'package:lingua_boost/core/services/tts_service.dart';
import 'package:lingua_boost/features/phrasebook/models/phrase.dart';
import 'package:lingua_boost/features/phrasebook/providers/phrasebook_provider.dart';
import 'package:lingua_boost/features/phrasebook/repositories/phrase_repository.dart';
import 'package:lingua_boost/features/review/domain/sm2.dart';
import 'package:lingua_boost/features/review/providers/review_provider.dart';
import 'package:lingua_boost/shared/models/user_model.dart';
import 'package:lingua_boost/shared/repositories/user_repository.dart';

// `implements` + noSuchMethod (rather than `extends`) so the fakes never
// touch Supabase.instance via the real constructors.
class _FakePhraseRepository implements PhraseRepository {
  final reviewedIds = <String>[];

  @override
  Future<void> updateReview({
    required String phraseId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime nextReviewAt,
    required String lastResult,
  }) async {
    reviewedIds.add(phraseId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakePronunciationPlayer implements PronunciationPlayer {
  @override
  Future<void> speak(String text, String langCode) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> prefetch(String text, String langCode) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeUserRepository implements UserRepository {
  int increments = 0;

  @override
  Future<void> incrementReviewsCompletedToday(String uid) async {
    increments++;
  }

  // Session finish records a streak day — irrelevant here, just absorb it.
  @override
  Future<void> recordStreakDay(String uid) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Phrase _phrase(String id, {required DateTime nextReviewAt}) => Phrase(
      id: id,
      userId: 'u1',
      sourceText: 'src $id',
      translatedText: 'dst $id',
      targetLang: 'fr',
      category: PhraseCategory.greetingsSmalltalk,
      review: ReviewState(nextReviewAt: nextReviewAt),
      createdAt: DateTime.now(),
    );

final _authUser = User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);

ProviderContainer _container({
  required UserModel user,
  required List<Phrase> phrases,
  required _FakePhraseRepository phraseRepo,
  required _FakeUserRepository userRepo,
}) {
  final container = ProviderContainer(overrides: [
    userSnapshotProvider.overrideWithValue(user),
    phrasesForActiveLanguageProvider.overrideWithValue(phrases),
    phraseRepositoryProvider.overrideWithValue(phraseRepo),
    userRepositoryProvider.overrideWithValue(userRepo),
    authStateProvider.overrideWithValue(AsyncValue.data(_authUser)),
    pronunciationPlayerProvider.overrideWithValue(_FakePronunciationPlayer()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  group('reviewsRemainingTodayProvider', () {
    test('full limit available when nothing reviewed today', () {
      final c = _container(
        user: const UserModel(id: 'u1', dailyReviewLimit: 5),
        phrases: List.generate(
            8, (i) => _phrase('$i', nextReviewAt: yesterday)),
        phraseRepo: _FakePhraseRepository(),
        userRepo: _FakeUserRepository(),
      );
      expect(c.read(reviewsRemainingTodayProvider), 5);
    });

    test('bounded by actual backlog when due < limit', () {
      final c = _container(
        user: const UserModel(id: 'u1', dailyReviewLimit: 5),
        phrases: [_phrase('a', nextReviewAt: yesterday)],
        phraseRepo: _FakePhraseRepository(),
        userRepo: _FakeUserRepository(),
      );
      expect(c.read(reviewsRemainingTodayProvider), 1);
    });

    test("today's completed count reduces remaining, floored at 0", () {
      final today = DateTime.now();
      final c = _container(
        user: UserModel(
          id: 'u1',
          dailyReviewLimit: 3,
          reviewsCompletedToday: 3,
          reviewsCompletedDate: DateTime(today.year, today.month, today.day),
        ),
        phrases:
            List.generate(6, (i) => _phrase('$i', nextReviewAt: yesterday)),
        phraseRepo: _FakePhraseRepository(),
        userRepo: _FakeUserRepository(),
      );
      expect(c.read(reviewsRemainingTodayProvider), 0);
    });

    test("yesterday's counter is ignored — new day resets for free", () {
      final c = _container(
        user: UserModel(
          id: 'u1',
          dailyReviewLimit: 4,
          reviewsCompletedToday: 4,
          reviewsCompletedDate: yesterday,
        ),
        phrases:
            List.generate(6, (i) => _phrase('$i', nextReviewAt: yesterday)),
        phraseRepo: _FakePhraseRepository(),
        userRepo: _FakeUserRepository(),
      );
      expect(c.read(reviewsRemainingTodayProvider), 4);
    });
  });

  group('capped review session', () {
    test('start() serves only the remaining count, most overdue first', () {
      final c = _container(
        user: const UserModel(id: 'u1', dailyReviewLimit: 2),
        phrases: [
          _phrase('newest', nextReviewAt: yesterday),
          _phrase('oldest',
              nextReviewAt: DateTime.now().subtract(const Duration(days: 9))),
          _phrase('middle',
              nextReviewAt: DateTime.now().subtract(const Duration(days: 4))),
        ],
        phraseRepo: _FakePhraseRepository(),
        userRepo: _FakeUserRepository(),
      );

      c.read(reviewSessionProvider.notifier).start();
      final session = c.read(reviewSessionProvider);

      expect(session.queue.length, 2);
      expect(session.originalQueueLength, 2);
      expect(session.queue.map((p) => p.id), ['oldest', 'middle']);
      expect(session.active, isTrue);
    });

    test('rating an original slot counts toward the cap; "Again" retries are free',
        () async {
      final userRepo = _FakeUserRepository();
      final c = _container(
        user: const UserModel(id: 'u1', dailyReviewLimit: 2),
        phrases: [
          _phrase('a', nextReviewAt: yesterday),
          _phrase('b', nextReviewAt: yesterday),
        ],
        phraseRepo: _FakePhraseRepository(),
        userRepo: userRepo,
      );

      final notifier = c.read(reviewSessionProvider.notifier);
      notifier.start();

      // Card 1: wrong — counts (original slot) and re-queues itself.
      await notifier.rate(ReviewRating.again);
      expect(userRepo.increments, 1);
      expect(c.read(reviewSessionProvider).queue.length, 3);

      // Card 2: correct — counts (original slot).
      await notifier.rate(ReviewRating.easy);
      expect(userRepo.increments, 2);

      // Card 3 is the re-queued retry of card 1 — must NOT count.
      await notifier.rate(ReviewRating.easy);
      expect(userRepo.increments, 2);
      expect(c.read(reviewSessionProvider).finished, isTrue);
    });
  });
}
