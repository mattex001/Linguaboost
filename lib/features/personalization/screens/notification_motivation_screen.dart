import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

class NotificationMotivationScreen extends ConsumerWidget {
  const NotificationMotivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalizationHeader(),

            // ── Three circular illustrations ───────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _NotifIllustration(),
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
                    'Your course builds\nitself as you live',
                    style: GoogleFonts.googleSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Translate what you need, review it at the right moment, and watch it stick',
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
                    onTap: () => context.go(AppRoutes.paywall),
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

// ── Three floating circular cards (illustration) ──────────────────────────────

class _NotifIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Top centre card
          Positioned(
            top: 0,
            left: 80,
            right: 80,
            child: _CircleCard(
              svgAsset: 'assets/icons/Improve screen 1.svg',
              delay: 0,
            ),
          ),
          // Bottom left card
          Positioned(
            bottom: 0,
            left: 0,
            child: _CircleCard(
              svgAsset: 'assets/icons/Improve screen 2.svg',
              delay: 200,
            ),
          ),
          // Bottom right card
          Positioned(
            bottom: 20,
            right: 0,
            child: _CircleCard(
              svgAsset: 'assets/icons/Improve screens 3.svg',
              delay: 400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final String svgAsset;
  final int delay;

  const _CircleCard({
    required this.svgAsset,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      svgAsset,
      width: 160,
      height: 160,
      fit: BoxFit.contain,
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
          delay: Duration(milliseconds: delay),
        )
        .moveY(
          begin: 0,
          end: -10,
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }
}
