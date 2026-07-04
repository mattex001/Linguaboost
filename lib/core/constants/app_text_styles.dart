import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Figma Typography collection tokens + pre-built TextStyle definitions.
///
/// Raw tokens are in [AppTypography]. Composed styles are on [AppTextStyles].
class AppTypography {
  AppTypography._();

  // ── Font families ──────────────────────────────────────────────────────────
  // Figma: Font/Sans = "Google San", Font/Mono = "Google San"
  // Both map to google_fonts GoogleSans.

  // ── Weight ─────────────────────────────────────────────────────────────────

  static const FontWeight weightNormal   = FontWeight.w400; // 400
  static const FontWeight weightMedium   = FontWeight.w500; // 500
  static const FontWeight weightSemibold = FontWeight.w600; // 600
  static const FontWeight weightBold     = FontWeight.w700; // 700

  /// Weight / Mobile / Medium (550 — midpoint between w500 and w600)
  static const FontWeight weightMobileMedium = FontWeight.w600; // nearest Flutter value

  // ── Size / Text ────────────────────────────────────────────────────────────

  static const double textXS = 12;
  static const double textSM = 14;
  static const double textMD = 16;
  static const double textLG = 18;

  // ── Size / Heading ─────────────────────────────────────────────────────────

  static const double headingXS  = 12;
  static const double headingSM  = 14;
  static const double headingMD  = 16;
  static const double headingLG  = 20;
  static const double headingXL  = 24;
  static const double heading2XL = 28;
  static const double heading3XL = 36;

  // ── Line height / Text ─────────────────────────────────────────────────────
  // Stored as absolute px values; convert to Flutter height multiplier via
  //   height = lineHeightPx / fontSizePx
  // (helpers on AppTextStyles do this automatically)

  static const double lineHeightTextXS = 16.8;
  static const double lineHeightTextSM = 19.6;
  static const double lineHeightTextMD = 22.4;
  static const double lineHeightTextLG = 25.0;

  // ── Line height / Heading ──────────────────────────────────────────────────

  static const double lineHeightHeadingXS  = 16.8;
  static const double lineHeightHeadingSM  = 19.6;
  static const double lineHeightHeadingMD  = 22.4;
  static const double lineHeightHeadingLG  = 25.0;
  static const double lineHeightHeadingXL  = 30.0;
  static const double lineHeightHeading2XL = 30.8;
  static const double lineHeightHeading3XL = 36.0;
}

/// Pre-composed TextStyles built from [AppTypography] tokens.
///
/// All styles default to dark-mode colours. Use the `*For(context)` helpers
/// in widgets to resolve the correct colour from the active theme.
class AppTextStyles {
  AppTextStyles._();

  // ── Internal helper ────────────────────────────────────────────────────────

  static double _h(double lineHeightPx, double sizePx) => lineHeightPx / sizePx;

  // ── Heading styles ─────────────────────────────────────────────────────────

