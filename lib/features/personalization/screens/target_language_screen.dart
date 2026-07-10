import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/languages.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

/// The core onboarding step: pick the language you're learning.
class TargetLanguageScreen extends ConsumerStatefulWidget {
  const TargetLanguageScreen({super.key});

  @override
  ConsumerState<TargetLanguageScreen> createState() =>
      _TargetLanguageScreenState();
}

class _TargetLanguageScreenState extends ConsumerState<TargetLanguageScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    final code = _selected;
    if (code == null || _saving) return;

    final uid = ref.read(authStateProvider).asData?.value?.id;
    setState(() => _saving = true);
    try {
      if (uid != null) {
        await ref.read(userRepositoryProvider).updateTargetLanguage(uid, code);
      }
      if (!mounted) return;
      context.push(AppRoutes.personalizationVoice, extra: code);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your choice. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalizationHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which language do you want to learn?',
                      style: GoogleFonts.googleSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every phrase you translate becomes part of your personal course',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textTertiary(context),
                        height: 19.6 / 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: kTargetLanguages.map((language) {
                        final selected = _selected == language.code;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LanguageRow(
                            language: language,
                            selected: selected,
                            onTap: () =>
                                setState(() => _selected = language.code),
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
              child: PersonalizationPrimaryButton(
                label: _saving ? 'Saving…' : 'Continue',
                enabled: _selected != null && !_saving,
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final TargetLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.label,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    language.nativeLabel,
                    style: GoogleFonts.googleSans(
                      fontSize: 12,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PersonalizationRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}
