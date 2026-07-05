import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/providers/auth_provider.dart';
import '../../phrasebook/models/phrase.dart';
import '../repositories/translate_repository.dart';

final translateRepositoryProvider = Provider<TranslateRepository>(
  (ref) => TranslateRepository(),
);

// ── Translation flow ──────────────────────────────────────────────────────────

/// Drives one translation round-trip. State holds the most recently saved
/// phrase (null before the first translation).
class TranslateController extends AsyncNotifier<Phrase?> {
  @override
  Future<Phrase?> build() async => null;

  /// Translates [text] into [targetLang], auto-saves it, and returns the
  /// saved phrase. Rethrows so the screen can show inline errors.
  Future<Phrase> translate({
    required String text,
    required String targetLang,
  }) async {
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid == null) {
      throw const TranslationException('You need to be signed in.');
    }

    state = const AsyncLoading();
    try {
      final phrase = await ref.read(translateRepositoryProvider).translateAndSave(
            uid: uid,
            text: text,
            targetLang: targetLang,
          );
      state = AsyncData(phrase);
      return phrase;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
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

  const SpeechInputState({
    this.available = false,
    this.listening = false,
    this.transcript = '',
  });

  SpeechInputState copyWith({
    bool? available,
    bool? listening,
    String? transcript,
  }) =>
      SpeechInputState(
        available: available ?? this.available,
        listening: listening ?? this.listening,
        transcript: transcript ?? this.transcript,
      );
}

class SpeechInputNotifier extends Notifier<SpeechInputState> {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  @override
  SpeechInputState build() {
    ref.onDispose(() {
      _speech.stop();
    });
    return const SpeechInputState();
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) return state.available;
    _initialized = true;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          state = state.copyWith(listening: false);
        }
      },
      onError: (_) => state = state.copyWith(listening: false),
    );
    state = state.copyWith(available: available);
    return available;
  }

  /// Starts listening; live partial transcripts land in [SpeechInputState].
  /// Source language is English (users translate from English).
  Future<void> start() async {
    final available = await _ensureInitialized();
    if (!available) return;

    state = state.copyWith(listening: true, transcript: '');
    await _speech.listen(
      localeId: 'en_US',
      // Auto-stop ~2.5s after the speaker goes quiet, so the hands-free
      // pipeline (speak → translate → play) can continue without a tap.
      pauseFor: const Duration(milliseconds: 2500),
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
