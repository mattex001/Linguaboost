import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/languages.dart';

/// Pronunciation playback abstraction. Device TTS today; a server-generated
/// audio implementation can swap in later without touching any widgets.
abstract class PronunciationPlayer {
  Future<void> speak(String text, String langCode);
  Future<void> stop();
}

class DeviceTtsPlayer implements PronunciationPlayer {
  DeviceTtsPlayer({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts;
  String? _currentLocale;

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
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

final pronunciationPlayerProvider = Provider<PronunciationPlayer>((ref) {
  final player = DeviceTtsPlayer();
  ref.onDispose(player.stop);
  return player;
});
