import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

/// First onboarding question: what should we call you? Optional — the app
/// falls back to the user's email prefix if left blank (see
/// displayNameProvider), so this doesn't block progress.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      final uid = ref.read(authStateProvider).asData?.value?.id;
      if (uid != null) {
        // Fire-and-forget — optional field, not load-bearing for onboarding.
        ref.read(userRepositoryProvider).updateName(uid, name);
      }
    }
    context.push(AppRoutes.personalizationLanguage);
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
                      'What should we call you?',
                      style: GoogleFonts.googleSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We\'ll use this to personalize your experience',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textTertiary(context),
                        height: 19.6 / 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundPrimary(context),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.borderSecondary(context)),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        // Without this, iOS draws its own AutoFill/QuickType
                        // suggestion overlay directly on top of the field —
                        // looks like a second stacked input box.
                        autofillHints: const [],
                        style: GoogleFonts.googleSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary(context),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.googleSans(
                            fontSize: 16,
                            color: AppColors.textGhost(context),
                          ),
                        ),
                        onSubmitted: (_) => _continue(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: PersonalizationPrimaryButton(
                label: 'Continue',
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
