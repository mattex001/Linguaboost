import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';

// ── Page content data ─────────────────────────────────────────────────────────

class _PageData {
  final String imageAsset;
  final String title;
  final String subtitle;

  const _PageData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });
}

const _pages = [
  _PageData(
    imageAsset: 'assets/images/onboarding_setting_goals.svg',
    title: 'Say what you\nactually need to say',
    subtitle:
        'Translate real sentences from your life and learn how locals would say them',
  ),
  _PageData(
    imageAsset: 'assets/images/onboarding_vocabulary.svg',
    title: 'Every phrase\nbecomes a lesson',
    subtitle:
        'Everything you translate is saved to your phrasebook with grammar, usage, and pronunciation',
  ),
  _PageData(
    imageAsset: 'assets/images/onboarding_progress.svg',
    title: 'Review at the\nright moment',
    subtitle:
        'Smart spaced repetition brings phrases back just before you forget them',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.authSignup);
    }
  }

  void _onSignIn() => context.go(AppRoutes.authLogin);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Illustration carousel ─────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _IllustrationPage(data: _pages[i]),
              ),
            ),
            // ── Bottom content ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _pages[_currentPage].title,
                      key: ValueKey('title_$_currentPage'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2XLFor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _pages[_currentPage].subtitle,
                      key: ValueKey('sub_$_currentPage'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.textSM.copyWith(
                        color: AppColors.textTertiary(context),
                        height: AppTypography.lineHeightHeadingSM /
                            AppTypography.textSM,
                      ),
                    ),
                  ),
                  const SizedBox(height: 42),
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 2.5,
                      spacing: 6,
                      activeDotColor: AppColors.brandPrimary,
                      dotColor: AppColors.borderSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 42),
                  // Primary CTA
                  _PrimaryButton(
                    label: _currentPage == _pages.length - 1
                        ? 'Get started'
                        : 'Next',
                    onTap: _onNext,
                  ),
                  const SizedBox(height: 20),
                  // Sign-in
                  _OutlineButton(label: 'Sign in', onTap: _onSignIn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Illustration page ─────────────────────────────────────────────────────────

class _IllustrationPage extends StatelessWidget {
  final _PageData data;
  const _IllustrationPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Decorative: green star — top right — float up/down + slow spin
        Positioned(
          top: 52,
          right: 20,
          child: Transform.rotate(
            angle: -1.05,
            child: const _StarShape(size: 28, color: Color(0xFF3E9142)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -9,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: 0,
                end: 0.12,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Decorative: large pink star — left edge — float down + slow spin, offset phase
        Positioned(
          top: 92,
          left: -8,
          child: Transform.rotate(
            angle: -1.05,
            child: const _StarShape(size: 42, color: Color(0xFFE85D8A)),
          )
              .animate(
                delay: 500.ms,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: 11,
                duration: 2600.ms,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: 0,
                end: -0.10,
                duration: 2600.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Decorative: salmon leaf — top right upper — float + gentle rock
        Positioned(
          top: 30,
          right: 68,
          child: Transform.rotate(
            angle: -0.52,
            child: const _LeafShape(size: 36, color: Color(0xFFF4A46A)),
          )
              .animate(
                delay: 250.ms,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: -7,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: -0.06,
                end: 0.06,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),
        ),
        // Illustration
        Center(
          child: SvgPicture.asset(
            data.imageAsset,
            height: 260,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms),
        ),
      ],
    );
  }
}

// ── Decorative shapes ─────────────────────────────────────────────────────────

class _StarShape extends StatelessWidget {
  final double size;
  final Color color;
  const _StarShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FourPointStarPainter(color: color),
    );
  }
}

class _FourPointStarPainter extends CustomPainter {
  final Color color;
  const _FourPointStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = cx;
    final inner = cx * 0.35;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final r = i.isEven ? outer : inner;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FourPointStarPainter old) => old.color != color;
}

class _LeafShape extends StatelessWidget {
  final double size;
  final Color color;
  const _LeafShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size),
      painter: _LeafPainter(color: color),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  const _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(size.width, 0, size.width, size.height, size.width / 2, size.height)
      ..cubicTo(0, size.height, 0, 0, size.width / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}

// ── Primary button (purple with hard shadow) ──────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppTextStyles.headingMD.copyWith(
                color: Colors.white,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outline button (white with soft shadow) ───────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 47,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.backgroundPrimary(context),
            foregroundColor: AppColors.backgroundInverse(context),
            side: BorderSide(color: AppColors.borderSecondary(context)),
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: AppTextStyles.headingMD.copyWith(
              color: AppColors.backgroundInverse(context),
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ),
      ),
    );
  }
}
