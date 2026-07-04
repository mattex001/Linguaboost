import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

// ── Plan type ─────────────────────────────────────────────────────────────────

enum PlanType { annual, monthly }

// ── Plan selector (reusable) ──────────────────────────────────────────────────
//
// Usage:
//   PlanSelectorWidget(
//     selected: _selected,
//     onSelect: (plan) => setState(() => _selected = plan),
//   )

class PlanSelectorWidget extends StatelessWidget {
  final PlanType selected;
  final ValueChanged<PlanType> onSelect;

  const PlanSelectorWidget({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Card height is fixed 94px. The badge (~22px tall) is centred on the
    // bottom border → top = 94 - 11 = 83, giving 11px inside + 11px outside.
    const double cardHeight = 102;
    const double badgeHeight = 22;
    const double badgeTop = cardHeight - badgeHeight / 2; // 91

    return Stack(
      clipBehavior: Clip.none, // badge overflows below card
      children: [
        // ── Card row (both Expanded to fill full width) ────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _PlanCard(
                type: PlanType.annual,
                selected: selected == PlanType.annual,
                onTap: () => onSelect(PlanType.annual),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _PlanCard(
                type: PlanType.monthly,
                selected: selected == PlanType.monthly,
                onTap: () => onSelect(PlanType.monthly),
              ),
            ),
          ],
        ),

        // ── "Best value" badge — straddles the bottom border of annual card ─
        // Positioned inside the annual card's Expanded half.
        // left: 20 gives a natural left-of-centre feel matching Figma.
        Positioned(
          left: 20,
          top: badgeTop,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF141413),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'Best value',
              style: GoogleFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 16.8 / 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanType type;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAnnual = type == PlanType.annual;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 102,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          // Selected: purple tint | Default: backgroundTertiary
          color: selected
              ? AppColors.brandPrimary.withValues(alpha: 0.10)
              : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(10),
          // Selected: 2px brandPrimary | Default: 1px borderTertiary
          border: Border.all(
            color: selected
                ? AppColors.brandPrimary
                : AppColors.borderTertiary(context),
            width: selected ? 2 : 1,
          ),
        ),
        // Figma structure: single Row — all text left, radio right
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: title + price + sub-price, gap-3px
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title ────────────────────────────────────────────────
                if (isAnnual)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Annual ',
                          style: GoogleFonts.googleSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: '30% off',
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Monthly',
                    style: GoogleFonts.googleSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ),
                  ),

                const SizedBox(height: 3),

                // ── Price ─────────────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ).copyWith(fontFamilyFallback: const ['Roboto', 'sans-serif']),
                    children: [
                      TextSpan(
                          text: isAnnual ? '\u20A616,800 / ' : '\u20A62,000 / '),
                      TextSpan(
                        text: isAnnual ? 'Yearly' : 'month',
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 3),

                // ── Sub-price / trial note ─────────────────────────────────
                Text(
                  isAnnual ? '₦24,000 / Year' : '7 days free trial',
                  style: GoogleFonts.googleSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary(context),
                    height: 16.8 / 10,
                    decoration: isAnnual
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
            ),

            // Right: radio indicator
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

// ── Radio indicator ───────────────────────────────────────────────────────────

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.brandPrimary
              : AppColors.borderTertiary(context),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary,
                ),
              ),
            )
          : null,
    );
  }
}
