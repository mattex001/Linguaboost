import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/phrase.dart';

class PhraseRepository {
  PhraseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseQueryBuilder get _phrases => _client.from('phrases');

  /// Live stream of all of the user's phrases, newest first. Powers the
  /// phrasebook list, saved count, and due count from one subscription.
  Stream<List<Phrase>> watchPhrases(String uid) {
    return _phrases
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Phrase.fromJson).toList());
  }

  /// Auto-save after a successful translation (FR-2.1). New phrases are
  /// immediately due (next_review_at defaults to now()). Returns the saved row.
  Future<Phrase> addPhrase({
    required String uid,
    required String sourceText,
    required String targetLang,
    required Map<String, dynamic> translation,
    String sourceLang = 'en',
  }) async {
    final row = await _phrases.insert({
      'user_id': uid,
      'source_text': sourceText,
      'translated_text': translation['translatedText'],
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'register_note': translation['registerNote'],
      'category': translation['category'],
      'confidence': translation['confidence'] ?? 'high',
      'confidence_note': translation['confidenceNote'],
      'vocab_breakdown': translation['vocabBreakdown'],
      'grammar_note': translation['grammarNote'],
      'pronunciation': translation['pronunciation'],
    }).select().single();
    return Phrase.fromJson(row);
  }

  Future<void> updateCategory(String phraseId, PhraseCategory category) =>
      _phrases.update({'category': category.id}).eq('id', phraseId);

  Future<void> deletePhrase(String phraseId) =>
      _phrases.delete().eq('id', phraseId);

  /// Persists an SM-2 rating immediately — this is what makes review sessions
  /// exit-safe (FR-3.6): every answered card is durably rescheduled.
  Future<void> updateReview({
    required String phraseId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime nextReviewAt,
    required String lastResult,
  }) {
    return _phrases.update({
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'next_review_at': nextReviewAt.toUtc().toIso8601String(),
      'last_result': lastResult,
      'last_reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', phraseId);
  }
}
