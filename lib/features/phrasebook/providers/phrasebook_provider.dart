import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../models/phrase.dart';
import '../repositories/phrase_repository.dart';

final phraseRepositoryProvider = Provider<PhraseRepository>(
  (ref) => PhraseRepository(),
);

/// Live stream of the user's whole phrasebook (newest first). The single
/// subscription behind the list UI, saved count, and due count. Keyed on the
/// stable user id so auth events don't tear the stream down.
final phrasesStreamProvider = StreamProvider<List<Phrase>>((ref) {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return Stream.value(const <Phrase>[]);
  return ref.watch(phraseRepositoryProvider).watchPhrases(uid);
});

/// Snapshot list (empty while loading).
final phrasesSnapshotProvider = Provider<List<Phrase>>((ref) {
  return ref.watch(phrasesStreamProvider).asData?.value ?? const [];
});

final phrasesSavedCountProvider = Provider<int>((ref) {
  return ref.watch(phrasesSnapshotProvider).length;
});

// ── Search + category filters ─────────────────────────────────────────────────

class PhraseSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final phraseSearchQueryProvider = NotifierProvider<PhraseSearchNotifier, String>(
  PhraseSearchNotifier.new,
);

class PhraseCategoryFilterNotifier extends Notifier<PhraseCategory?> {
  @override
  PhraseCategory? build() => null; // null = All

  void select(PhraseCategory? category) => state = category;
}

final phraseCategoryFilterProvider =
    NotifierProvider<PhraseCategoryFilterNotifier, PhraseCategory?>(
  PhraseCategoryFilterNotifier.new,
);

/// Client-side filter over the streamed list: case- and diacritic-insensitive
/// match on source or translated text (FR-2.4), plus category chip filter.
final filteredPhrasesProvider = Provider<List<Phrase>>((ref) {
  final phrases = ref.watch(phrasesSnapshotProvider);
  final query = _foldDiacritics(ref.watch(phraseSearchQueryProvider).trim());
  final category = ref.watch(phraseCategoryFilterProvider);

  return phrases.where((p) {
    if (category != null && p.category != category) return false;
    if (query.isEmpty) return true;
    return _foldDiacritics(p.sourceText).contains(query) ||
        _foldDiacritics(p.translatedText).contains(query);
  }).toList();
});

const _diacritics =
    'àáâãäåçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
const _plain = 'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY';

String _foldDiacritics(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final index = _diacritics.indexOf(char);
    buffer.write(index >= 0 ? _plain[index] : char);
  }
  return buffer.toString().toLowerCase();
}
