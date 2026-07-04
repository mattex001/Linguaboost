import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

// ── Primary app button (purple + hard shadow + pill) ─────────────────────────
// This is the canonical primary button style for LinguaBoost.

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.height = 47,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.31,
      child: DecoratedBox(
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
          height: height,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brandPrimary,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Secondary app button (transparent + border + pill) ────────────────────────

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary(context),
          side: BorderSide(color: AppColors.borderSecondary(context)),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}
