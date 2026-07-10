import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_boost/features/translate/providers/translate_provider.dart';
import 'package:lingua_boost/features/translate/repositories/pending_translation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PendingTranslationStore', () {
    test('add → list → remove round-trip, scoped per user', () async {
      final store = PendingTranslationStore.instance;

      final entry = await store.add(
        'u1',
        sourceText: 'Where is the station?',
        sourceLang: 'en',
        targetLang: 'fr',
        plainTranslatedText: 'Où est la gare ?',
      );

      expect((await store.list('u1')).length, 1);
      expect((await store.list('u2')), isEmpty, reason: 'scoped per user');

      final loaded = (await store.list('u1')).single;
      expect(loaded.localId, entry.localId);
      expect(loaded.sourceText, 'Where is the station?');
      expect(loaded.plainTranslatedText, 'Où est la gare ?');
      expect(loaded.targetLang, 'fr');

      await store.remove('u1', entry.localId);
      expect(await store.list('u1'), isEmpty);
    });

    test('corrupt stored JSON degrades to an empty list, not a crash',
        () async {
      SharedPreferences.setMockInitialValues(
          {'pending_translations_u1': 'not-json{{'});
      expect(await PendingTranslationStore.instance.list('u1'), isEmpty);
    });
  });

  group('pendingTranslationToPhrase', () {
    test('maps to a marked phrase that can never enter the review queue', () {
      final entry = PendingTranslation(
        localId: 'abc',
        sourceText: 'hello',
        sourceLang: 'en',
        targetLang: 'es',
        plainTranslatedText: 'hola',
        createdAt: DateTime.now(),
      );

      final phrase = pendingTranslationToPhrase(entry, uid: 'u1');

      expect(phrase.isPendingOffline, isTrue);
      expect(phrase.id, 'pending-abc');
      expect(phrase.translatedText, 'hola');
      expect(phrase.registerNote, isNull);
      expect(phrase.grammarNote, isNull);
      expect(phrase.vocabBreakdown, isEmpty);
      expect(phrase.isDue, isFalse,
          reason: 'no server row exists to rate — must never be reviewable');
    });
  });
}
