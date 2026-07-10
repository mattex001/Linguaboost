import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// On-device translation via ML Kit — the offline fallback when the Claude
/// pipeline is unreachable. Produces a plain translation only (no register
/// note, vocab breakdown, grammar note or pronunciation); the phrase is
/// upgraded to the full rich version by the reconnect sweep later.
///
/// Language support is derived from ML Kit's own [TranslateLanguage] roster
/// at runtime (never hardcoded), so it self-corrects as the plugin's
/// coverage grows. As of 0.14.0 that covers 12 of the app's 14 target
/// languages — Yoruba and Igbo are not available on-device.
class OfflineTranslationService {
  OfflineTranslationService._();
  static final instance = OfflineTranslationService._();

  final _modelManager = OnDeviceTranslatorModelManager();

  /// Whether ML Kit can translate between these languages at all.
  bool isLanguagePairSupported(String sourceCode, String targetCode) =>
      BCP47Code.fromRawValue(sourceCode) != null &&
      BCP47Code.fromRawValue(targetCode) != null;

  /// Whether both language models are already downloaded to the device —
  /// i.e. an offline translation would succeed right now.
  Future<bool> isReadyOffline(String sourceCode, String targetCode) async {
    final source = BCP47Code.fromRawValue(sourceCode);
    final target = BCP47Code.fromRawValue(targetCode);
    if (source == null || target == null) return false;
    return await _modelManager.isModelDownloaded(source.bcpCode) &&
        await _modelManager.isModelDownloaded(target.bcpCode);
  }

  /// Proactively downloads the models for a language pair (Wi-Fi only, per
  /// ML Kit's default) so translation keeps working if the user later goes
  /// offline. Call after the user picks or switches a practicing language.
  /// Errors are swallowed — this is opportunistic prefetching.
  Future<void> ensureModelsDownloaded(
    String sourceCode,
    String targetCode,
  ) async {
    for (final code in [sourceCode, targetCode]) {
      final lang = BCP47Code.fromRawValue(code);
      if (lang == null) continue;
      try {
        if (!await _modelManager.isModelDownloaded(lang.bcpCode)) {
          await _modelManager.downloadModel(lang.bcpCode);
          debugPrint('OfflineTranslationService: downloaded model $code');
        }
      } catch (e) {
        debugPrint('OfflineTranslationService: model download $code — $e');
      }
    }
  }

  /// Translates on-device. Returns null when the pair isn't supported or
  /// the models aren't downloaded yet.
  Future<String?> translate({
    required String text,
    required String sourceCode,
    required String targetCode,
  }) async {
    final source = BCP47Code.fromRawValue(sourceCode);
    final target = BCP47Code.fromRawValue(targetCode);
    if (source == null || target == null) return null;
    if (!await isReadyOffline(sourceCode, targetCode)) return null;

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return await translator.translateText(text);
    } catch (e) {
      debugPrint('OfflineTranslationService: translate failed — $e');
      return null;
    } finally {
      translator.close();
    }
  }
}