  static TextStyle get heading3XL => GoogleFonts.googleSans(
        fontSize: AppTypography.heading3XL,
        fontWeight: AppTypography.weightBold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeading3XL, AppTypography.heading3XL),
      );

  static TextStyle get heading2XL => GoogleFonts.googleSans(
        fontSize: AppTypography.heading2XL,
        fontWeight: AppTypography.weightBold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeading2XL, AppTypography.heading2XL),
      );

  static TextStyle get headingXL => GoogleFonts.googleSans(
        fontSize: AppTypography.headingXL,
        fontWeight: AppTypography.weightBold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeadingXL, AppTypography.headingXL),
      );

  static TextStyle get headingLG => GoogleFonts.googleSans(
        fontSize: AppTypography.headingLG,
        fontWeight: AppTypography.weightSemibold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeadingLG, AppTypography.headingLG),
      );

  static TextStyle get headingMD => GoogleFonts.googleSans(
        fontSize: AppTypography.headingMD,
        fontWeight: AppTypography.weightSemibold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeadingMD, AppTypography.headingMD),
      );

  static TextStyle get headingSM => GoogleFonts.googleSans(
        fontSize: AppTypography.headingSM,
        fontWeight: AppTypography.weightSemibold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeadingSM, AppTypography.headingSM),
      );

  static TextStyle get headingXS => GoogleFonts.googleSans(
        fontSize: AppTypography.headingXS,
        fontWeight: AppTypography.weightSemibold,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightHeadingXS, AppTypography.headingXS),
      );

  // ── Text (body) styles ─────────────────────────────────────────────────────

  static TextStyle get textLG => GoogleFonts.googleSans(
        fontSize: AppTypography.textLG,
        fontWeight: AppTypography.weightNormal,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightTextLG, AppTypography.textLG),
      );

  static TextStyle get textMD => GoogleFonts.googleSans(
        fontSize: AppTypography.textMD,
        fontWeight: AppTypography.weightNormal,
        color: AppColors.textPrimaryDark,
        height: _h(AppTypography.lineHeightTextMD, AppTypography.textMD),
      );

  static TextStyle get textSM => GoogleFonts.googleSans(
        fontSize: AppTypography.textSM,
        fontWeight: AppTypography.weightNormal,
        color: AppColors.textSecondaryDark,
        height: _h(AppTypography.lineHeightTextSM, AppTypography.textSM),
      );

  static TextStyle get textXS => GoogleFonts.googleSans(
        fontSize: AppTypography.textXS,
        fontWeight: AppTypography.weightNormal,
        color: AppColors.textTertiaryDark,
        height: _h(AppTypography.lineHeightTextXS, AppTypography.textXS),
      );

  // ── Medium-weight variants ─────────────────────────────────────────────────

  static TextStyle get textLGMedium  => textLG.copyWith(fontWeight: AppTypography.weightMedium);
  static TextStyle get textMDMedium  => textMD.copyWith(fontWeight: AppTypography.weightMedium);
  static TextStyle get textSMMedium  => textSM.copyWith(fontWeight: AppTypography.weightMedium);
  static TextStyle get textXSMedium  => textXS.copyWith(fontWeight: AppTypography.weightMedium);

  // ── Legacy aliases (keeps existing call-sites compiling) ──────────────────

  static TextStyle get headline1    => heading3XL;
  static TextStyle get headline2    => heading2XL;
  static TextStyle get headline3    => headingXL;
  static TextStyle get wordTitle    => heading2XL;
  static TextStyle get subtitle     => headingLG;
  static TextStyle get body         => textMD;
  static TextStyle get bodySecondary => textMD.copyWith(color: AppColors.textSecondaryDark);
  static TextStyle get caption      => textSM;
  static TextStyle get label        => textSMMedium;
  static TextStyle get button       => textMD.copyWith(
        fontWeight: AppTypography.weightBold,
        color: AppColors.textInverseDark,
      );
  static TextStyle get buttonOutline => textMD.copyWith(
        fontWeight: AppTypography.weightBold,
        color: AppColors.brandPrimary,
      );

  // ── Context-aware helpers ──────────────────────────────────────────────────

  static TextStyle heading3XLFor(BuildContext context) =>
      heading3XL.copyWith(color: AppColors.textPrimary(context));

  static TextStyle heading2XLFor(BuildContext context) =>
      heading2XL.copyWith(color: AppColors.textPrimary(context));

  static TextStyle headingXLFor(BuildContext context) =>
      headingXL.copyWith(color: AppColors.textPrimary(context));

  static TextStyle headingLGFor(BuildContext context) =>
      headingLG.copyWith(color: AppColors.textPrimary(context));

  static TextStyle headingMDFor(BuildContext context) =>
      headingMD.copyWith(color: AppColors.textPrimary(context));

  static TextStyle headingSMFor(BuildContext context) =>
      headingSM.copyWith(color: AppColors.textPrimary(context));

  static TextStyle textLGFor(BuildContext context) =>
      textLG.copyWith(color: AppColors.textPrimary(context));

  static TextStyle textMDFor(BuildContext context) =>
      textMD.copyWith(color: AppColors.textPrimary(context));

  static TextStyle textSMFor(BuildContext context) =>
      textSM.copyWith(color: AppColors.textSecondary(context));

  static TextStyle textXSFor(BuildContext context) =>
      textXS.copyWith(color: AppColors.textTertiary(context));

  // Legacy context-aware aliases
  static TextStyle headline1For(BuildContext context) => heading3XLFor(context);
  static TextStyle headline2For(BuildContext context) => heading2XLFor(context);
  static TextStyle headline3For(BuildContext context) => headingXLFor(context);
  static TextStyle subtitleFor(BuildContext context)  => headingLGFor(context);
  static TextStyle bodyFor(BuildContext context)      => textMDFor(context);
  static TextStyle bodySecondaryFor(BuildContext context) =>
      textMD.copyWith(color: AppColors.textSecondary(context));
  static TextStyle captionFor(BuildContext context)   => textSMFor(context);
  static TextStyle labelFor(BuildContext context)     =>
      textSMMedium.copyWith(color: AppColors.textPrimary(context));
}
