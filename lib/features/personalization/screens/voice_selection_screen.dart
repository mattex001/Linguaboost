import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/tts_service.dart';
import '../widgets/personalization_widgets.dart';

/// Onboarding step: pick a voice for the language just chosen.
/// [targetLanguageCode] is the code selected on the previous step, passed
/// via route `extra` so this doesn't have to wait on the profile stream to
/// catch up with what was just saved.
class VoiceSelectionScreen extends ConsumerStatefulWidget {
  final String? targetLanguageCode;

  const VoiceSelectionScreen({super.key, this.targetLanguageCode});

  @override
  ConsumerState<VoiceSelectionScreen> createState() =>
      _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends ConsumerState<VoiceSelectionScreen> {
  String? _languageCode;
  List<VoiceOption>? _voices;
  VoiceOption? _selected;
  VoiceOption? _playing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code =
        widget.targetLanguageCode ?? ref.read(activeLanguageCodeProvider);
    if (code == null) {
      setState(() => _voices = const []);
      return;
    }
    _languageCode = code;

    final player = ref.read(pronunciationPlayerProvider);
    final voices = await player.voicesForLanguage(code);
    if (!mounted) return;
    setState(() => _voices = voices);
  }

  Future<void> _togglePlay(VoiceOption voice) async {
    final player = ref.read(pronunciationPlayerProvider);
    if (_playing == voice) {
      await player.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = voice);
    await player.previewVoice(voice, _languageCode!);
    if (!mounted) return;
    if (_playing == voice) setState(() => _playing = null);
  }

  Future<void> _continue() async {
    final voice = _selected;
    final code = _languageCode;
    if (_saving) return;

    if (voice != null && code != null) {
      setState(() => _saving = true);
      final uid = ref.read(authStateProvider).asData?.value?.id;
      if (uid != null) {
        await ref.read(userRepositoryProvider).updateVoice(
              uid,
              name: voice.name,
              locale: voice.locale,
            );
      }
      if (!mounted) return;
    }
    context.push(AppRoutes.personalizationGoal);
  }

  void _skip() => context.push(AppRoutes.personalizationGoal);

  @override
  Widget build(BuildContext context) {
    final loading = _voices == null;
    final voices = _voices ?? const <VoiceOption>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalizationHeader(),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick a voice',
                            style: GoogleFonts.googleSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap play to hear how each voice sounds',
                            style: GoogleFonts.googleSans(
                              fontSize: 14,
                              color: AppColors.textTertiary(context),
                              height: 19.6 / 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (voices.isEmpty)
                            Text(
                              'Your device only has one voice for this '
                              'language, so there\'s nothing to choose '
                              'from — we\'ll use the default.',
                              style: GoogleFonts.googleSans(
                                fontSize: 14,
                                color: AppColors.textTertiary(context),
                                height: 1.4,
                              ),
                            )
                          else
                            Column(
                              children: voices.map((voice) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: VoiceCard(
                                    name: voice.displayName,
                                    accent: voice.locale,
                                    selected: _selected == voice,
                                    playing: _playing == voice,
                                    onTap: () =>
                                        setState(() => _selected = voice),
                                    onPlay: () => _togglePlay(voice),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                children: [
                  PersonalizationPrimaryButton(
                    label: _saving ? 'Saving…' : 'Continue',
                    enabled: !loading && !_saving,
                    onTap: _continue,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _saving ? null : _skip,
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
