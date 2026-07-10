import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

class PersonalizationIntroScreen extends ConsumerWidget {
  const PersonalizationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const PersonalizationHeader(),

            // ── "Welcome to LinguaBoost" ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to ',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary(context),
                      height: 19.6 / 14,
                    ),
                  ),
                  const SizedBox(width: 7),
                  SvgPicture.asset(
                    'assets/images/LinguaBoost_logo.svg',
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // ── Illustration ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SvgPicture.asset(
                    'assets/images/People_reading.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ── Bottom: title + subtitle + button ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lets personalize your learning experience',
                    style: AppTextStyles.heading3XLFor(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Pick your language and we'll build a course around the phrases your life actually needs",
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary(context),
                      height: 19.6 / 14,
                    ),
                  ),
                  const SizedBox(height: 37),
                  PersonalizationPrimaryButton(
                    label: 'Continue',
                    onTap: () => context.push(AppRoutes.personalizationName),
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
