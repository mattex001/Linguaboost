import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';

// ── Shared back-only scaffold ─────────────────────────────────────────────────

class _StaticScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  const _StaticScaffold({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Nav bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(CoolIcons.chevron_left, size: 28),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: GoogleFonts.googleSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ── Notifications settings ────────────────────────────────────────────────────

class ProfileNotificationsScreen extends ConsumerStatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  ConsumerState<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends ConsumerState<ProfileNotificationsScreen> {
  bool _enabled = false;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userSnapshotProvider);
    if (user != null) {
      _enabled = user.notificationsEnabled;
      _start = _parseTime(user.notificationStartTime);
      _end = _parseTime(user.notificationEndTime);
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayTime(TimeOfDay t) => t.format(context);

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _toggleEnabled(bool val) async {
    if (val && Platform.isIOS) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        if (!result.isGranted) return;
      }
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
    }
    setState(() => _enabled = val);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid != null) {
      await ref.read(userRepositoryProvider).updateUser(uid, {
        'notifications_enabled': _enabled,
        'notification_start': _formatTime(_start),
        'notification_end': _formatTime(_end),
      });
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        child: Column(
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(CoolIcons.chevron_left, size: 28),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Notifications',
                          style: GoogleFonts.googleSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Push toggle group
                    _GroupCard(
                      children: [
                        _RowItem(
                          icon: CoolIcons.bell_notification,
                          title: 'Push notifications',
                          trailing: Switch.adaptive(
                            value: _enabled,
                            onChanged: _toggleEnabled,
                            activeTrackColor: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reminder window (only shown when enabled)
                    AnimatedOpacity(
                      opacity: _enabled ? 1 : 0.38,
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'REMINDER WINDOW',
                              style: GoogleFonts.googleSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary(context),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          _GroupCard(
                            children: [
                              _RowItem(
                                icon: CoolIcons.clock,
                                title: 'Start time',
                                trailing: GestureDetector(
                                  onTap: _enabled
                                      ? () => _pickTime(isStart: true)
                                      : null,
                                  child: Text(
                                    _displayTime(_start),
                                    style: GoogleFonts.googleSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _enabled
                                          ? AppColors.brandPrimary
                                          : AppColors.textTertiary(context),
                                    ),
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 52,
                                color: AppColors.borderDisabled(context),
                              ),
                              _RowItem(
                                icon: CoolIcons.clock,
                                title: 'End time',
                                trailing: GestureDetector(
                                  onTap: _enabled
                                      ? () => _pickTime(isStart: false)
                                      : null,
                                  child: Text(
                                    _displayTime(_end),
                                    style: GoogleFonts.googleSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _enabled
                                          ? AppColors.brandPrimary
                                          : AppColors.textTertiary(context),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'We\'ll send reminders between these times only.',
                              style: GoogleFonts.googleSans(
                                fontSize: 12,
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
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              child: SizedBox(
                width: double.infinity,
                height: 47,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save changes',
                          style: GoogleFonts.googleSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

// ── Help & FAQ ────────────────────────────────────────────────────────────────

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  int? _open;

  static const _faqs = [
    (
      'How does translation work?',
      'Type, paste, or speak an English sentence and LinguaBoost translates it the way a native speaker would say it — with a formality note, vocabulary breakdown, grammar note, and pronunciation. Every translation is saved to your phrasebook automatically.',
    ),
    (
      'How does Daily Review work?',
      'LinguaBoost uses spaced repetition: each phrase comes back for review right before you\'d forget it. Rate each card Again, Hard, or Easy and the schedule adapts. Only your own phrases are reviewed — no random content.',
    ),
    (
      'How is my streak calculated?',
      'Your streak increases by 1 for each calendar day you translate a phrase or complete your due reviews. Missing a day resets the streak to zero.',
    ),
    (
      'Can I change my target language?',
      'Yes. Go to Profile → My Learning → Target language at any time. New translations will use the new language; phrases you already saved keep theirs.',
    ),
    (
      'How do I cancel my subscription?',
      'On iOS, open Settings → Apple ID → Subscriptions. On Android, open the Play Store → Subscriptions. LinguaBoost does not handle cancellations directly.',
    ),
    (
      'Why am I not receiving reminders?',
      'Check that notifications are enabled in Profile → Notifications and that LinguaBoost has notification permission in your device Settings. Also confirm your reminder window covers the current time.',
    ),
    (
      'How do I restore a previous purchase?',
      'On the paywall screen, tap "Restore purchases" at the bottom. Your active subscription will be detected and re-applied automatically.',
    ),
    (
      'Is my data private?',
      'We only store the information you provide during onboarding plus your saved phrases and review history. We never sell personal data. See our Privacy Policy for full details.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _StaticScaffold(
      title: 'Help & FAQ',
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        itemCount: _faqs.length,
        itemBuilder: (context, i) {
          final faq = _faqs[i];
          final isOpen = _open == i;
          return GestureDetector(
            onTap: () => setState(() => _open = isOpen ? null : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOpen
                      ? AppColors.brandPrimary.withValues(alpha: 0.4)
                      : AppColors.borderTertiary(context),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            faq.$1,
                            style: GoogleFonts.googleSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isOpen
                                  ? AppColors.brandPrimary
                                  : AppColors.textPrimary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textTertiary(context),
                          ),
                        ),
                      ],
                    ),
                    if (isOpen) ...[
                      const SizedBox(height: 10),
                      Text(
                        faq.$2,
                        style: GoogleFonts.googleSans(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Privacy Policy ────────────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticScaffold(
      title: 'Privacy Policy',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        children: [
          _PolicySection(
            title: 'Last updated: January 2025',
            body:
                'LinguaBoost ("we", "our", or "us") is committed to protecting your privacy. This policy explains what data we collect, why we collect it, and how we use it.',
          ),
          _PolicySection(
            title: '1. Information we collect',
            body:
                'We collect the email address you use to sign in, your in-app preferences (target language, learning goal, reminder window), the phrases you translate, and usage statistics such as your streak and review history.',
          ),
          _PolicySection(
            title: '2. How we use your information',
            body:
                'Your information is used solely to personalise your learning experience, deliver daily word reminders, and maintain your account. We do not use your data for advertising or share it with third-party advertisers.',
          ),
          _PolicySection(
            title: '3. Data storage',
            body:
                'Your data is stored securely in Google Firebase (Firestore and Firebase Authentication). Firebase complies with GDPR, CCPA, and other applicable data protection regulations.',
          ),
          _PolicySection(
            title: '4. Third-party services',
            body:
                'We use RevenueCat to manage subscriptions. RevenueCat may collect transaction information as described in their privacy policy. We use Firebase Cloud Messaging for push notifications.',
          ),
          _PolicySection(
            title: '5. Data retention',
            body:
                'We retain your data for as long as your account is active. You may request deletion at any time via Profile → Account → Delete account. Deletion is permanent and cannot be undone.',
          ),
          _PolicySection(
            title: '6. Your rights',
            body:
                'Depending on your jurisdiction you may have the right to access, correct, or delete the personal data we hold about you. To exercise these rights, contact us at support@linguaboost.app.',
          ),
          _PolicySection(
            title: '7. Changes to this policy',
            body:
                'We may update this policy from time to time. We will notify you of significant changes via in-app notice or email. Continued use of the app after changes constitutes acceptance.',
          ),
          _PolicySection(
            title: '8. Contact',
            body:
                'Questions about this policy? Email us at privacy@linguaboost.app.',
          ),
        ],
      ),
    );
  }
}

// ── Terms of Service ──────────────────────────────────────────────────────────

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticScaffold(
      title: 'Terms of Service',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        children: [
          _PolicySection(
            title: 'Last updated: January 2025',
            body:
                'By downloading or using LinguaBoost you agree to these Terms of Service. Please read them carefully.',
          ),
          _PolicySection(
            title: '1. Use of the app',
            body:
                'LinguaBoost is for personal, non-commercial use only. You must be at least 13 years old to create an account. You are responsible for maintaining the security of your account credentials.',
          ),
          _PolicySection(
            title: '2. Subscriptions & billing',
            body:
                'Premium features are available through a paid subscription billed via the App Store or Google Play. Subscriptions auto-renew unless cancelled at least 24 hours before the renewal date. We offer a 7-day free trial for new subscribers.',
          ),
          _PolicySection(
            title: '3. Refunds',
            body:
                'All purchases are subject to the refund policy of the platform through which you subscribed (Apple App Store or Google Play Store). LinguaBoost does not process refunds directly.',
          ),
          _PolicySection(
            title: '4. Intellectual property',
            body:
                'All content within LinguaBoost — including word definitions, example sentences, learning programs, and UI design — is owned by or licensed to LinguaBoost. You may not reproduce or distribute this content without permission.',
          ),
          _PolicySection(
            title: '5. Disclaimers',
            body:
                'LinguaBoost is provided "as is" without warranties of any kind. We do not guarantee that the app will be error-free or available at all times. Language learning outcomes depend on individual effort and consistency.',
          ),
          _PolicySection(
            title: '6. Limitation of liability',
            body:
                'To the maximum extent permitted by law, LinguaBoost shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.',
          ),
          _PolicySection(
            title: '7. Termination',
            body:
                'We reserve the right to suspend or terminate accounts that violate these terms. You may delete your account at any time from the Profile screen.',
          ),
          _PolicySection(
            title: '8. Governing law',
            body:
                'These terms are governed by the laws of the United Kingdom. Any disputes shall be resolved in the courts of England and Wales.',
          ),
          _PolicySection(
            title: '9. Contact',
            body: 'Questions? Email legal@linguaboost.app.',
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary(context)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _RowItem({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, size: 20, color: AppColors.textSecondary(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.googleSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
