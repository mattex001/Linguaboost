import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/services/tts_service.dart';
import '../../phrasebook/models/phrase.dart';
import '../domain/sm2.dart';

/// One review card: source-language prompt → reveal → self-rate (FR-3.3/3.4).
class ReviewCard extends ConsumerWidget {
  final Phrase phrase;
  final bool revealed;
  final VoidCallback onReveal;
  final ValueChanged<ReviewRating> onRate;

  const ReviewCard({
    super.key,
    required this.phrase,
    required this.revealed,
    required this.onReveal,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(pronunciationPlayerProvider);

    return Column(
      children: [
        // ── Card ──────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderTertiary(context)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'How do you say…',
                style: GoogleFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary(context),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                phrase.sourceText,
                textAlign: TextAlign.center,
                style: GoogleFonts.googleSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (!revealed)
                Text(
                  'Say it out loud, then reveal the answer',
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary(context),
                  ),
                )
              else ...[
                Divider(
                  color: AppColors.borderDisabled(context),
                  thickness: 1,
                ),
                const SizedBox(height: 20),
                Text(
                  phrase.translatedText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chauPhilomeneOne(
                    fontSize: 28,
                    color: AppColors.textPrimary(context),
                    height: 1.2,
                  ),
                ),
                if ((phrase.phonetic ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    phrase.phonetic!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () =>
                      player.speak(phrase.translatedText, phrase.targetLang),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CoolIcons.volume_max,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Actions ───────────────────────────────────────────────────────
        if (!revealed)
          _RevealButton(onTap: onReveal)
        else
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: 'Again',
                  sub: '< 1 day',
                  background: AppColors.backgroundDanger(context),
                  border: AppColors.borderDanger(context),
                  foreground: AppColors.textDanger(context),
                  onTap: () => onRate(ReviewRating.again),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RatingButton(
                  label: 'Hard',
                  sub: 'took a while',
                  background: AppColors.backgroundSecondary(context),
                  border: AppColors.borderSecondary(context),
                  foreground: AppColors.textPrimary(context),
                  onTap: () => onRate(ReviewRating.hard),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RatingButton(
                  label: 'Easy',
                  sub: 'knew it',
                  background: AppColors.brandPrimary,
                  border: AppColors.brandPrimary,
                  foreground: Colors.white,
                  hardShadow: true,
                  onTap: () => onRate(ReviewRating.easy),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RevealButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RevealButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF141413),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 47,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Text(
            'Reveal answer',
            style: GoogleFonts.googleSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sub;
  final Color background;
  final Color border;
  final Color foreground;
  final bool hardShadow;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sub,
    required this.background,
    required this.border,
    required this.foreground,
    required this.onTap,
    this.hardShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: hardShadow
              ? const [
                  BoxShadow(
                    color: Color(0xFF141413),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.googleSans(
                fontSize: 11,
                color: foreground.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
