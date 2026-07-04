import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../shared/widgets/app_button.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/review_card.dart';

/// Review tab: spaced-repetition session over the user's own phrases
/// (FR-3.x). Sessions are exit-safe — every rating is persisted immediately.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(reviewSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        bottom: false,
        child: session.active
            ? const _SessionView()
            : session.finished
                ? const _DoneView()
                : const _IdleView(),
      ),
    );
  }
}

// ── Idle: due count + start ───────────────────────────────────────────────────

class _IdleView extends ConsumerWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueCountProvider);
    final caughtUp = dueCount == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: GoogleFonts.chauPhilomeneOne(
              fontSize: 28,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Only the phrases you\'re at risk of forgetting',
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: AppColors.textTertiary(context),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dueCount',
                    style: GoogleFonts.chauPhilomeneOne(
                      fontSize: 72,
                      color: caughtUp
                          ? AppColors.textTertiary(context)
                          : AppColors.brandPrimary,
                      height: 1,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 8),
                  Text(
                    caughtUp
                        ? 'All caught up 🎉'
                        : dueCount == 1
                            ? 'phrase due today'
                            : 'phrases due today',
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caughtUp
                        ? 'Translate something new and it will show up here for review.'
                        : 'A few minutes now keeps them in memory for good.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      color: AppColors.textTertiary(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (caughtUp)
                    SizedBox(
                      width: 220,
                      child: AppPrimaryButton(
                        label: 'Translate a phrase',
                        onTap: () => ref
                            .read(activeNavTabProvider.notifier)
                            .setTab(1),
                      ),
                    )
                  else
                    SizedBox(
                      width: 220,
                      child: AppPrimaryButton(
                        label: 'Start review',
                        onTap: () =>
                            ref.read(reviewSessionProvider.notifier).start(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active session ────────────────────────────────────────────────────────────

class _SessionView extends ConsumerWidget {
  const _SessionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(reviewSessionProvider);
    final phrase = session.current;
    if (phrase == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
      child: Column(
        children: [
          // ── Session header ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => ref.read(reviewSessionProvider.notifier).exit(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundPrimary(context),
                    border: Border.all(
                      color: AppColors.borderSecondary(context),
                    ),
                  ),
                  child: Icon(
                    CoolIcons.close_md,
                    size: 20,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${session.index + 1}',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${session.queue.length}',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),

          const SizedBox(height: 12),

          // ── Progress bar ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: session.queue.isEmpty
                  ? 0
                  : session.index / session.queue.length,
              minHeight: 6,
              backgroundColor: AppColors.backgroundPrimary(context),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.brandPrimary),
            ),
          ),

          const SizedBox(height: 28),

          Expanded(
            child: SingleChildScrollView(
              child: ReviewCard(
                key: ValueKey('${phrase.id}-${session.index}'),
                phrase: phrase,
                revealed: session.revealed,
                onReveal: () =>
                    ref.read(reviewSessionProvider.notifier).reveal(),
                onRate: (rating) =>
                    ref.read(reviewSessionProvider.notifier).rate(rating),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

class _DoneView extends ConsumerWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(reviewSessionProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52))
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Review complete!',
              style: GoogleFonts.googleSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed ${session.completed} '
              '${session.completed == 1 ? 'card' : 'cards'}. '
              'They\'ll come back right when you need them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textTertiary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: AppPrimaryButton(
                label: 'Back to Home',
                onTap: () {
                  ref.read(reviewSessionProvider.notifier).exit();
                  ref.read(activeNavTabProvider.notifier).setTab(0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
