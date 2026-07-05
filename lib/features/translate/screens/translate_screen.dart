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
import '../../dashboard/providers/dashboard_provider.dart';
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

  Future<void> _startVoiceCapture() async {
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
    _autoVoice = true;
    _inputController.clear();
    await ref.read(speechInputProvider.notifier).start();
  }

  Future<void> _toggleMic() async {
    final speech = ref.read(speechInputProvider);
    if (speech.listening) {
      // Manual stop still flows into auto-translate via the listener.
      await ref.read(speechInputProvider.notifier).stop();
      return;
    }
    await _startVoiceCapture();
  }

  Future<void> _translate({bool speakResult = false}) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userSnapshotProvider);
    final targetLang = user?.targetLanguage ?? kTargetLanguages.first.code;

    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    await ref.read(speechInputProvider.notifier).stop();

    try {
      final phrase = await ref
          .read(translateControllerProvider.notifier)
          .translate(text: text, targetLang: targetLang);

      // Streak: translating counts as today's learning action
      ref.read(dailyProgressProvider.notifier).recordLearningAction();

      if (!mounted) return;
      _inputController.clear();
      if (speakResult) {
        // Voice flow: hear the translation immediately.
        ref
            .read(pronunciationPlayerProvider)
            .speak(phrase.translatedText, phrase.targetLang);
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
      if (next.listening && next.transcript.isNotEmpty) {
        _inputController.text = next.transcript;
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
      final stoppedListening = (prev?.listening ?? false) && !next.listening;
      if (stoppedListening && _autoVoice) {
        _autoVoice = false;
        if (next.transcript.trim().isNotEmpty && !loading) {
          _inputController.text = next.transcript;
          _translate(speakResult: true);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundPrimary(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.borderSecondary(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                language.flag,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                language.label,
                                style: GoogleFonts.googleSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _inputController,
                            maxLines: 5,
                            minLines: 3,
                            maxLength: AppConstants.maxTranslationInputChars,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.googleSans(
                              fontSize: 16,
                              color: AppColors.textPrimary(context),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Type or paste what you need to say in English…',
                              hintStyle: GoogleFonts.googleSans(
                                fontSize: 15,
                                color: AppColors.textTertiary(context),
                              ),
                              counterText: '',
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                4,
                              ),
                            ),
                          ),

                          // ── Status row ─────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                if (speech.listening)
                                  Expanded(
                                    child:
                                        Text(
                                              'Listening…',
                                              style: GoogleFonts.googleSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.brandPrimary,
                                              ),
                                            )
                                            .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true),
                                            )
                                            .fadeIn(duration: 600.ms),
                                  )
                                else
                                  Expanded(
                                    child: Text(
                                      'Tap the mic to speak',
                                      style: GoogleFonts.googleSans(
                                        fontSize: 13,
                                        color: AppColors.textTertiary(context),
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${_inputController.text.characters.length}/${AppConstants.maxTranslationInputChars}',
                                  style: GoogleFonts.googleSans(
                                    fontSize: 12,
                                    color: AppColors.textTertiary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Mic button ─────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: GlowMicButton(
                                listening: speech.listening,
                                onTap: loading ? null : _toggleMic,
                                size: 56,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  ],
                ),
              ),
            ),

            // ── Translate CTA (pinned to bottom) ─────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: loading
                  ? const _TranslatingIndicator()
                  : AppPrimaryButton(
                      label: 'Translate',
                      enabled: _hasText,
                      onTap: _translate,
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
