import 'package:flutter/material.dart';

/// Figma design token colours — mirrors the Variables panel exactly.
///
/// Static raw values follow the naming convention:
///   [group][Token][Light|Dark]
/// e.g. `backgroundPrimaryLight`, `textDangerDark`.
///
/// Context-resolved helpers (e.g. [AppColors.backgroundPrimary]) pick the
/// correct value from the current [BuildContext] automatically.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Brand (same in both modes)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color brandPrimary = Color(0xFF8471F4);

  // ═══════════════════════════════════════════════════════════════════════════
  // Background
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary
  static const Color backgroundPrimaryLight = Color(0xFFFFFFFF);
  static const Color backgroundPrimaryDark  = Color(0xFF30302E);

  // Secondary
  static const Color backgroundSecondaryLight = Color(0xFFF5F4ED);
  static const Color backgroundSecondaryDark  = Color(0xFF262624);

  // Tertiary
  static const Color backgroundTertiaryLight = Color(0xFFFAF9F5);
  static const Color backgroundTertiaryDark  = Color(0xFF141413);

  // Inverse
  static const Color backgroundInverseLight = Color(0xFF141413);
  static const Color backgroundInverseDark  = Color(0xFFFAF9F5);

  // Ghost (0 % opacity — fully transparent)
  static const Color backgroundGhostLight = Color(0x00FFFFFF);
  static const Color backgroundGhostDark  = Color(0x0030302E);

  // Info
  static const Color backgroundInfoLight = Color(0xFFD6E4F6);
  static const Color backgroundInfoDark  = Color(0xFF253E5F);

  // Danger
  static const Color backgroundDangerLight = Color(0xFFFFF1F1);
  static const Color backgroundDangerDark  = Color(0xFF3B1919);

  // Success
  static const Color backgroundSuccessLight = Color(0xFFF2FFDC);
  static const Color backgroundSuccessDark  = Color(0xFF1B4614);

  // Warning
  static const Color backgroundWarningLight = Color(0xFFF9ECEC);
  static const Color backgroundWarningDark  = Color(0xFF483A0F);

  // Disabled (50 % opacity)
  static const Color backgroundDisabledLight = Color(0x80FFFFFF);
  static const Color backgroundDisabledDark  = Color(0x8030302E);

  // Other cards
  static const Color backgroundOtherCardsLight = Color(0xFFF0EEE6);
  static const Color backgroundOtherCardsDark  = Color(0xFF141413);

  // ═══════════════════════════════════════════════════════════════════════════
  // Text
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary
  static const Color textPrimaryLight = Color(0xFF141413);
  static const Color textPrimaryDark  = Color(0xFFFAF9F5);

  // Secondary
  static const Color textSecondaryLight = Color(0xFF3D3D3A);
  static const Color textSecondaryDark  = Color(0xFFC2C0B6);

  // Tertiary
  static const Color textTertiaryLight = Color(0xFF73726C);
  static const Color textTertiaryDark  = Color(0xFF9C9A92);

  // Inverse
  static const Color textInverseLight = Color(0xFFFFFFFF);
  static const Color textInverseDark  = Color(0xFF141413);

  // Info
  static const Color textInfoLight = Color(0xFF3266AD);
  static const Color textInfoDark  = Color(0xFF80AADD);

  // Danger
  static const Color textDangerLight = Color(0xFFD93025);
  static const Color textDangerDark  = Color(0xFFFC8181);

  // Success
  static const Color textSuccessLight = Color(0xFF265B19);
  static const Color textSuccessDark  = Color(0xFF7AB948);

  // Warning
  static const Color textWarningLight = Color(0xFF5A4815);
  static const Color textWarningDark  = Color(0xFFD1A041);

  // Disabled (50 % opacity)
  static const Color textDisabledLight = Color(0x80141413);
  static const Color textDisabledDark  = Color(0x80FAF9F5);

  // Ghost (50 % opacity)
  static const Color textGhostLight = Color(0x8073726C);
  static const Color textGhostDark  = Color(0x809C9A92);

  // Brand-Primary (same in both modes)
  static const Color textBrandPrimary = Color(0xFF8471F4);

  // ═══════════════════════════════════════════════════════════════════════════
  // Border
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary (40 %)
  static const Color borderPrimaryLight = Color(0x661F1E1D);
  static const Color borderPrimaryDark  = Color(0x66DEDCD1);

  // Secondary (30 %)
  static const Color borderSecondaryLight = Color(0x4D1F1E1D);
  static const Color borderSecondaryDark  = Color(0x4DDEDCD1);

  // Tertiary (15 %)
  static const Color borderTertiaryLight = Color(0x261F1E1D);
  static const Color borderTertiaryDark  = Color(0x26DEDCD1);

  // Inverse — Light 30 %, Dark 15 %
  static const Color borderInverseLight = Color(0x4DFFFFFF);
  static const Color borderInverseDark  = Color(0x26141413);

  // Ghost (0 %)
  static const Color borderGhostLight = Color(0x001F1E1D);
  static const Color borderGhostDark  = Color(0x00DEDCD1);

  // Info
  static const Color borderInfoLight = Color(0xFF4682D5);
  static const Color borderInfoDark  = Color(0xFF4682D5);

  // Danger
  static const Color borderDangerLight = Color(0xFFF87171);
  static const Color borderDangerDark  = Color(0xFFEF4444);

  // Success
  static const Color borderSuccessLight = Color(0xFF437426);
  static const Color borderSuccessDark  = Color(0xFF599130);

  // Warning
  static const Color borderWarningLight = Color(0xFF805C1F);
  static const Color borderWarningDark  = Color(0xFFA87829);

  // Disabled (10 %)
  static const Color borderDisabledLight = Color(0x1A1F1E1D);
  static const Color borderDisabledDark  = Color(0x1ADEDCD1);

  // ═══════════════════════════════════════════════════════════════════════════
  // Ring
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary (70 %)
  static const Color ringPrimaryLight = Color(0xB3141413);
  static const Color ringPrimaryDark  = Color(0xB3FAF9F5);

  // Secondary (70 %)
  static const Color ringSecondaryLight = Color(0xB33D3D3A);
  static const Color ringSecondaryDark  = Color(0xB3C2C0B6);

  // Inverse (70 %)
  static const Color ringInverseLight = Color(0xB3FFFFFF);
  static const Color ringInverseDark  = Color(0xB3141413);

  // Info (50 %)
  static const Color ringInfoLight = Color(0x803266AD);
  static const Color ringInfoDark  = Color(0x8080AADD);

  // Danger (50 %)
  static const Color ringDangerLight = Color(0x80A73D39);
  static const Color ringDangerDark  = Color(0x80CD5C58);

  // Success (50 %)
  static const Color ringSuccessLight = Color(0x80437426);
  static const Color ringSuccessDark  = Color(0x80599130);

  // Warning (50 %)
  static const Color ringWarningLight = Color(0x80805C1F);
  static const Color ringWarningDark  = Color(0x80A87829);

  // ═══════════════════════════════════════════════════════════════════════════
  // Context-resolved helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Background
  static Color backgroundPrimary(BuildContext context) =>
      _isDark(context) ? backgroundPrimaryDark : backgroundPrimaryLight;

  static Color backgroundSecondary(BuildContext context) =>
      _isDark(context) ? backgroundSecondaryDark : backgroundSecondaryLight;

  static Color backgroundTertiary(BuildContext context) =>
      _isDark(context) ? backgroundTertiaryDark : backgroundTertiaryLight;

  static Color backgroundInverse(BuildContext context) =>
      _isDark(context) ? backgroundInverseDark : backgroundInverseLight;

  static Color backgroundInfo(BuildContext context) =>
      _isDark(context) ? backgroundInfoDark : backgroundInfoLight;

  static Color backgroundDanger(BuildContext context) =>
      _isDark(context) ? backgroundDangerDark : backgroundDangerLight;

  static Color backgroundSuccess(BuildContext context) =>
      _isDark(context) ? backgroundSuccessDark : backgroundSuccessLight;

  static Color backgroundWarning(BuildContext context) =>
      _isDark(context) ? backgroundWarningDark : backgroundWarningLight;

  static Color backgroundDisabled(BuildContext context) =>
      _isDark(context) ? backgroundDisabledDark : backgroundDisabledLight;

  static Color backgroundOtherCards(BuildContext context) =>
      _isDark(context) ? backgroundOtherCardsDark : backgroundOtherCardsLight;

  // Text
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textTertiary(BuildContext context) =>
      _isDark(context) ? textTertiaryDark : textTertiaryLight;

  static Color textInverse(BuildContext context) =>
      _isDark(context) ? textInverseDark : textInverseLight;

  static Color textInfo(BuildContext context) =>
      _isDark(context) ? textInfoDark : textInfoLight;

  static Color textDanger(BuildContext context) =>
      _isDark(context) ? textDangerDark : textDangerLight;

  static Color textSuccess(BuildContext context) =>
      _isDark(context) ? textSuccessDark : textSuccessLight;

  static Color textWarning(BuildContext context) =>
      _isDark(context) ? textWarningDark : textWarningLight;

  static Color textDisabled(BuildContext context) =>
      _isDark(context) ? textDisabledDark : textDisabledLight;

  static Color textGhost(BuildContext context) =>
      _isDark(context) ? textGhostDark : textGhostLight;

  // Border
  static Color borderPrimary(BuildContext context) =>
      _isDark(context) ? borderPrimaryDark : borderPrimaryLight;

  static Color borderSecondary(BuildContext context) =>
      _isDark(context) ? borderSecondaryDark : borderSecondaryLight;

  static Color borderTertiary(BuildContext context) =>
      _isDark(context) ? borderTertiaryDark : borderTertiaryLight;

  static Color borderInverse(BuildContext context) =>
      _isDark(context) ? borderInverseDark : borderInverseLight;

  static Color borderInfo(BuildContext context) =>
      _isDark(context) ? borderInfoDark : borderInfoLight;

  static Color borderDanger(BuildContext context) =>
      _isDark(context) ? borderDangerDark : borderDangerLight;

  static Color borderSuccess(BuildContext context) =>
      _isDark(context) ? borderSuccessDark : borderSuccessLight;

  static Color borderWarning(BuildContext context) =>
      _isDark(context) ? borderWarningDark : borderWarningLight;

  static Color borderDisabled(BuildContext context) =>
      _isDark(context) ? borderDisabledDark : borderDisabledLight;

  // Ring
  static Color ringPrimary(BuildContext context) =>
      _isDark(context) ? ringPrimaryDark : ringPrimaryLight;

  static Color ringSecondary(BuildContext context) =>
      _isDark(context) ? ringSecondaryDark : ringSecondaryLight;

  static Color ringInverse(BuildContext context) =>
      _isDark(context) ? ringInverseDark : ringInverseLight;

  static Color ringInfo(BuildContext context) =>
      _isDark(context) ? ringInfoDark : ringInfoLight;

  static Color ringDanger(BuildContext context) =>
      _isDark(context) ? ringDangerDark : ringDangerLight;

  static Color ringSuccess(BuildContext context) =>
      _isDark(context) ? ringSuccessDark : ringSuccessLight;

  static Color ringWarning(BuildContext context) =>
      _isDark(context) ? ringWarningDark : ringWarningLight;
}
