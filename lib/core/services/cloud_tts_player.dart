import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../constants/languages.dart';
import 'tts_service.dart';

/// Neural pronunciation playback via the `tts-speak` Edge Function (Google
/// Cloud TTS). Synthesized audio is cached on-device keyed by
/// (voice, language, text) — reviews replay the same phrases constantly, so
/// each unique phrase is billed once per device, not once per play.
///
/// Falls back to [DeviceTtsPlayer] whenever the cloud path can't deliver:
/// offline with no cached audio, unsupported language (Yoruba/Igbo have no
/// Google voices), server not configured, or any transient failure.
class CloudTtsPlayer implements PronunciationPlayer {
  CloudTtsPlayer({DeviceTtsPlayer? fallback})
      : _fallback = fallback ?? DeviceTtsPlayer();

  final DeviceTtsPlayer _fallback;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _preferredVoiceName;
  String? _preferredVoiceLocale;
  Directory? _cacheDir;

  @override
  void setPreferredVoice(String? name, String? locale) {
    _preferredVoiceName = name;
    _preferredVoiceLocale = locale;
    _fallback.setPreferredVoice(name, locale);
  }

  @override
  Future<void> speak(String text, String langCode) async {
    final locale = targetLanguageForCode(langCode)?.ttsLocale ?? langCode;
    final voice =
        _preferredVoiceLocale == locale ? _preferredVoiceName : null;
    final file = await _cachedOrFetched(text, locale, voice);
    if (file == null) {
      await _fallback.speak(text, langCode);
      return;
    }
    await _audioPlayer.stop();
    // Low-latency mode trims the per-play startup delay; these are short
    // local clips, exactly what that mode is for. Previews keep the default
    // mode since they rely on onPlayerComplete.
    await _audioPlayer.play(
      DeviceFileSource(file.path),
      mode: PlayerMode.lowLatency,
    );
  }

  @override
  Future<void> prefetch(String text, String langCode) async {
    final locale = targetLanguageForCode(langCode)?.ttsLocale ?? langCode;
    final voice =
        _preferredVoiceLocale == locale ? _preferredVoiceName : null;
    await _cachedOrFetched(text, locale, voice);
  }

  @override
  Future<void> previewVoice(VoiceOption voice, String langCode) async {
    final language = targetLanguageForCode(langCode);
    final phrase = language?.previewPhrase ?? 'Hello';
    final file =
        await _cachedOrFetched(phrase, voice.locale, voice.name);
    if (file == null) {
      await _fallback.previewVoice(voice, langCode);
      return;
    }
    await _audioPlayer.stop();
    // Await completion so the voice picker's play/stop icon tracks reality,
    // matching DeviceTtsPlayer's awaitSpeakCompletion behavior.
    await _audioPlayer.play(DeviceFileSource(file.path));
    await _audioPlayer.onPlayerComplete.first;
  }

  @override
  Future<List<VoiceOption>> voicesForLanguage(String langCode) async {
    final locale = targetLanguageForCode(langCode)?.ttsLocale ?? langCode;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'tts-speak',
        body: {'action': 'voices', 'languageCode': locale},
      );
      final data = response.data;
      if (data is! Map) return _fallback.voicesForLanguage(langCode);
      final voices = (data['voices'] as List? ?? const [])
          .whereType<Map>()
          .map((v) => VoiceOption(
                name: v['name'].toString(),
                // Store our locale, not Google's (ar-XA/cmn-CN differ), so
                // the saved preference matches speak()'s lookup key.
                locale: locale,
              ))
          .toList();
      return voices.isNotEmpty
          ? voices
          : _fallback.voicesForLanguage(langCode);
    } catch (e) {
      debugPrint('CloudTtsPlayer: voices lookup failed — $e');
      return _fallback.voicesForLanguage(langCode);
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _fallback.stop();
  }

  // ── Audio cache ────────────────────────────────────────────────────────────

  Future<File?> _cachedOrFetched(
    String text,
    String locale,
    String? voiceName,
  ) async {
    try {
      final dir = await _ensureCacheDir();
      final key = md5
          .convert(utf8.encode('${voiceName ?? 'default'}|$locale|$text'))
          .toString();
      final file = File('${dir.path}/$key.mp3');
      if (await file.exists()) return file;

      final response = await Supabase.instance.client.functions.invoke(
        'tts-speak',
        body: {
          'action': 'speak',
          'text': text,
          'languageCode': locale,
          'voiceName': ?voiceName,
        },
      );
      final data = response.data;
      final audioContent = data is Map ? data['audioContent'] : null;
      if (audioContent is! String || audioContent.isEmpty) return null;

      await file.writeAsBytes(base64Decode(audioContent), flush: true);
      return file;
    } catch (e) {
      debugPrint('CloudTtsPlayer: synth failed for "$text" — $e');
      return null;
    }
  }

  Future<Directory> _ensureCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/tts_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }
}
