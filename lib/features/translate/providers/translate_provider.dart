import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/constants/languages.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../phrasebook/models/phrase.dart';
import '../repositories/pending_translation_store.dart';
import '../repositories/translate_repository.dart';
import '../services/offline_translation_service.dart';

final translateRepositoryProvider = Provider<TranslateRepository>(
  (ref) => TranslateRepository(),
);

// ── Offline pending queue ─────────────────────────────────────────────────────

/// Phrases translated on-device while offline, still waiting for the full
/// Claude pipeline. Re-read after every add/remove via [refresh].
class PendingTranslationsNotifier
    extends AsyncNotifier<List<PendingTranslation>> {
  @override
  Future<List<PendingTranslation>> build() async {
    final uid = ref.watch(authUserIdProvider);
    if (uid == null) return const [];
    return PendingTranslationStore.instance.list(uid);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

final pendingTranslationsProvider = AsyncNotifierProvider<
    PendingTranslationsNotifier, List<PendingTranslation>>(
  PendingTranslationsNotifier.new,
);

/// Re-runs every pending offline phrase through the normal online pipeline
/// (full Claude call + real Supabase insert), removing each local entry as
/// its upgrade lands. Invoked when connectivity returns; safe to call
/// repeatedly — a failed entry just stays queued for the next attempt.
class PendingTranslationSweeper {
  PendingTranslationSweeper._();
  static final instance = PendingTranslationSweeper._();

  bool _running = false;

  Future<void> sweep({
    required String uid,
    required TranslateRepository repository,
  }) async {
    if (_running) return;
    _running = true;
    try {
      final entries = await PendingTranslationStore.instance.list(uid);
      for (final entry in entries) {
        try {
          await repository.translateAndSave(
            uid: uid,
            text: entry.sourceText,
            targetLang: entry.targetLang,
            sourceLang: entry.sourceLang,
          );
          await PendingTranslationStore.instance.remove(uid, entry.localId);
        } catch (e) {
          debugPrint('PendingTranslationSweeper: upgrade failed, keeping '
              '"${entry.sourceText}" queued — $e');
        }
      }
    } finally {
      _running = false;
    }
  }
}

// ── Translation flow ──────────────────────────────────────────────────────────

/// Drives one translation round-trip. State holds the most recently saved
/// phrase (null before the first translation).
class TranslateController extends AsyncNotifier<Phrase?> {
  @override
  Future<Phrase?> build() async => null;

  /// Translates [text] into [targetLang], auto-saves it, and returns the
  /// saved phrase. Rethrows so the screen can show inline errors.
  ///
  /// With no connectivity, falls back to on-device ML Kit: a plain
  /// translation only, held in the local pending queue until the reconnect
  /// sweep replays it through the full pipeline.
  Future<Phrase> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid == null) {
      throw const TranslationException('You need to be signed in.');
    }

    final online = ref.read(isOnlineProvider).value ?? true;
    if (!online) {
      return _translateOffline(
        uid: uid,
        text: text,
        targetLang: targetLang,
        sourceLang: sourceLang,
      );
    }

    state = const AsyncLoading();
    try {
      final phrase = await ref.read(translateRepositoryProvider).translateAndSave(
            uid: uid,
            text: text,
            targetLang: targetLang,
            sourceLang: sourceLang,
          );
      state = AsyncData(phrase);
      return phrase;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Phrase> _translateOffline({
    required String uid,
    required String text,
    required String targetLang,
    required String sourceLang,
  }) async {
    final language = targetLanguageForCode(targetLang);
    final label = language?.label ?? targetLang;
    final service = OfflineTranslationService.instance;

    if (!service.isLanguagePairSupported(sourceLang, targetLang)) {
      throw TranslationException(
        "You're offline, and offline translation isn't available for "
        '$label. Connect to the internet to translate.',
      );
    }

    state = const AsyncLoading();
    try {
      final translated = await service.translate(
        text: text,
        sourceCode: sourceLang,
        targetCode: targetLang,
      );
      if (translated == null || translated.trim().isEmpty) {
        throw TranslationException(
          "You're offline, and the $label offline language pack isn't "
          'downloaded yet. Connect to the internet once to set it up.',
        );
      }

      final entry = await PendingTranslationStore.instance.add(
        uid,
        sourceText: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
        plainTranslatedText: translated,
      );
      ref.invalidate(pendingTranslationsProvider);

      final phrase = pendingTranslationToPhrase(entry, uid: uid);
      state = AsyncData(phrase);
      return phrase;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Presents a locally-queued offline translation through the standard
/// [Phrase] shape so existing UI (detail sheet, phrasebook list) can render
/// it. Marked [Phrase.isPendingOffline]; scheduled far in the future so it
/// can never enter the review queue (there is no server row to rate yet).
Phrase pendingTranslationToPhrase(PendingTranslation entry,
    {required String uid}) {
  return Phrase(
    id: 'pending-${entry.localId}',
    userId: uid,
    sourceText: entry.sourceText,
    translatedText: entry.plainTranslatedText,
    sourceLang: entry.sourceLang,
    targetLang: entry.targetLang,
    category: PhraseCategory.greetingsSmalltalk,
    confidence: 'medium',
    review: ReviewState(
      nextReviewAt: entry.createdAt.add(const Duration(days: 36500)),
    ),
    createdAt: entry.createdAt,
    isPendingOffline: true,
  );
}

final translateControllerProvider =
    AsyncNotifierProvider<TranslateController, Phrase?>(
  TranslateController.new,
);

// ── Speech-to-text input (FR-1.1) ─────────────────────────────────────────────

class SpeechInputState {
  final bool available;
  final bool listening;
  final String transcript;
  final String? errorMessage;

  const SpeechInputState({
    this.available = false,
    this.listening = false,
    this.transcript = '',
    this.errorMessage,
  });

  SpeechInputState copyWith({
    bool? available,
    bool? listening,
    String? transcript,
    String? errorMessage,
  }) =>
      SpeechInputState(
        available: available ?? this.available,
        listening: listening ?? this.listening,
        transcript: transcript ?? this.transcript,
        errorMessage: errorMessage,
      );
}

class SpeechInputNotifier extends Notifier<SpeechInputState> {
  final SpeechToText _speech = SpeechToText();

  @override
  SpeechInputState build() {
    ref.onDispose(() {
      _speech.stop();
    });
    return const SpeechInputState();
  }

  Future<bool> _ensureInitialized() async {
    // Re-initializing is safe to call repeatedly (the plugin no-ops if
    // already set up), so a prior failure — e.g. speech-recognition
    // permission wasn't granted yet — doesn't get cached forever and can
    // succeed on a later tap once the user grants it.
    if (state.available) return true;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          state = state.copyWith(listening: false);
        }
      },
      onError: (error) {
        debugPrint(
          'SpeechInputNotifier: ${error.errorMsg} (permanent: ${error.permanent})',
        );
        state = state.copyWith(
          listening: false,
          errorMessage: error.errorMsg,
        );
      },
    );
    state = state.copyWith(available: available);
    return available;
  }

  /// Starts listening; live partial transcripts land in [SpeechInputState].
  /// [localeId] should match the user's chosen source language (e.g. 'es_ES').
  ///
  /// [pauseFor] controls the silence auto-stop: hands-free capture wants a
  /// short one (~1.1s) so the speak → translate → play pipeline continues
  /// without a tap; push-to-talk passes a long one, since releasing the
  /// button is the stop signal there.
  Future<void> start({
    String localeId = 'en_US',
    Duration pauseFor = const Duration(milliseconds: 1100),
  }) async {
    final available = await _ensureInitialized();
    if (!available) return;

    state = state.copyWith(listening: true, transcript: '');
    await _speech.listen(
      localeId: localeId,
      pauseFor: pauseFor,
      listenFor: const Duration(seconds: 45),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (SpeechRecognitionResult result) {
        state = state.copyWith(transcript: result.recognizedWords);
      },
    );
  }

  Future<void> stop() async {
    await _speech.stop();
    state = state.copyWith(listening: false);
  }
}

final speechInputProvider =
    NotifierProvider<SpeechInputNotifier, SpeechInputState>(
  SpeechInputNotifier.new,
);
