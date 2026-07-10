import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_boost/core/providers/user_provider.dart';
import 'package:lingua_boost/core/services/local_storage_service.dart';
import 'package:lingua_boost/features/phrasebook/models/phrase.dart';
import 'package:lingua_boost/features/phrasebook/providers/phrasebook_provider.dart';

Phrase _phrase(String id) => Phrase(
      id: id,
      userId: 'u1',
      sourceText: 'How much is this?',
      translatedText: '¿Cuánto cuesta esto?',
      targetLang: 'es',
      registerNote: 'Neutral — fine anywhere.',
      category: PhraseCategory.shoppingMoney,
      confidence: 'high',
      vocabBreakdown: const [VocabEntry(term: 'cuesta', meaning: 'costs')],
      grammarNote: 'Question inversion.',
      phonetic: 'KWAN-toh KWES-tah',
      ipa: 'ˈkwanto ˈkwesta',
      review: ReviewState(
        easeFactor: 2.6,
        intervalDays: 6,
        repetitions: 2,
        nextReviewAt: DateTime.utc(2026, 7, 10),
        lastResult: 'easy',
        lastReviewedAt: DateTime.utc(2026, 7, 4, 9, 30),
      ),
      createdAt: DateTime.utc(2026, 7, 1, 12),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
  });

  test('Phrase.toJson round-trips through Phrase.fromJson', () {
    final original = _phrase('p1');
    final revived = Phrase.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonEncode(original.toJson()))),
    );

    expect(revived.id, original.id);
    expect(revived.translatedText, original.translatedText);
    expect(revived.registerNote, original.registerNote);
    expect(revived.category, original.category);
    expect(revived.vocabBreakdown.single.term, 'cuesta');
    expect(revived.grammarNote, original.grammarNote);
    expect(revived.phonetic, original.phonetic);
    expect(revived.ipa, original.ipa);
    expect(revived.review.easeFactor, original.review.easeFactor);
    expect(revived.review.intervalDays, original.review.intervalDays);
    expect(revived.review.repetitions, original.review.repetitions);
    expect(
      revived.review.nextReviewAt.toUtc(),
      original.review.nextReviewAt.toUtc(),
    );
    expect(revived.review.lastResult, 'easy');
    expect(revived.isPendingOffline, isFalse);
  });

  test(
      'phrasesSnapshotProvider serves the disk cache when the stream has '
      'nothing (offline start)', () async {
    // Pre-populate the cache as if a previous online session wrote it.
    await LocalStorageService.instance.setCachedPhrasesJson(
      'u1',
      jsonEncode([_phrase('p1').toJson(), _phrase('p2').toJson()]),
    );

    final container = ProviderContainer(overrides: [
      authUserIdProvider.overrideWithValue('u1'),
      // Stream that never delivers — models the realtime subscription
      // hanging with no connectivity.
      phrasesStreamProvider.overrideWith(
        (ref) => const Stream<List<Phrase>>.empty(broadcast: true),
      ),
    ]);
    addTearDown(container.dispose);

    final snapshot = container.read(phrasesSnapshotProvider);
    expect(snapshot.length, 2);
    expect(snapshot.first.translatedText, '¿Cuánto cuesta esto?');
  });

  test('cache scoped per user — another uid sees nothing', () async {
    await LocalStorageService.instance.setCachedPhrasesJson(
      'u1',
      jsonEncode([_phrase('p1').toJson()]),
    );

    final container = ProviderContainer(overrides: [
      authUserIdProvider.overrideWithValue('someone-else'),
      phrasesStreamProvider.overrideWith(
        (ref) => const Stream<List<Phrase>>.empty(broadcast: true),
      ),
    ]);
    addTearDown(container.dispose);

    expect(container.read(phrasesSnapshotProvider), isEmpty);
  });
}
