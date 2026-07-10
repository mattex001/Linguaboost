import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/languages.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glow_mic_button.dart';
import '../../../shared/widgets/language_switcher_sheet.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../phrasebook/widgets/language_switch_action.dart';
import '../../phrasebook/widgets/phrase_detail_sheet.dart';
import '../providers/translate_provider.dart';
import '../repositories/translate_repository.dart';

/// Translate tab: type / paste / speak an English sentence, get the natural
/// translation + explanation, auto-saved to the phrasebook (FR-1.x, FR-2.1).
class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _inputController = TextEditingController();
  bool _hasText = false;
  String? _error;

  /// Hands-free pipeline: mic-initiated capture auto-translates when the
  /// speaker goes quiet and auto-plays the translation.
  bool _autoVoice = false;

  /// True while the record button is physically held. Guards the first-use
  /// race where the mic-permission dialog appears mid-hold: the user lifts
  /// their finger to tap "Allow", and without this check capture would then
  /// start with nobody holding the button (nothing would ever stop it).
  bool _holdActive = false;

  /// When the current capture began — used to enforce a minimum recording
  /// window, since stopping Android's recognizer before it has finished
  /// starting throws ERROR_CLIENT (the "quick tap" failure).
  DateTime? _captureStartedAt;

  /// Auto-restarts consumed during the current hold. Android's recognizer
  /// gives up on its own (speech timeout / no match) regardless of the
  /// pause setting; while the finger is still down we quietly restart it,
  /// but bounded, so a broken recognizer can't loop forever.
  int _holdRestarts = 0;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceCapture({bool holdMode = false}) async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone access is needed for voice input'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // The permission dialog may have interrupted the hold — don't start a
    // capture nobody is holding.
    if (holdMode && !_holdActive) return;
    final user = ref.read(userSnapshotProvider);
    final sourceLanguage =
        targetLanguageForCode(user?.sourceLanguage ?? 'en') ??
        kTargetLanguages.last;
    _autoVoice = true;
    _inputController.clear();
    _captureStartedAt = DateTime.now();
    await ref.read(speechInputProvider.notifier).start(
          localeId: sourceLanguage.ttsLocale.replaceAll('-', '_'),
          // Push-to-talk: release is the stop signal, so a mid-sentence
          // pause must not auto-stop the capture. Hands-free keeps the
          // short silence timeout.
          pauseFor: holdMode
              ? const Duration(seconds: 30)
              : const Duration(milliseconds: 1100),
        );
  }

  Future<void> _updateSourceLanguage(String code) async {
    final uid = ref.read(authUserIdProvider);
    if (uid == null) return;
    await ref.read(userRepositoryProvider).updateSourceLanguage(uid, code);
  }

  Future<void> _swapLanguages({
    required String currentSourceCode,
    required String currentTargetCode,
  }) async {
    final uid = ref.read(authUserIdProvider);
    if (uid == null) return;
    await ref
        .read(userRepositoryProvider)
        .swapLanguages(
          uid,
          newSourceCode: currentTargetCode,
          newTargetCode: currentSourceCode,
        );
  }

  // Press-and-hold record gesture: press down starts listening, release
  // stops it — auto-translate is still driven by the `ref.listen` block
  // below reacting to `listening` flipping false.
  Future<void> _onRecordPressStart() async {
    _holdActive = true;
    _holdRestarts = 0;
    if (ref.read(speechInputProvider).listening) return;
    await _startVoiceCapture(holdMode: true);
  }

  Future<void> _onRecordPressEnd() async {
    _holdActive = false;
    if (!ref.read(speechInputProvider).listening) return;

    // Stopping Android's recognizer before it has fully started throws
    // ERROR_CLIENT (quick taps). Let very short captures run out a minimum
    // window before stopping.
    const minWindow = Duration(milliseconds: 900);
    final startedAt = _captureStartedAt;
    final elapsed = startedAt == null
        ? minWindow
        : DateTime.now().difference(startedAt);
    if (elapsed < minWindow) {
      await Future.delayed(minWindow - elapsed);
      if (!mounted || _holdActive) return; // re-pressed meanwhile
      if (!ref.read(speechInputProvider).listening) return;
    }
    await ref.read(speechInputProvider.notifier).stop();
  }

  Future<void> _translate({bool speakResult = false}) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userSnapshotProvider);
    final targetLang = user?.targetLanguage ?? kTargetLanguages.first.code;
    final sourceLang = user?.sourceLanguage ?? 'en';

    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    await ref.read(speechInputProvider.notifier).stop();

    try {
      final phrase = await ref
          .read(translateControllerProvider.notifier)
          .translate(
            text: text,
            targetLang: targetLang,
            sourceLang: sourceLang,
          );

      // Streak: translating counts as today's learning action
      ref.read(dailyProgressProvider.notifier).recordLearningAction();

      if (!mounted) return;
      _inputController.clear();
      if (speakResult) {
        // Voice flow: hear the translation immediately.
        ref
            .read(pronunciationPlayerProvider)
            .speak(phrase.translatedText, phrase.targetLang);
      } else {
        // Typed flow: warm the audio while the sheet opens so the play
        // button responds instantly. (Voice flow's speak() already caches.)
        ref
            .read(pronunciationPlayerProvider)
            .prefetch(phrase.translatedText, phrase.targetLang);
      }
      PhraseDetailSheet.show(context, phrase: phrase);
    } on TranslationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Translation failed. Check your connection and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final translateState = ref.watch(translateControllerProvider);
    final speech = ref.watch(speechInputProvider);
    final user = ref.watch(userSnapshotProvider);
    final language =
        targetLanguageForCode(user?.targetLanguage) ?? kTargetLanguages.first;
    final sourceLanguage =
        targetLanguageForCode(user?.sourceLanguage ?? 'en') ??
        kTargetLanguages.last;
    final loading = translateState.isLoading;

    // Home-tab mic handoff: start hands-free capture as soon as this tab
    // becomes active with a pending request.
    ref.listen<bool>(voiceCaptureRequestProvider, (prev, requested) {
      if (requested) {
        ref.read(voiceCaptureRequestProvider.notifier).consume();
        _startVoiceCapture();
      }
    });
    // Consume a request that was already set before this widget first built.
    if (ref.read(voiceCaptureRequestProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(voiceCaptureRequestProvider.notifier).consume();
        _startVoiceCapture();
      });
    }

    // Live speech transcript fills the input field; when listening ends in
    // hands-free mode, translation starts automatically and the result is
    // spoken aloud (FR: speak → translate → play).
    ref.listen<SpeechInputState>(speechInputProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        // Android's recognizer routinely bails on its own: speech_timeout
        // (~5s of silence, regardless of our pause setting), no_match
        // (heard nothing usable), client/busy (stopped mid-startup or
        // restarted too fast). None of these deserve a raw error code.
        final err = next.errorMessage!.toLowerCase();
        final transient = err.contains('speech_timeout') ||
            err.contains('no_match') ||
            err.contains('client') ||
            err.contains('busy');
        if (transient) {
          if (_holdActive && _holdRestarts < 2) {
            // Finger still down — quietly restart the capture. Brief delay:
            // an immediate re-listen after an error reports error_busy.
            _holdRestarts++;
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _holdActive) _startVoiceCapture(holdMode: true);
            });
          } else if (!_holdActive && next.transcript.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Didn't catch that — hold the mic, speak, then release."),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice input error: ${next.errorMessage}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      if (next.listening && next.transcript.isNotEmpty) {
        _inputController.text = next.transcript;
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
      final stoppedListening = (prev?.listening ?? false) && !next.listening;
      if (stoppedListening && _autoVoice) {
        _autoVoice = false;
        // speech_to_text's stop() only awaits the platform ack that
        // recording stopped — the true final transcript (which can still
        // differ from the last partial) lands a beat later via onResult.
        // A short grace delay lets it settle before we read the transcript
        // and translate, instead of racing a possibly-stale partial.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          final transcript = ref.read(speechInputProvider).transcript.trim();
          if (transcript.isNotEmpty && !ref.read(translateControllerProvider).isLoading) {
            _inputController.text = transcript;
            _translate(speakResult: true);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Translate',
                    style: GoogleFonts.chauPhilomeneOne(
                      fontSize: 28,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  LanguagePill(
                    code: language.code,
                    onTap: () => showLanguageSwitcherSheet(
                      context,
                      currentCode: language.code,
                      onSelect: (code) =>
                          switchActiveLanguage(context, ref, code),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Say it the way a local would',
                style: GoogleFonts.googleSans(
                  fontSize: 13,
                  color: AppColors.textTertiary(context),
                ),
              ),

              const SizedBox(height: 20),

              // ── Input card ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: speech.listening
                        ? AppColors.brandPrimary
                        : AppColors.borderTertiary(context),
                    width: speech.listening ? 1.5 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _inputController,
                      maxLines: 7,
                      minLines: 5,
                      maxLength: AppConstants.maxTranslationInputChars,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.googleSans(
                        fontSize: 19,
                        color: AppColors.textPrimary(context),
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Type or paste what you need to say in ${sourceLanguage.label}…',
                        hintStyle: GoogleFonts.googleSans(
                          fontSize: 19,
                          color: AppColors.textTertiary(context),
                        ),
                        counterText: '',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          28,
                        ),
                      ),
                    ),

                    // ── Character counter ─────────────────────────────────
                    Positioned(
                      right: 16,
                      bottom: 10,
                      child: Text(
                        '${_inputController.text.characters.length}/${AppConstants.maxTranslationInputChars}',
                        style: GoogleFonts.googleSans(
                          fontSize: 12,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Translate CTA ───────────────────────────────────────
              loading
                  ? const _TranslatingIndicator()
                  : AppPrimaryButton(
                      label: 'Translate',
                      enabled: _hasText,
                      onTap: _translate,
                    ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    color: AppColors.textDanger(context),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Hint card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Every phrase becomes a lesson',
                      style: GoogleFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Whatever you translate is saved to your phrasebook and '
                      'scheduled for review — so the sentences you actually '
                      'need are the ones you remember.',
                      style: GoogleFonts.googleSans(
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Mic button ───────────────────────────────────────────────
              Center(
                child: GlowMicButton(
                  listening: speech.listening,
                  onTap: null,
                  growOnPress: true,
                  onHoldStart: loading ? null : _onRecordPressStart,
                  onHoldEnd: loading ? null : _onRecordPressEnd,
                  size: 56,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: speech.listening
                    ? Text(
                            'Listening… release to translate',
                            style: GoogleFonts.googleSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandPrimary,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 600.ms)
                    : Text(
                        'Hold to speak',
                        style: GoogleFonts.googleSans(
                          fontSize: 13,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // ── Source ⇄ target language swap ─────────────────────────
              Center(
                child: _LanguageSwapBar(
                  source: sourceLanguage,
                  target: language,
                  onTapSource: () => showLanguageSwitcherSheet(
                    context,
                    currentCode: sourceLanguage.code,
                    onSelect: _updateSourceLanguage,
                  ),
                  onTapTarget: () => showLanguageSwitcherSheet(
                    context,
                    currentCode: language.code,
                    onSelect: (code) =>
                        switchActiveLanguage(context, ref, code),
                  ),
                  onSwap: () => _swapLanguages(
                    currentSourceCode: sourceLanguage.code,
                    currentTargetCode: language.code,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source ⇄ target language swap bar ─────────────────────────────────────────

class _LanguageSwapBar extends StatelessWidget {
  final TargetLanguage source;
  final TargetLanguage target;
  final VoidCallback onTapSource;
  final VoidCallback onTapTarget;
  final VoidCallback onSwap;

  const _LanguageSwapBar({
    required this.source,
    required this.target,
    required this.onTapSource,
    required this.onTapTarget,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSecondary(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageChip(language: source, onTap: onTapSource),
          GestureDetector(
            onTap: onSwap,
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz,
                size: 18,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
          _LanguageChip(language: target, onTap: onTapTarget),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final TargetLanguage language;
  final VoidCallback onTap;

  const _LanguageChip({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              language.label,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslatingIndicator extends StatelessWidget {
  const _TranslatingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 47,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Translating…',
            style: GoogleFonts.googleSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
