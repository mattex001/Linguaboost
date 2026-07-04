import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../widgets/personalization_widgets.dart';

class AllowNotificationsScreen extends ConsumerStatefulWidget {
  const AllowNotificationsScreen({super.key});

  @override
  ConsumerState<AllowNotificationsScreen> createState() =>
      _AllowNotificationsScreenState();
}

class _AllowNotificationsScreenState
    extends ConsumerState<AllowNotificationsScreen> {
  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final granted = await NotificationService.instance.requestPermission();
      final uid = ref.read(authStateProvider).asData?.value?.id;
      if (uid != null && granted) {
        await ref
            .read(userRepositoryProvider)
            .updateUser(uid, {'notifications_enabled': true});
      }
    } catch (_) {
      // Non-blocking — reminders can be enabled later from Profile.
    }

    if (!mounted) return;
    setState(() => _busy = false);
    context.push(AppRoutes.personalizationMotivation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const PersonalizationHeader(),

            // ── Scrollable content ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay consistent with a daily review reminder',
                      style: GoogleFonts.googleSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 25 / 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "One nudge a day when phrases are due — that's it",
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary(context),
                        height: 19.6 / 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Reminder preview card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTertiary(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.borderTertiary(context),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App icon
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/icons/Theme.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Notification content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Time to review',
                                      style: GoogleFonts.googleSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(context),
                                        height: 19.6 / 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '8:00 AM',
                                      style: GoogleFonts.googleSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(context),
                                        height: 19.6 / 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You have 5 phrases waiting for review. '
                                  'Keep your streak going!',
                                  style: GoogleFonts.googleSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textTertiary(context),
                                    height: 16.8 / 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SvgPicture.asset(
                                  'assets/images/LinguaBoost_logo.svg',
                                  height: 12,
                                  fit: BoxFit.contain,
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
            ),

            // ── Enable button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: PersonalizationPrimaryButton(
                label: _busy ? 'Enabling…' : 'Enable reminders',
                enabled: !_busy,
                onTap: _enable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
