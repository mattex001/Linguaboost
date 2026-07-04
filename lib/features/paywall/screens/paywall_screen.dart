import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/local_storage_service.dart';
import '../providers/purchase_provider.dart';
import '../widgets/plan_selector_widget.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanType _selected = PlanType.annual;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the RC Package matching the selected plan, or null if not loaded.
  Package? _packageFor(Offerings? offerings) {
    if (offerings == null) return null;
    final current = offerings.current;
    if (current == null) return null;

    for (final pkg in current.availablePackages) {
      if (_selected == PlanType.annual &&
          pkg.packageType == PackageType.annual) {
        return pkg;
      }
      if (_selected == PlanType.monthly &&
          pkg.packageType == PackageType.monthly) {
        return pkg;
      }
    }
    // Fallback: first available
    return current.availablePackages.isNotEmpty
        ? current.availablePackages.first
        : null;
  }

  Future<void> _onContinue(Offerings? offerings) async {
    final pkg = _packageFor(offerings);
    if (pkg == null) {
      // Offerings not loaded — skip (dev / config issue)
      await LocalStorageService.instance.setOnboardingComplete();
      if (mounted) context.go(AppRoutes.dashboard);
      return;
    }

    final notifier = ref.read(purchaseNotifierProvider.notifier);
    final success = await notifier.purchase(pkg);
    if (success && mounted) {
      await LocalStorageService.instance.setOnboardingComplete();
      if (mounted) context.go(AppRoutes.dashboard);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.read(purchaseNotifierProvider.notifier).clearError();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final offeringsAsync = ref.watch(offeringsProvider);

    // Show error snackbar when purchase fails
    ref.listen(purchaseNotifierProvider, (_, next) {
      if (next.status == PurchaseStatus.error &&
          next.errorMessage != null) {
        _showError(next.errorMessage!);
      }
    });

    final isLoading = purchaseState.status == PurchaseStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            color: AppColors.backgroundSecondary(context),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 167,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Close button
                          SizedBox(
                            height: 48,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        await LocalStorageService.instance.setOnboardingComplete();
                                        if (context.mounted) context.go(AppRoutes.dashboard);
                                      },
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: Icon(CoolIcons.close_lg, size: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 13),

                          Text(
                            'Lets get started',
                            style: GoogleFonts.googleSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                              height: 25 / 16,
                            ),
                          ),

                          const SizedBox(height: 6),

                          SizedBox(
                            width: 225,
                            child: Text(
                              'How your free trial works',
                              style: GoogleFonts.googleSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                                height: 25 / 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hero illustration
                    Positioned(
                      right: 0,
                      top: 37,
                      child: SvgPicture.asset(
                        'assets/images/Paywall screen.svg',
                        width: 111,
                        height: 141,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable: timeline + plan selector ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 345,
                    child: _buildTimeline(context),
                  ),
                  // Extra breathing room so content clears the fixed CTA on small screens
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: PlanSelectorWidget(
                      selected: _selected,
                      onSelect: (p) => setState(() => _selected = p),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed bottom: Continue + disclaimer ─────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
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
                        onPressed: isLoading
                            ? null
                            : () => _onContinue(offeringsAsync.asData?.value),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.brandPrimary,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Start free trial',
                                style: GoogleFonts.googleSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            final notifier =
                                ref.read(purchaseNotifierProvider.notifier);
                            final ok = await notifier.restore();
                            if (ok && mounted) {
                              await LocalStorageService.instance.setOnboardingComplete();
                              // ignore: use_build_context_synchronously
                              if (mounted) context.go(AppRoutes.dashboard);
                            }
                          },
                    child: Text(
                      'Restore purchases · Free trial for new subscribers only',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.googleSans(
                        fontSize: 12,
                        color: AppColors.textTertiary(context),
                        height: 16.8 / 12,
                      ),
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

  // ── Timeline ─────────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context) {
    return Stack(
      children: [
        // Yellow gradient tail — drawn first so purple bar renders on top
        Positioned(
          left: 19.89,
          top: 240.78,
          child: Container(
            width: 26.99,
            height: 80.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFECC00), Color(0x33F0EEE6)],
                stops: [0.587, 0.936],
              ),
            ),
          ),
        ),

        // Purple bar — drawn on top of gradient
        Positioned(
          left: 19.89,
          top: 21.19,
          child: Container(
            width: 26.99,
            height: 262.48,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Step 1
        Positioned(
          left: 23.63,
          top: 32.37,
          child: const Icon(CoolIcons.user_check,
              size: 18, color: Colors.white),
        ),
        Positioned(
          left: 69.5,
          top: 30.37,
          right: 20,
          child: _StepContent(
            title: 'Create your account',
            subtitle: "You've successful created your profile and learning goals",
            strikethrough: true,
          ),
        ),

        // Step 2
        Positioned(
          left: 23.63,
          top: 115.37,
          child: const Icon(CoolIcons.lock_open,
              size: 18, color: Colors.white),
        ),
        Positioned(
          left: 69.5,
          top: 111.37,
          right: 20,
          child: _StepContent(
            title: 'Today: Get pro access',
            subtitle: 'You can use all the pro features with restrictions',
          ),
        ),

        // Step 3
        Positioned(
          left: 23.14,
          top: 179.37,
          child: const Icon(CoolIcons.bell_notification,
              size: 18, color: Colors.white),
        ),
        Positioned(
          left: 70.5,
          top: 175.37,
          right: 20,
          child: _StepContent(
            title: 'Day 5: Reminder',
            subtitle: "We'll remind you before your trial ends with a notification",
          ),
        ),

        // Step 4
        Positioned(
          left: 23.63,
          top: 256.37,
          child: const Icon(CoolIcons.star, size: 18, color: Colors.white),
        ),
        Positioned(
          left: 69,
          top: 256.37,
          right: 20,
          child: Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day 7: Trial ends',
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                    height: 25 / 14,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.googleSans(
                      fontSize: 12,
                      color: AppColors.textTertiary(context),
                      height: 16.8 / 12,
                    ),
                    children: [
                      const TextSpan(text: 'Your pro subscription starts on '),
                      TextSpan(
                        text: 'Nov 5, 2026',
                        style: GoogleFonts.googleSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                          height: 16.8 / 12,
                        ),
                      ),
                      const TextSpan(text: ' cancel before to avoid payment'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step content ──────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool strikethrough;

  const _StepContent({
    required this.title,
    this.subtitle,
    this.strikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
            height: 25 / 14,
            decoration:
                strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: AppColors.textPrimary(context),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.googleSans(
              fontSize: 12,
              color: AppColors.textTertiary(context),
              height: 16.8 / 12,
            ),
          ),
        ],
      ],
    );
  }
}
