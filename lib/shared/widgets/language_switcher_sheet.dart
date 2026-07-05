import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/languages.dart';

/// Bottom sheet for picking the active practicing language. Pure UI — the
/// caller supplies [currentCode] and an [onSelect] callback that performs
/// the actual switch (and any related side effects, e.g. seeding a
/// never-before-practiced language). Used identically from Translate,
/// Phrasebook, and Review so the app has one consistent "switch language"
/// interaction everywhere.
Future<void> showLanguageSwitcherSheet(
  BuildContext context, {
  required String? currentCode,
  required ValueChanged<String> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.backgroundPrimary(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practicing',
                  style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(sheetContext),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: kTargetLanguages.map((lang) {
                      final selected = lang.code == currentCode;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            if (!selected) onSelect(lang.code);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brandPrimary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  lang.flag,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lang.label,
                                    style: GoogleFonts.googleSans(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: AppColors.textPrimary(sheetContext),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check,
                                    size: 18,
                                    color: AppColors.brandPrimary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The flag + language-name pill that opens [showLanguageSwitcherSheet].
/// Falls back to the first catalog language while [code] is null (e.g.
/// briefly during onboarding before a language has been chosen).
class LanguagePill extends StatelessWidget {
  final String? code;
  final VoidCallback onTap;

  const LanguagePill({super.key, required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final language = targetLanguageForCode(code) ?? kTargetLanguages.first;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderSecondary(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              language.label,
              style: GoogleFonts.googleSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textTertiary(context),
            ),
          ],
        ),
      ),
    );
  }
}
