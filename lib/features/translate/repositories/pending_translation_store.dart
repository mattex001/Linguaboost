import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A phrase translated on-device while offline, waiting to be replayed
/// through the full Claude pipeline (and inserted into Supabase) once the
/// connection returns. Held only in local storage — a device-offline phrase
/// can't reach Postgres at all, so there is no server row yet.
class PendingTranslation {
  final String localId;
  final String sourceText;
  final String sourceLang;
  final String targetLang;
  final String plainTranslatedText;
  final DateTime createdAt;

  const PendingTranslation({
    required this.localId,
    required this.sourceText,
    required this.sourceLang,
    required this.targetLang,
    required this.plainTranslatedText,
    required this.createdAt,
  });

  factory PendingTranslation.fromJson(Map<String, dynamic> json) =>
      PendingTranslation(
        localId: json['localId'] as String,
        sourceText: json['sourceText'] as String,
        sourceLang: json['sourceLang'] as String,
        targetLang: json['targetLang'] as String,
        plainTranslatedText: json['plainTranslatedText'] as String,
        createdAt: DateTime.tryParse(json['createdAt'].toString()) ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'sourceText': sourceText,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'plainTranslatedText': plainTranslatedText,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// shared_preferences-backed queue of [PendingTranslation]s, keyed per user.
/// Expected volume is a handful of phrases at most, so a JSON list is plenty.
class PendingTranslationStore {
  PendingTranslationStore._();
  static final instance = PendingTranslationStore._();

  static String _key(String uid) => 'pending_translations_$uid';

  Future<List<PendingTranslation>> list(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) =>
              PendingTranslation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<PendingTranslation> add(
    String uid, {
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    required String plainTranslatedText,
  }) async {
    final entry = PendingTranslation(
      localId: const Uuid().v4(),
      sourceText: sourceText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      plainTranslatedText: plainTranslatedText,
      createdAt: DateTime.now(),
    );
    final entries = await list(uid);
    await _write(uid, [...entries, entry]);
    return entry;
  }

  Future<void> remove(String uid, String localId) async {
    final entries = await list(uid);
    await _write(
      uid,
      entries.where((e) => e.localId != localId).toList(),
    );
  }

  Future<void> _write(String uid, List<PendingTranslation> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid),
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
