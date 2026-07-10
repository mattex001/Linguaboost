import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glow_mic_button.dart';
import '../../phrasebook/providers/phrasebook_provider.dart';
import '../../phrasebook/screens/phrasebook_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../review/providers/review_provider.dart';
import '../../review/screens/review_screen.dart';
import '../../translate/screens/translate_screen.dart';
import '../providers/dashboard_provider.dart';

import 'home_themes_screen.dart' show kBgThemeAssets;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(dailyProgressProvider, (prev, next) {
      if (next.streakJustCompleted && !(prev?.streakJustCompleted ?? false)) {
        _showStreakSuccess();
      }
    });

    final activeTab = ref.watch(activeNavTabProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: activeTab,
              children: [
                _HomeTab(),
                const TranslateScreen(),
                const ReviewScreen(),
                const PhrasebookScreen(),
                const ProfileScreen(),
              ],
            ),
          ),
          const _BottomNav(),
        ],
      ),
    );
  }

  void _showStreakSuccess() {
    final user = ref.read(userSnapshotProvider);
    final streak = (user?.streak ?? 0) + 1;
    final weekActivity = ref.read(weekActivityProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StreakSuccessModal(
        streak: streak,
        weekActivity: weekActivity,
        onDismiss: () {
          ref.read(dailyProgressProvider.notifier).dismissStreakModal();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Tab widgets ───────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
  }

  Future<void> _maybeShowPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('notification_prompt_shown') ?? false;
    if (alreadyShown) return;

    final status = await Permission.notification.status;
    if (status.isGranted) return;

    if (!mounted) return;
    context.push(AppRoutes.notificationPrompt);
  }

  @override
  Widget build(BuildContext context) {
    final bgIndex = ref.watch(backgroundThemeProvider);
    final hasBackground = bgIndex >= 0 && bgIndex < kBgThemeAssets.length;

    return Stack(
      children: [
        if (hasBackground)
          Positioned.fill(
            child: Image.asset(kBgThemeAssets[bgIndex], fit: BoxFit.cover),
          ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _NavBar(ref: ref, immersive: hasBackground),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.brandPrimary,
                  onRefresh: () => refreshAppData(ref),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        _PromoBanner(immersive: hasBackground),
                        const SizedBox(height: 24),
                        _QuickCaptureCard(immersive: hasBackground),
                        const SizedBox(height: 16),
                        _ReviewCtaCard(immersive: hasBackground),
                        const SizedBox(height: 24),
                        const _StreakCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Nav bar ───────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final WidgetRef ref;
  final bool immersive;
  const _NavBar({required this.ref, required this.immersive});

  @override
  Widget build(BuildContext context) {
    // The profile stream hasn't delivered its first snapshot yet — showing
    // the "there" fallback here would flash a wrong name for a beat before
    // snapping to the real one, so hold an empty placeholder instead.
    final nameReady = ref.watch(currentUserProvider).hasValue ||
        ref.watch(userSnapshotProvider) != null;
    final name = ref.watch(displayNameProvider);
    final user = ref.watch(userSnapshotProvider);
    final textColor = immersive ? Colors.white : AppColors.textPrimary(context);

    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AvatarNavButton(
              user: user,
              onTap: () => ref.read(activeNavTabProvider.notifier).setTab(4),
            ),
            Text(
              nameReady ? 'Hello $name' : '',
              style: GoogleFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            _NavCircleButton(
              icon: CoolIcons.settings_future,
              onTap: () => context.push(AppRoutes.homeThemes),
              immersive: immersive,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarNavButton extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onTap;
  const _AvatarNavButton({required this.user, required this.onTap});

  String get _initials {
    final src = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : (user?.email ?? '').split('@').first;
    if (src.isEmpty) return '?';
    final parts = src.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return src.length > 1
        ? '${src[0]}${src[1]}'.toUpperCase()
        : src[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.brandPrimary,
              AppColors.brandPrimary.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _initials,
            style: GoogleFonts.chauPhilomeneOne(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool immersive;
  const _NavCircleButton({
    required this.icon,
    required this.onTap,
    required this.immersive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: immersive
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.backgroundPrimary(context),
          border: Border.all(
            color: immersive
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.borderSecondary(context),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: immersive ? Colors.white : AppColors.textPrimary(context),
        ),
      ),
    );
  }
}

// ── Promo banner ──────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  final bool immersive;
  const _PromoBanner({required this.immersive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.paywall),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: immersive
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.backgroundPrimary(context),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: immersive
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppColors.textGhost(context),
            ),
          ),
          child: Center(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: immersive ? Colors.white : AppColors.textPrimary(context),
                ),
                children: [
                  const TextSpan(text: 'Limited time offer!  '),
                  TextSpan(
                    text: 'Get 30% off',
                    style: GoogleFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: immersive
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick capture card (speak → translate → hear it) ─────────────────────────

class _QuickCaptureCard extends ConsumerWidget {
  final bool immersive;
  const _QuickCaptureCard({required this.immersive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        immersive ? Colors.white : AppColors.textPrimary(context);
    final textTertiary = immersive
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textTertiary(context);

    void goVoice() {
      ref.read(voiceCaptureRequestProvider.notifier).request();
      ref.read(activeNavTabProvider.notifier).setTab(1);
    }

    void goType() => ref.read(activeNavTabProvider.notifier).setTab(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: immersive
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: immersive
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.borderTertiary(context),
          ),
          boxShadow: immersive
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Mic button — tap, speak, and hear the translation
            GlowMicButton(listening: false, onTap: goVoice, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What do you need to say?',
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap the mic, speak, and hear it in your language',
                    style: GoogleFonts.googleSans(
                      fontSize: 12,
                      color: textTertiary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: goType,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CoolIcons.edit_pencil_01,
                          size: 14,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Type instead',
                          style: GoogleFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
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

// ── Review CTA card (PRD §7: due count front and centre) ─────────────────────

class _ReviewCtaCard extends ConsumerWidget {
  final bool immersive;
  const _ReviewCtaCard({required this.immersive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Until the phrasebook has data, dueCount and phrasesSaved both read as
    // 0 — rendering that would flash "All caught up" / "0 phrases" before
    // snapping to the real numbers a beat later. Data counts as ready from
    // the live stream, a stream error (offline — the disk cache serves the
    // snapshot), or a non-empty cached snapshot while still connecting.
    final phrasesAsync = ref.watch(phrasesStreamProvider);
    final ready = phrasesAsync.hasValue ||
        phrasesAsync.hasError ||
        ref.watch(phrasesSnapshotProvider).isNotEmpty;
    final dueCount = ref.watch(reviewsRemainingTodayProvider);
    final phrasesSaved = ref.watch(phrasesSavedCountProvider);
    final caughtUp = dueCount == 0;

    final textPrimary =
        immersive ? Colors.white : AppColors.textPrimary(context);
    final textTertiary = immersive
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textTertiary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        decoration: BoxDecoration(
          color: immersive
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: immersive
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.borderTertiary(context),
          ),
          boxShadow: immersive
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: !ready
            ? const _ReviewCtaCardSkeleton()
            : Column(
          children: [
            Text(
              caughtUp ? 'All caught up 🎉' : 'Ready when you are',
              style: GoogleFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: immersive
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textWarning(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$dueCount',
              style: GoogleFonts.chauPhilomeneOne(
                fontSize: 52,
                color: caughtUp ? textTertiary : AppColors.brandPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dueCount == 1 ? 'phrase due today' : 'phrases due today',
              style: GoogleFonts.googleSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phrasesSaved == 1
                  ? '1 phrase in your phrasebook'
                  : '$phrasesSaved phrases in your phrasebook',
              style: GoogleFonts.googleSans(
                fontSize: 12,
                color: textTertiary,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => ref
                  .read(activeNavTabProvider.notifier)
                  .setTab(caughtUp ? 1 : 2),
              child: Container(
                width: 179,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF141413),
                      blurRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    caughtUp ? 'Translate a phrase' : 'Review now',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown while the phrasebook stream hasn't delivered its first
/// snapshot — same footprint as the real content so the card doesn't jump.
class _ReviewCtaCardSkeleton extends StatelessWidget {
  const _ReviewCtaCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.borderTertiary(context),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Column(
      children: [
        bar(130, 14),
        const SizedBox(height: 12),
        SizedBox(
          width: 64,
          height: 52,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        bar(140, 15),
        const SizedBox(height: 6),
        bar(170, 12),
        const SizedBox(height: 22),
        Container(
          width: 179,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.borderTertiary(context),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hold blank stat values until each underlying stream has delivered its
    // first snapshot, rather than flashing 0 and then the real number.
    final userReady = ref.watch(currentUserProvider).hasValue ||
        ref.watch(userSnapshotProvider) != null;
    final phrasesAsync = ref.watch(phrasesStreamProvider);
    final phrasesReady = phrasesAsync.hasValue ||
        phrasesAsync.hasError ||
        ref.watch(phrasesSnapshotProvider).isNotEmpty;

    final user = ref.watch(userSnapshotProvider);
    final weekActivity = ref.watch(weekActivityProvider);

    final streak = user?.streak ?? 0;
    final phrases = ref.watch(phrasesSavedCountProvider);
    final due = ref.watch(reviewsRemainingTodayProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderTertiary(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Stats row ──────────────────────────────────────────────────
            Row(
              children: [
                // Flame + label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/flame.svg',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Your streak',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                        height: 1.79,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),
                _VerticalDivider(),
                const SizedBox(width: 12),

                Expanded(
                  child: _StatColumn(
                    label: 'Day',
                    value: userReady ? '$streak' : '',
                  ),
                ),

                _VerticalDivider(),

                Expanded(
                  child: _StatColumn(
                    label: 'Phrases',
                    value: phrasesReady ? '$phrases' : '',
                  ),
                ),

                _VerticalDivider(),

                Expanded(
                  child: _StatColumn(
                    label: 'Due',
                    value: phrasesReady ? '$due' : '',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: AppColors.borderDisabled(context), thickness: 1),
            const SizedBox(height: 20),

            // ── Weekday row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildWeekdays(context, weekActivity),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekdays(BuildContext context, List<bool> activity) {
    const labels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return List.generate(7, (i) {
      final done = i < activity.length && activity[i];
      return Column(
        children: [
          Text(
            labels[i],
            style: GoogleFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary(context),
              height: 1.40,
            ),
          ),
          const SizedBox(height: 12),
          _DayCheck(done: done),
        ],
      );
    });
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.googleSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary(context),
            height: 1.40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.googleSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 58,
      color: AppColors.borderDisabled(context),
    );
  }
}

class _DayCheck extends StatelessWidget {
  final bool done;
  const _DayCheck({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.brandPrimary : Colors.transparent,
        border: Border.all(
          color: done
              ? AppColors.brandPrimary
              : AppColors.borderSecondary(context),
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

// ── Bottom nav bar ────────────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeNavTabProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    void go(int index) =>
        ref.read(activeNavTabProvider.notifier).setTab(index);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _NavItem(
                icon: CoolIcons.house_03,
                label: 'Home',
                active: activeTab == 0,
                onTap: () => go(0),
              ),
              _NavItem(
                icon: CoolIcons.chat_conversation,
                label: 'Translate',
                active: activeTab == 1,
                onTap: () => go(1),
              ),
              _NavItem(
                icon: CoolIcons.list_checklist,
                label: 'Review',
                active: activeTab == 2,
                onTap: () => go(2),
              ),
              _NavItem(
                icon: CoolIcons.book_open,
                label: 'Phrasebook',
                active: activeTab == 3,
                onTap: () => go(3),
              ),
              _NavItem(
                icon: CoolIcons.user_02,
                label: 'Profile',
                active: activeTab == 4,
                onTap: () => go(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.brandPrimary : AppColors.textTertiary(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak success modal ──────────────────────────────────────────────────────

class _StreakSuccessModal extends StatelessWidget {
  final int streak;
  final List<bool> weekActivity;
  final VoidCallback onDismiss;

  const _StreakSuccessModal({
    required this.streak,
    required this.weekActivity,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'Day $streak Complete!',
              style: GoogleFonts.googleSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You showed up today. Keep the streak alive!',
              textAlign: TextAlign.center,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textTertiary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final done = i < weekActivity.length && weekActivity[i];
                return Column(
                  children: [
                    Text(
                      days[i],
                      style: GoogleFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                        border: Border.all(
                          color: done
                              ? AppColors.brandPrimary
                              : AppColors.borderSecondary(context),
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Keep it up! 🔥',
                  style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
