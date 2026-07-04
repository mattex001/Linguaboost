import 'package:flutter/widgets.dart';

import '../../../core/constants/cool_icons.dart';

/// Fixed category taxonomy (PRD §9.3). Mirrored server-side in
/// supabase/functions/_shared/taxonomy.ts — keep the ids in sync.
enum PhraseCategory {
  greetingsSmalltalk('greetings_smalltalk', 'Greetings', CoolIcons.chat),
  foodDining('food_dining', 'Food & Dining', CoolIcons.shopping_bag_01),
  shoppingMoney('shopping_money', 'Shopping & Money', CoolIcons.credit_card_01),
  transportDirections(
      'transport_directions', 'Transport', CoolIcons.navigation),
  housingUtilities('housing_utilities', 'Housing', CoolIcons.house_02),
  healthEmergencies('health_emergencies', 'Health', CoolIcons.first_aid),
  workSchool('work_school', 'Work & School', CoolIcons.suitcase),
  bureaucracyDocuments(
      'bureaucracy_documents', 'Paperwork', CoolIcons.file_document),
  socialRelationships('social_relationships', 'Social', CoolIcons.users),
  numbersTimeDates('numbers_time_dates', 'Time & Numbers', CoolIcons.clock);

  const PhraseCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static PhraseCategory fromId(String? id) => PhraseCategory.values.firstWhere(
        (c) => c.id == id,
        orElse: () => PhraseCategory.greetingsSmalltalk,
      );
}

class VocabEntry {
  final String term;
  final String meaning;

  const VocabEntry({required this.term, required this.meaning});

  factory VocabEntry.fromJson(Map<String, dynamic> json) => VocabEntry(
        term: (json['term'] ?? '').toString(),
        meaning: (json['meaning'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'term': term, 'meaning': meaning};
}

/// SM-2 review state embedded on the phrase row.
class ReviewState {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final String? lastResult; // again | hard | easy
  final DateTime? lastReviewedAt;

  const ReviewState({
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.nextReviewAt,
    this.lastResult,
    this.lastReviewedAt,
  });

  bool get isDue => !nextReviewAt.isAfter(DateTime.now());
}

/// A row from the Supabase `phrases` table.
class Phrase {
  final String id;
  final String userId;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String? registerNote;
  final PhraseCategory category;
  final String confidence; // high | medium | low
  final String? confidenceNote;
  final bool seeded;
  final List<VocabEntry> vocabBreakdown;
  final String? grammarNote;
  final String? phonetic;
  final String? ipa;
  final ReviewState review;
  final DateTime createdAt;

  const Phrase({
    required this.id,
    required this.userId,
    required this.sourceText,
    required this.translatedText,
    this.sourceLang = 'en',
    required this.targetLang,
    this.registerNote,
    required this.category,
    this.confidence = 'high',
    this.confidenceNote,
    this.seeded = false,
    this.vocabBreakdown = const [],
    this.grammarNote,
    this.phonetic,
    this.ipa,
    required this.review,
    required this.createdAt,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    final pronunciation = json['pronunciation'];
    return Phrase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceText: (json['source_text'] ?? '').toString(),
      translatedText: (json['translated_text'] ?? '').toString(),
      sourceLang: (json['source_lang'] ?? 'en').toString(),
      targetLang: (json['target_lang'] ?? '').toString(),
      registerNote: json['register_note'] as String?,
      category: PhraseCategory.fromId(json['category'] as String?),
      confidence: (json['confidence'] ?? 'high').toString(),
      confidenceNote: json['confidence_note'] as String?,
      seeded: (json['seeded'] as bool?) ?? false,
      vocabBreakdown: (json['vocab_breakdown'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(VocabEntry.fromJson)
              .toList() ??
          const [],
      grammarNote: json['grammar_note'] as String?,
      phonetic: pronunciation is Map ? pronunciation['phonetic'] as String? : null,
      ipa: pronunciation is Map ? pronunciation['ipa'] as String? : null,
      review: ReviewState(
        easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: (json['interval_days'] as num?)?.toInt() ?? 0,
        repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
        nextReviewAt: DateTime.tryParse(json['next_review_at']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now(),
        lastResult: json['last_result'] as String?,
        lastReviewedAt:
            DateTime.tryParse(json['last_reviewed_at']?.toString() ?? '')
                ?.toLocal(),
      ),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  bool get isDue => review.isDue;
}
