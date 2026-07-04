import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_border.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ── Shared helpers ─────────────────────────────────────────────────────────

  static TextTheme _textTheme(Color primary, Color secondary) =>
      GoogleFonts.googleSansTextTheme(
        TextTheme(
          displayLarge:  AppTextStyles.headline1.copyWith(color: primary),
          displayMedium: AppTextStyles.headline2.copyWith(color: primary),
          displaySmall:  AppTextStyles.headline3.copyWith(color: primary),
          headlineMedium: AppTextStyles.subtitle.copyWith(color: primary),
          bodyLarge:  AppTextStyles.body.copyWith(color: primary),
          bodyMedium: AppTextStyles.bodySecondary.copyWith(color: secondary),
          bodySmall:  AppTextStyles.caption.copyWith(color: secondary),
          labelLarge:  AppTextStyles.button,
          labelMedium: AppTextStyles.label.copyWith(color: primary),
        ),
      );

  static BottomNavigationBarThemeData _bottomNavTheme({
    required Color background,
    required Color selected,
    required Color unselected,
  }) =>
      BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: selected,
        unselectedItemColor: unselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.textXS.copyWith(
          fontWeight: AppTypography.weightSemibold,
          color: selected,
        ),
        unselectedLabelStyle: AppTextStyles.textXS.copyWith(
          color: unselected,
        ),
      );

  static NavigationBarThemeData _navigationBarTheme({
    required Color background,
    required Color indicator,
    required Color selected,
    required Color unselected,
  }) =>
      NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: indicator,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTextStyles.textXS.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                  color: selected,
                )
              : AppTextStyles.textXS.copyWith(color: unselected),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? IconThemeData(color: selected)
              : IconThemeData(color: unselected),
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required Color bg,
    required Color fg,
  }) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorder.mobileXl,
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color fg, Color border) =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
          foregroundColor: WidgetStatePropertyAll(fg),
          side: WidgetStatePropertyAll(BorderSide(color: border, width: 1.5)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppBorder.mobileXl),
          ),
        ),
      );

  // ── Dark ───────────────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundPrimaryDark,
        primaryColor: AppColors.brandPrimary,
        colorScheme: ColorScheme.dark(
          primary:    AppColors.brandPrimary,
          secondary:  AppColors.brandPrimary,
          surface:    AppColors.backgroundSecondaryDark,
          error:      AppColors.backgroundDangerDark,
          onPrimary:  AppColors.textInverseDark,
          onSecondary: AppColors.textInverseDark,
          onSurface:  AppColors.textPrimaryDark,
          onError:    AppColors.textInverseDark,
          outline:    AppColors.borderPrimaryDark,
        ),
        textTheme: _textTheme(
          AppColors.textPrimaryDark,
          AppColors.textSecondaryDark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundPrimaryDark,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.dark,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.backgroundPrimaryDark,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          titleTextStyle: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundSecondaryDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorder.mobileXl,
          ),
        ),
        elevatedButtonTheme: _elevatedButtonTheme(
          bg: AppColors.brandPrimary,
          fg: AppColors.textInverseDark,
        ),
        outlinedButtonTheme: _outlinedButtonTheme(
          AppColors.brandPrimary,
          AppColors.borderPrimaryDark,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandPrimary,
            textStyle: AppTextStyles.label,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderTertiaryDark,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSecondaryDark,
          border: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: const BorderSide(
              color: AppColors.borderSecondaryDark,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: const BorderSide(
              color: AppColors.brandPrimary,
              width: 1.5,
            ),
          ),
          hintStyle: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.backgroundPrimaryDark
                : AppColors.textTertiaryDark,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.brandPrimary
                : AppColors.backgroundSecondaryDark,
          ),
        ),
        bottomNavigationBarTheme: _bottomNavTheme(
          background: AppColors.backgroundPrimaryDark,
          selected: AppColors.brandPrimary,
          unselected: AppColors.textTertiaryDark,
        ),
        navigationBarTheme: _navigationBarTheme(
          background: AppColors.backgroundPrimaryDark,
          indicator: AppColors.brandPrimary.withValues(alpha: 0.15),
          selected: AppColors.brandPrimary,
          unselected: AppColors.textTertiaryDark,
        ),
      );

  // ── Light ──────────────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundPrimaryLight,
        primaryColor: AppColors.brandPrimary,
        colorScheme: ColorScheme.light(
          primary:    AppColors.brandPrimary,
          secondary:  AppColors.brandPrimary,
          surface:    AppColors.backgroundSecondaryLight,
          error:      AppColors.backgroundDangerLight,
          onPrimary:  AppColors.textInverseLight,
          onSecondary: AppColors.textInverseLight,
          onSurface:  AppColors.textPrimaryLight,
          onError:    AppColors.textInverseLight,
          outline:    AppColors.borderPrimaryLight,
        ),
        textTheme: _textTheme(
          AppColors.textPrimaryLight,
          AppColors.textSecondaryLight,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundPrimaryLight,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.backgroundPrimaryLight,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          titleTextStyle: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundSecondaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorder.mobileXl,
          ),
        ),
        elevatedButtonTheme: _elevatedButtonTheme(
          bg: AppColors.brandPrimary,
          fg: AppColors.textInverseLight,
        ),
        outlinedButtonTheme: _outlinedButtonTheme(
          AppColors.brandPrimary,
          AppColors.borderPrimaryLight,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandPrimary,
            textStyle: AppTextStyles.label.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderTertiaryLight,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundSecondaryLight,
          border: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: const BorderSide(
              color: AppColors.borderSecondaryLight,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppBorder.mobileMd,
            borderSide: const BorderSide(
              color: AppColors.brandPrimary,
              width: 1.5,
            ),
          ),
          hintStyle: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.backgroundPrimaryLight
                : AppColors.textTertiaryLight,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.brandPrimary
                : AppColors.backgroundSecondaryLight,
          ),
        ),
        bottomNavigationBarTheme: _bottomNavTheme(
          background: AppColors.backgroundPrimaryLight,
          selected: AppColors.brandPrimary,
          unselected: AppColors.textTertiaryLight,
        ),
        navigationBarTheme: _navigationBarTheme(
          background: AppColors.backgroundPrimaryLight,
          indicator: AppColors.brandPrimary.withValues(alpha: 0.12),
          selected: AppColors.brandPrimary,
          unselected: AppColors.textTertiaryLight,
        ),
      );
}
