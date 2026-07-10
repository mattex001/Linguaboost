import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/user_provider.dart';
import '../../../core/services/local_storage_service.dart';
import '../../translate/providers/translate_provider.dart';
import '../models/phrase.dart';
import '../repositories/phrase_repository.dart';

final phraseRepositoryProvider = Provider<PhraseRepository>(
  (ref) => PhraseRepository(),
);

/// Pull-to-refresh backend: tears down and re-establishes the realtime
/// streams (phrases + profile) and re-reads the offline-pending queue, then
/// waits for the phrase stream's first fresh snapshot so the spinner
/// reflects actual work. Safe to call from any screen.
Future<void> refreshAppData(WidgetRef ref) async {
  ref.invalidate(phrasesStreamProvider);
  ref.invalidate(currentUserProvider);
  ref.invalidate(pendingTranslationsProvider);
  try {
    await ref
        .read(phrasesStreamProvider.future)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    // Offline or slow — the cached snapshot keeps serving the UI.
  }
}

/// Live stream of the user's whole phrasebook (newest first). The single
/// subscription behind the list UI, saved count, and due count. Keyed on the
/// stable user id so auth events don't tear the stream down. Every emission
/// is cached to disk (see [phrasesSnapshotProvider]) so losing the
/// connection doesn't wipe previously translated phrases from the UI.
final phrasesStreamProvider = StreamProvider<List<Phrase>>((ref) {
  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return Stream.value(const <Phrase>[]);
  return ref.watch(phraseRepositoryProvider).watchPhrases(uid).map((phrases) {
    LocalStorageService.instance.setCachedPhrasesJson(
      uid,
      jsonEncode(phrases.map((p) => p.toJson()).toList()),
    );
    return phrases;
  });
});

/// Snapshot list. Prefers the live stream — including its last-known value
/// while reconnecting or erroring — and falls back to the on-disk cache
/// when the stream has never delivered anything (e.g. app launched with no
/// connectivity). Unfiltered — spans every language the user has saved a
/// phrase in; use [phrasesForActiveLanguageProvider] for anything
/// user-facing (list, counts, due queue).
final phrasesSnapshotProvider = Provider<List<Phrase>>((ref) {
  final live = ref.watch(phrasesStreamProvider).value;
  if (live != null) return live;

  final uid = ref.watch(authUserIdProvider);
  if (uid == null) return const [];
  final cached = LocalStorageService.instance.cachedPhrasesJson(uid);
  if (cached == null) return const [];
  try {
    return (jsonDecode(cached) as List)
        .map((e) => Phrase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    return const [];
  }
});

/// The phrasebook scoped to the active practicing language (PRD ask:
/// switching to Spanish should show only Spanish phrases, and vice versa).
///
/// Includes offline-pending phrases (translated on-device, not yet in
/// Supabase) at the top — they carry [Phrase.isPendingOffline] and a
/// far-future review date, so they show in the list and counts but can
/// never enter the review queue before their online upgrade lands.
final phrasesForActiveLanguageProvider = Provider<List<Phrase>>((ref) {
  final activeLanguage = ref.watch(activeLanguageCodeProvider);
  final uid = ref.watch(authUserIdProvider) ?? '';
  final pending = (ref.watch(pendingTranslationsProvider).value ?? const [])
      .where((e) => e.targetLang == activeLanguage)
      .map((e) => pendingTranslationToPhrase(e, uid: uid));
  final saved = ref
      .watch(phrasesSnapshotProvider)
      .where((p) => p.targetLang == activeLanguage);
  return [...pending, ...saved].toList();
});

final phrasesSavedCountProvider = Provider<int>((ref) {
  return ref.watch(phrasesForActiveLanguageProvider).length;
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

/// Client-side filter over the active-language phrasebook: case- and
/// diacritic-insensitive match on source or translated text (FR-2.4), plus
/// category chip filter.
final filteredPhrasesProvider = Provider<List<Phrase>>((ref) {
  final phrases = ref.watch(phrasesForActiveLanguageProvider);
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
