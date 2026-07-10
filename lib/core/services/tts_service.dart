import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/languages.dart';
import '../providers/user_provider.dart';
import 'cloud_tts_player.dart';

/// A voice available for a given locale — a device TTS voice or a Google
/// Cloud TTS voice, identified by [name] (what gets persisted).
class VoiceOption {
  final String name;
  final String locale;
  const VoiceOption({required this.name, required this.locale});

  String get displayName => friendlyName(name);

  /// Human-friendly label. Google voice ids look like
  /// "fr-FR-Chirp3-HD-Achernar" or "es-ES-Neural2-A" — strip the locale
  /// prefix and show "Achernar" / "Neural2 A". Anything else (device
  /// voices) is shown as-is.
  static String friendlyName(String name) {
    final match =
        RegExp(r'^[a-z]{2,3}(?:-[A-Za-z]{2,4})?-(.+)$').firstMatch(name);
    if (match == null) return name;
    final parts = match.group(1)!.split('-');
    // Single-letter suffixes ("Neural2-A") need their tier for context;
    // named voices ("Chirp3-HD-Achernar") read best as just the name.
    if (parts.last.length <= 2) return parts.join(' ');
    return parts.last;
  }
}

/// Pronunciation playback abstraction. Device TTS today; a server-generated
/// audio implementation can swap in later without touching any widgets.
abstract class PronunciationPlayer {
  Future<void> speak(String text, String langCode);
  Future<void> stop();

  /// Warms whatever cache backs [speak] so a later play starts instantly.
  /// Fire-and-forget; no-op for players with nothing to warm (device TTS).
  Future<void> prefetch(String text, String langCode) async {}

  /// Up to 5 device voices available for [langCode]. May return fewer (or
  /// zero) if the OS only ships one voice for that language.
  Future<List<VoiceOption>> voicesForLanguage(String langCode);

  /// Plays [langCode]'s preview phrase using [voice], without persisting it.
  Future<void> previewVoice(VoiceOption voice, String langCode);

  /// Keeps the player in sync with the user's saved voice preference.
  void setPreferredVoice(String? name, String? locale);
}

class DeviceTtsPlayer implements PronunciationPlayer {
  DeviceTtsPlayer({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.0);
    // Lets previewVoice()'s await reflect actual playback duration, so the
    // voice picker's play/stop icon tracks reality. Existing speak() call
    // sites are all fire-and-forget, so this doesn't change their behavior.
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;
  String? _currentLocale;
  String? _preferredVoiceName;
  String? _preferredVoiceLocale;
  String? _appliedVoiceKey;

  @override
  void setPreferredVoice(String? name, String? locale) {
    _preferredVoiceName = name;
    _preferredVoiceLocale = locale;
  }

  @override
  Future<void> speak(String text, String langCode) async {
    final locale = targetLanguageForCode(langCode)?.ttsLocale ?? langCode;
    if (locale != _currentLocale) {
      try {
        final available = await _tts.isLanguageAvailable(locale);
        await _tts.setLanguage(available == true ? locale : langCode);
        _currentLocale = locale;
      } catch (e) {
        debugPrint('DeviceTtsPlayer: could not set language $locale — $e');
      }
    }
    await _applyPreferredVoiceIfNeeded(locale);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _applyPreferredVoiceIfNeeded(String locale) async {
    if (_preferredVoiceName == null || _preferredVoiceLocale != locale) {
      return;
    }
    final key = '$_preferredVoiceName@$_preferredVoiceLocale';
    if (key == _appliedVoiceKey) return;
    try {
      await _tts.setVoice(
        {'name': _preferredVoiceName!, 'locale': _preferredVoiceLocale!},
      );
      _appliedVoiceKey = key;
    } catch (e) {
      debugPrint('DeviceTtsPlayer: could not set voice $key — $e');
    }
  }

  @override
  Future<List<VoiceOption>> voicesForLanguage(String langCode) async {
    final locale = targetLanguageForCode(langCode)?.ttsLocale ?? langCode;
    final langPrefix = locale.split(RegExp('[-_]')).first.toLowerCase();

    List<dynamic> raw;
    try {
      raw = (await _tts.getVoices) as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint('DeviceTtsPlayer: could not list voices for $locale — $e');
      return const [];
    }

    bool matchesLocale(String voiceLocale, {required bool exact}) {
      final normalized = voiceLocale.replaceAll('_', '-').toLowerCase();
      if (exact) return normalized == locale.toLowerCase();
      return normalized.split('-').first == langPrefix;
    }

    List<VoiceOption> collect({required bool exact}) {
      final seen = <String>{};
      final options = <VoiceOption>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString();
        final voiceLocale = entry['locale']?.toString();
        if (name == null || voiceLocale == null) continue;
        if (!matchesLocale(voiceLocale, exact: exact)) continue;
        if (!seen.add(name)) continue;
        options.add(VoiceOption(name: name, locale: voiceLocale));
        if (options.length == 5) break;
      }
      return options;
    }

    final exactMatches = collect(exact: true);
    return exactMatches.isNotEmpty ? exactMatches : collect(exact: false);
  }

  @override
  Future<void> previewVoice(VoiceOption voice, String langCode) async {
    final language = targetLanguageForCode(langCode);
    final phrase = language?.previewPhrase ?? 'Hello';
    try {
      await _tts.setLanguage(voice.locale);
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
      _currentLocale = voice.locale;
      _appliedVoiceKey = null;
    } catch (e) {
      debugPrint('DeviceTtsPlayer: could not preview ${voice.name} — $e');
    }
    await _tts.stop();
    await _tts.speak(phrase);
  }

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> prefetch(String text, String langCode) async {
    // Device TTS synthesizes live — nothing to warm.
  }
}

final pronunciationPlayerProvider = Provider<PronunciationPlayer>((ref) {
  // Neural voices via the tts-speak Edge Function, with on-device audio
  // caching; DeviceTtsPlayer remains inside it as the offline/unsupported
  // fallback (e.g. Yoruba/Igbo, or the server key not configured yet).
  final player = CloudTtsPlayer();
  ref.onDispose(player.stop);
  ref.listen(userSnapshotProvider, (previous, next) {
    player.setPreferredVoice(next?.voiceName, next?.voiceLocale);
  }, fireImmediately: true);
  return player;
});
