import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/constants/languages.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/user_model.dart';
import '../../phrasebook/providers/phrasebook_provider.dart';
import '../../review/providers/review_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userSnapshotProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              _ProfileHeader(user: user),

              const SizedBox(height: 24),

              // ── Stats row ─────────────────────────────────────────────────
              if (user != null) _StatsRow(user: user),

              if (user != null) const SizedBox(height: 24),

              // ── PREMIUM ───────────────────────────────────────────────────
              _SectionGroup(
                label: 'PREMIUM',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.star,
                    iconColor: const Color(0xFFD4A017),
                    title: user?.isPremium == true
                        ? 'Manage subscription'
                        : 'Upgrade to Premium',
                    trailing: user?.isPremium == true
                        ? _StatusBadge('Active',
                            color: AppColors.backgroundSuccessLight)
                        : _StatusBadge('Get 30% off',
                            color: const Color(0xFFEDE9FE),
                            textColor: AppColors.brandPrimary),
                    onTap: () => context.push(AppRoutes.paywall),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── MY LEARNING ───────────────────────────────────────────────
              _SectionGroup(
                label: 'MY LEARNING',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.globe,
                    title: 'Target language',
                    value: _languageLabel(user?.targetLanguage),
                    onTap: () =>
                        context.push(AppRoutes.profileEditLanguage),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.flag,
                    title: 'Learning goal',
                    value: _goalLabel(user?.learningGoal),
                    onTap: () =>
                        context.push(AppRoutes.profileEditGoal),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── NOTIFICATIONS ─────────────────────────────────────────────
              _SectionGroup(
                label: 'NOTIFICATIONS',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.bell_notification,
                    title: 'Push notifications',
                    trailing: _ToggleChip(
                        enabled: user?.notificationsEnabled ?? false),
                    onTap: () =>
                        context.push(AppRoutes.profileNotifications),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.clock,
                    title: 'Reminder window',
                    value: user?.notificationsEnabled == true
                        ? '${user!.notificationStartTime} – ${user.notificationEndTime}'
                        : 'Off',
                    onTap: () =>
                        context.push(AppRoutes.profileNotifications),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── APPEARANCE ────────────────────────────────────────────────
              _SectionGroup(
                label: 'APPEARANCE',
                items: [
                  _ThemeRow(),
                  _SettingsItem(
                    icon: CoolIcons.moon,
                    title: 'Background theme',
                    value: user?.isPremium == true ? 'Customise' : 'Premium',
                    trailing: user?.isPremium == false
                        ? _StatusBadge('Premium',
                            color: const Color(0xFFEDE9FE),
                            textColor: AppColors.brandPrimary)
                        : null,
                    onTap: () => context.push(AppRoutes.homeThemes),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── SHARE & SUPPORT ───────────────────────────────────────────
              _SectionGroup(
                label: 'SHARE & SUPPORT',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.share_android,
                    title: 'Share LinguaBoost',
                    onTap: () => _share(),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.star,
                    title: 'Rate the app',
                    onTap: () => _rateApp(),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.chat_circle_dots,
                    title: 'Give feedback',
                    onTap: () => _giveFeedback(),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.info,
                    title: 'Help & FAQ',
                    onTap: () => context.push(AppRoutes.profileHelpFaq),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── LEGAL ─────────────────────────────────────────────────────
              _SectionGroup(
                label: 'LEGAL',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.file_document,
                    title: 'Privacy Policy',
                    onTap: () => context.push(AppRoutes.profilePrivacyPolicy),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.file_document,
                    title: 'Terms of Service',
                    onTap: () => context.push(AppRoutes.profileTermsOfService),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── ACCOUNT ───────────────────────────────────────────────────
              _SectionGroup(
                label: 'ACCOUNT',
                items: [
                  _SettingsItem(
                    icon: CoolIcons.log_out,
                    iconColor: AppColors.textDanger(context),
                    title: 'Sign out',
                    titleColor: AppColors.textDanger(context),
                    showChevron: false,
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                  _SettingsItem(
                    icon: CoolIcons.trash_empty,
                    iconColor: AppColors.textDanger(context),
                    title: 'Delete account',
                    titleColor: AppColors.textDanger(context),
                    showChevron: false,
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Version footer ─────────────────────────────────────────────
              _VersionFooter(userId: user?.id),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _goalLabel(String? goal) =>
      (goal == null || goal.isEmpty) ? 'Not set' : goal;

  String _languageLabel(String? code) {
    final language = targetLanguageForCode(code);
    if (language == null) return 'Not set';
    return '${language.flag} ${language.label}';
  }

  void _share() {
    Share.share(
      'I\'ve been learning a language with LinguaBoost — it builds a course from the phrases you actually need! 🌍',
      subject: 'Check out LinguaBoost',
    );
  }

  void _rateApp() {
    final uri = Uri.parse(
      'https://apps.apple.com/app/idYOUR_APP_ID',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _giveFeedback() {
    final uri = Uri.parse(
      'mailto:support@linguaboost.app?subject=LinguaBoost%20Feedback',
    );
    launchUrl(uri);
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: 'Sign out',
        body: 'Are you sure you want to sign out of LinguaBoost?',
        confirmLabel: 'Sign out',
        confirmColor: AppColors.backgroundDangerLight,
        onConfirm: () async {
          Navigator.of(context).pop();
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) context.go(AppRoutes.authSignup);
        },
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: 'Delete account',
        body:
            'This will permanently delete your account and all your learning data. This cannot be undone.',
        confirmLabel: 'Delete account',
        confirmColor: AppColors.backgroundDangerLight,
        onConfirm: () async {
          Navigator.of(context).pop();
          await ref.read(authServiceProvider).deleteAccount();
          if (context.mounted) context.go(AppRoutes.authSignup);
        },
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  const _ProfileHeader({required this.user});

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

  String get _displayName {
    if (user?.name?.trim().isNotEmpty == true) return user!.name!.trim();
    if (user?.email == null) return 'Guest';
    final prefix = user!.email!.split('@').first;
    if (prefix.isEmpty) return 'Guest';
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        children: [
          // ── Top row: title + edit ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.chauPhilomeneOne(
                  fontSize: 24,
                  color: AppColors.textPrimary(context),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.profileEditName),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary(context),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderTertiary(context)),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Avatar + info ─────────────────────────────────────────────────
          Row(
            children: [
              // Avatar circle
              Container(
                width: 68,
                height: 68,
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
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Name + email + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _displayName,
                          style: GoogleFonts.googleSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user?.isPremium == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Premium',
                              style: GoogleFonts.googleSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'Not signed in',
                      style: GoogleFonts.googleSans(
                        fontSize: 13,
                        color: AppColors.textTertiary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Target-language badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _languageBadge(user?.targetLanguage),
                            style: GoogleFonts.googleSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _languageBadge(String? code) {
    final language = targetLanguageForCode(code);
    if (language == null) return 'Pick a language';
    return 'Learning ${language.label} ${language.flag}';
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phrases = ref.watch(phrasesSavedCountProvider);
    final due = ref.watch(dueCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _StatCard(
            value: '${user.streak}',
            label: 'Day streak',
            svgPath: 'assets/icons/Main icon/Group-14.svg',
            flex: 2,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: '$phrases',
            label: 'Phrases saved',
            svgPath: 'assets/icons/Main icon/Group-85.svg',
            flex: 2,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: '$due',
            label: 'Due today',
            svgPath: 'assets/icons/Main icon/Group-84.svg',
            flex: 2,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String svgPath;
  final int flex;

  const _StatCard({
    required this.value,
    required this.label,
    required this.svgPath,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderTertiary(context)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            SvgPicture.asset(svgPath, width: 28, height: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.googleSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.googleSans(
                fontSize: 10,
                color: AppColors.textTertiary(context),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section group ──────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _SectionGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary(context),
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderTertiary(context)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: AppColors.borderDisabled(context),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme row ──────────────────────────────────────────────────────────────────

class _ThemeRow extends ConsumerWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              Icons.brightness_6_rounded,
              size: 20,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'App theme',
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ThemeSegmentControl(current: mode),
        ],
      ),
    );
  }
}

class _ThemeSegmentControl extends ConsumerWidget {
  final ThemeMode current;
  const _ThemeSegmentControl({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderTertiary(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            icon: Icons.wb_sunny_rounded,
            label: 'Light',
            active: current == ThemeMode.light,
            isFirst: true,
            isLast: false,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          Container(
            width: 1,
            height: 18,
            color: AppColors.borderDisabled(context),
          ),
          _Segment(
            icon: Icons.brightness_auto_rounded,
            label: 'Auto',
            active: current == ThemeMode.system,
            isFirst: false,
            isLast: false,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),
          Container(
            width: 1,
            height: 18,
            color: AppColors.borderDisabled(context),
          ),
          _Segment(
            icon: Icons.nights_stay_rounded,
            label: 'Dark',
            active: current == ThemeMode.dark,
            isFirst: false,
            isLast: true,
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _Segment({
    required this.icon,
    required this.label,
    required this.active,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(9) : Radius.zero,
      right: isLast ? const Radius.circular(9) : Radius.zero,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.backgroundPrimary(context) : Colors.transparent,
          borderRadius: radius,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? AppColors.brandPrimary
                  : AppColors.textTertiary(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.brandPrimary
                    : AppColors.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings item ──────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: 24,
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColors.textPrimary(context),
                ),
              ),
            ),

            // Value text
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(
                value!,
                style: GoogleFonts.googleSans(
                  fontSize: 13,
                  color: AppColors.textTertiary(context),
                ),
              ),
            ],

            // Custom trailing widget
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],

            // Chevron
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _StatusBadge(this.label, {required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.googleSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textSuccess(context),
        ),
      ),
    );
  }
}

// ── Toggle chip ────────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final bool enabled;
  const _ToggleChip({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.backgroundSuccessLight.withValues(alpha: 0.3)
            : AppColors.backgroundSecondary(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled
              ? const Color(0xFF437426).withValues(alpha: 0.4)
              : AppColors.borderTertiary(context),
        ),
      ),
      child: Text(
        enabled ? 'On' : 'Off',
        style: GoogleFonts.googleSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: enabled
              ? const Color(0xFF437426)
              : AppColors.textTertiary(context),
        ),
      ),
    );
  }
}

// ── Version footer ─────────────────────────────────────────────────────────────

class _VersionFooter extends StatelessWidget {
  final String? userId;
  const _VersionFooter({this.userId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GestureDetector(
        onTap: userId != null
            ? () {
                Clipboard.setData(ClipboardData(text: userId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User ID copied'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderTertiary(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LinguaBoost · version 1.0.0',
                      style: GoogleFonts.googleSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (userId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'User ID: ${userId!.length > 24 ? '${userId!.substring(0, 24)}…' : userId}',
                        style: GoogleFonts.googleSans(
                          fontSize: 11,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (userId != null)
                Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.textTertiary(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm bottom sheet ───────────────────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary(context),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.googleSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              color: AppColors.textTertiary(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary(context),
                    side: BorderSide(color: AppColors.borderSecondary(context)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDangerLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    confirmLabel,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
