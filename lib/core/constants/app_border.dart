import 'package:flutter/material.dart';

/// Figma Border collection — Radius and Width tokens.
///
/// Usage:
///   borderRadius: AppBorder.radiusMD          // → BorderRadius
///   borderRadius: AppBorder.mobileRadiusLG    // → BorderRadius
///   side: BorderSide(width: AppBorder.width)
class AppBorder {
  AppBorder._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Radius — base scale
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusXS   = 4;
  static const double radiusSM   = 6;
  static const double radiusMD   = 8;
  static const double radiusLG   = 10;
  static const double radiusXL   = 12;
  static const double radiusFull = 999;

  // BorderRadius convenience getters
  static BorderRadius get xs   => BorderRadius.circular(radiusXS);
  static BorderRadius get sm   => BorderRadius.circular(radiusSM);
  static BorderRadius get md   => BorderRadius.circular(radiusMD);
  static BorderRadius get lg   => BorderRadius.circular(radiusLG);
  static BorderRadius get xl   => BorderRadius.circular(radiusXL);
  static BorderRadius get full => BorderRadius.circular(radiusFull);

  // Radius objects (for ClipRRect, etc.)
  static Radius get xsRadius   => const Radius.circular(radiusXS);
  static Radius get smRadius   => const Radius.circular(radiusSM);
  static Radius get mdRadius   => const Radius.circular(radiusMD);
  static Radius get lgRadius   => const Radius.circular(radiusLG);
  static Radius get xlRadius   => const Radius.circular(radiusXL);
  static Radius get fullRadius => const Radius.circular(radiusFull);

  // ═══════════════════════════════════════════════════════════════════════════
  // Radius / Mobile
  // ═══════════════════════════════════════════════════════════════════════════

  static const double mobileNone       = 0;
  static const double mobileXXS        = 2;
  static const double mobileXS         = 4;
  static const double mobileSM         = 8;
  static const double mobileMD         = 10;
  static const double mobileLG         = 14;
  static const double mobileXL         = 24;
  static const double mobileFull       = 9999;

  // BorderRadius convenience getters
  static BorderRadius get mobileNoneRadius  => BorderRadius.zero;
  static BorderRadius get mobileXxs        => BorderRadius.circular(mobileXXS);
  static BorderRadius get mobileXs         => BorderRadius.circular(mobileXS);
  static BorderRadius get mobileSm         => BorderRadius.circular(mobileSM);
  static BorderRadius get mobileMd         => BorderRadius.circular(mobileMD);
  static BorderRadius get mobileLg         => BorderRadius.circular(mobileLG);
  static BorderRadius get mobileXl         => BorderRadius.circular(mobileXL);
  static BorderRadius get mobileFullRadius => BorderRadius.circular(mobileFull);

  // ═══════════════════════════════════════════════════════════════════════════
  // Width
  // ═══════════════════════════════════════════════════════════════════════════

  static const double width = 1;
}
