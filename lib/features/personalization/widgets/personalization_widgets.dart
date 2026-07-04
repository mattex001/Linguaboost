import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';

// ── Primary button (purple with hard drop shadow) ─────────────────────────────

class PersonalizationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const PersonalizationPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.31,
      child: DecoratedBox(
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
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brandPrimary,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header row: chevron-left back button + Skip text ─────────────────────────

class PersonalizationHeader extends StatelessWidget {
  const PersonalizationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.onboarding);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    CoolIcons.chevron_left,
                    size: 28,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await LocalStorageService.instance.setOnboardingComplete();
                if (context.mounted) context.go(AppRoutes.dashboard);
              },
              child: Text(
                'Skip',
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radio indicator ───────────────────────────────────────────────────────────

class PersonalizationRadio extends StatelessWidget {
  final bool selected;

  const PersonalizationRadio({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Colors.white
                  : AppColors.borderTertiary(context),
              width: 2,
            ),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ── Full-width option row (list layout) ───────────────────────────────────────

class PersonalizationOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PersonalizationOptionRow({
    super.key,
    required this.label,
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
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
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

// ── Inline chip option (wrap layout, auto-width) ──────────────────────────────

class PersonalizationOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PersonalizationOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            PersonalizationRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}

// ── Filled chip (wrap layout, topic selection) ────────────────────────────────

class PersonalizationCheckboxChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PersonalizationCheckboxChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

// ── Full-width word row (word test — checkbox style) ──────────────────────────

class WordTestRow extends StatelessWidget {
  final String word;
  final bool selected;
  final VoidCallback onTap;

  const WordTestRow({
    super.key,
    required this.word,
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
            Expanded(
              child: Text(
                word,
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : const Color(0x8073726C),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? Icon(CoolIcons.check,
                      color: AppColors.brandPrimary, size: 11)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice waveform painter ────────────────────────────────────────────────────

class VoiceWaveform extends StatelessWidget {
  final bool active;
  const VoiceWaveform({super.key, this.active = false});

  static const _heights = [
    4.0, 7.0, 11.0, 6.0, 13.0, 8.0, 5.0, 10.0, 7.0,
    12.0, 5.0, 9.0, 4.0, 8.0, 11.0,
  ];

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFFBBB8B0);
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_heights.length, (i) {
          final bar = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 2.5,
              height: _heights[i],
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
          if (!active) return bar;
          // Animate each bar up/down with staggered phase when playing
          return bar
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
                delay: Duration(milliseconds: i * 60),
              )
              .moveY(
                begin: _heights[i] * 0.3,
                end: -(_heights[i] * 0.3),
                duration: 500.ms,
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }
}

// ── Voice card (voice preference) ─────────────────────────────────────────────

class VoiceCard extends StatelessWidget {
  final String name;
  final String accent;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const VoiceCard({
    super.key,
    required this.name,
    required this.accent,
    required this.selected,
    required this.onTap,
    required this.onPlay,
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.backgroundTertiary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.brandPrimary
                : AppColors.borderDisabled(context),
          ),
        ),
        child: Row(
          children: [
            // Fixed-width name + accent column keeps waveform aligned across all cards
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accent,
                    style: GoogleFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),
            // Waveform — centred in remaining space
            Expanded(
              child: Center(child: VoiceWaveform(active: playing)),
            ),
            const SizedBox(width: 12),
            // Play / stop button
            GestureDetector(
              onTap: onPlay,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.backgroundSecondary(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  playing ? CoolIcons.stop : CoolIcons.play,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Radio
            PersonalizationRadio(selected: selected),
          ],
        ),
      ),
    );
  }
}
