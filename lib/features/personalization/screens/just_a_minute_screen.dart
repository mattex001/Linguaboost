import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

/// Interstitial that also seeds the phrasebook with 8 relocation-starter
/// phrases (PRD §9.4 cold start). Seeding runs in the background — failure is
/// non-blocking, the phrasebook just starts empty.
class JustAMinuteScreen extends ConsumerStatefulWidget {
  const JustAMinuteScreen({super.key});

  @override
  ConsumerState<JustAMinuteScreen> createState() => _JustAMinuteScreenState();
}

class _JustAMinuteScreenState extends ConsumerState<JustAMinuteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedPhrasebook());
  }

  Future<void> _seedPhrasebook() async {
    final user = ref.read(userSnapshotProvider);
    final targetLang = user?.targetLanguage;
    if (targetLang == null) return;

    try {
      await Supabase.instance.client.functions.invoke(
        'seed-phrasebook',
        body: {'targetLang': targetLang},
      );
    } catch (e) {
      debugPrint('seed-phrasebook failed (non-blocking): $e');
    }
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

            // ── Illustration ───────────────────────────────────────────────
            Expanded(
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/Notification_illustration.svg',
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ── Bottom content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A few minutes a day\ncan make a big\ndifference',
                    style: GoogleFonts.googleSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.1,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    "We're adding your first phrases — the ones everyone needs in a new place",
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary(context),
                      height: 19.6 / 14,
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                  const SizedBox(height: 37),
                  PersonalizationPrimaryButton(
                    label: 'Continue',
                    onTap: () =>
                        context.push(AppRoutes.personalizationNotifications),
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
