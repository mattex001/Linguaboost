import 'package:supabase_flutter/supabase_flutter.dart';

import '../../phrasebook/models/phrase.dart';
import '../../phrasebook/repositories/phrase_repository.dart';

class TranslationException implements Exception {
  final String message;
  const TranslationException(this.message);

  @override
  String toString() => message;
}

class TranslateRepository {
  TranslateRepository({
    SupabaseClient? client,
    PhraseRepository? phraseRepository,
  })  : _client = client ?? Supabase.instance.client,
        _phraseRepository = phraseRepository ?? PhraseRepository();

  final SupabaseClient _client;
  final PhraseRepository _phraseRepository;

  /// Calls the translate-phrase Edge Function, then auto-saves the phrase
  /// (FR-2.1 — no manual save action). Returns the saved row.
  Future<Phrase> translateAndSave({
    required String uid,
    required String text,
    required String targetLang,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'translate-phrase',
        body: {'text': text, 'targetLang': targetLang},
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final serverError = details is Map ? details['error'] : null;
      throw TranslationException(
        serverError?.toString() ??
            'Translation failed. Check your connection and try again.',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const TranslationException('Unexpected response from translator.');
    }

    return _phraseRepository.addPhrase(
      uid: uid,
      sourceText: text,
      targetLang: targetLang,
      translation: Map<String, dynamic>.from(data),
    );
  }
}
