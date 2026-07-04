import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';

class NotificationPromptScreen extends StatefulWidget {
  const NotificationPromptScreen({super.key});

  @override
  State<NotificationPromptScreen> createState() =>
      _NotificationPromptScreenState();
}

class _NotificationPromptScreenState extends State<NotificationPromptScreen> {
  Future<void> _onAllow() async {
    final router = GoRouter.of(context);
    await Permission.notification.request();
    await _markPromptShown();
    if (!mounted) return;
    router.pop();
  }

  Future<void> _onMaybeLater() async {
    final router = GoRouter.of(context);
    final skip = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SkipConfirmSheet(),
    );
    if (skip == true && mounted) {
      await _markPromptShown();
      if (!mounted) return;
      router.pop();
    }
  }

  Future<void> _markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_prompt_shown', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Title ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Get notified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // ── Progress indicator ─────────────────────────────────────────
            const _StepProgress(steps: 3, activeCount: 2),

            const SizedBox(height: 36),

            // ── Illustration ───────────────────────────────────────────────
            const _NotificationIllustration(),

            const SizedBox(height: 36),

            // ── Heading ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'Be the first to know.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Receive important updates about your\naccount, new features, and limited offers.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),

            // ── Info banner ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInfoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.textInfoLight, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can customize your preferences later.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textInfoLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Buttons ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  AppPrimaryButton(
                    label: 'Allow notifications',
                    onTap: _onAllow,
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryButton(
                    label: 'Maybe later',
                    onTap: _onMaybeLater,
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

// ── Step progress indicator ───────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int steps;
  final int activeCount;

  const _StepProgress({required this.steps, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps, (i) {
        final active = i < activeCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? AppColors.textPrimaryLight
                : const Color(0xFFE0DED8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ── Notification illustration ─────────────────────────────────────────────────

class _NotificationIllustration extends StatelessWidget {
  const _NotificationIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Circle background
          Positioned(
            top: 14,
            child: Container(
              width: 210,
              height: 210,
              decoration: const BoxDecoration(
                color: Color(0xFFB8B0A0),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Card 1 — top (slightly behind)
          Positioned(
            top: 24,
            child: _MockNotifCard(
              title: 'Phrases due for review',
              time: '9:41 AM',
              highlighted: false,
            ),
          ),

          // Card 2 — middle (highlighted/selected)
          Positioned(
            top: 80,
            child: _MockNotifCard(
              title: 'Time to review! 📖',
              time: '10:52 AM',
              highlighted: true,
            ),
          ),

          // Card 3 — bottom
          Positioned(
            top: 136,
            child: _MockNotifCard(
              title: "Don't break your streak 🔥",
              time: '9:41 AM',
              highlighted: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockNotifCard extends StatelessWidget {
  final String title;
  final String time;
  final bool highlighted;

  const _MockNotifCard({
    required this.title,
    required this.time,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF0EFF9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: highlighted
            ? Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          // App icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                'LB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Placeholder body lines
                Container(
                  height: 6,
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E0DA),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E0DA),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skip confirm bottom sheet ─────────────────────────────────────────────────

class _SkipConfirmSheet extends StatelessWidget {
  const _SkipConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD1CFC7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Dark teal illustration ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A5E57), Color(0xFF1A3E3A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Soft wave decoration
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: -40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Centered notification card
                  Center(
                    child: Container(
                      width: 290,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'LB',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Time to review! 📖',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      '10:30 PM',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.textTertiaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your phrases are ready for review.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Heading ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Are you sure?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // ── Body ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You could miss your daily review reminder or a streak-saving nudge.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // ── Buttons ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
            child: Column(
              children: [
                AppPrimaryButton(
                  label: 'No, enable notifications',
                  onTap: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: 'Yes, skip',
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

