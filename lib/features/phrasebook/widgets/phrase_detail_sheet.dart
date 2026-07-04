import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/services/tts_service.dart';
import '../models/phrase.dart';

/// Bottom sheet showing a phrase's translation + full AI explanation
/// (FR-1.4 / FR-2.5). Used both for fresh translation results and for
/// reopening saved phrases. When [onRecategorize]/[onDelete] are provided,
/// phrasebook management actions are shown; otherwise a "Saved to
/// Phrasebook" footer note is displayed.
class PhraseDetailSheet extends ConsumerWidget {
  final Phrase phrase;
  final VoidCallback? onRecategorize;
  final VoidCallback? onDelete;

  const PhraseDetailSheet({
    super.key,
    required this.phrase,
    this.onRecategorize,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Phrase phrase,
    VoidCallback? onRecategorize,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhraseDetailSheet(
        phrase: phrase,
        onRecategorize: onRecategorize,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(pronunciationPlayerProvider);
    final lowConfidence = phrase.confidence != 'high';
    final hasActions = onRecategorize != null || onDelete != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSecondary(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Chip row ─────────────────────────────────────────────
                    Row(
                      children: [
                        _CategoryChip(category: phrase.category),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => player.speak(
                            phrase.translatedText,
                            phrase.targetLang,
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CoolIcons.volume_max,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Translated phrase ────────────────────────────────────
                    Text(
                      phrase.translatedText,
                      style: GoogleFonts.chauPhilomeneOne(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        height: 1.15,
                      ),
                    ),

                    if ((phrase.phonetic ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        phrase.phonetic!,
                        style: GoogleFonts.googleSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Text(
                      '"${phrase.sourceText}"',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary(context),
                        height: 1.5,
                      ),
                    ),

                    // ── Low-confidence warning (FR-1.6) ──────────────────────
                    if (lowConfidence) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWarning(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderWarning(context),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CoolIcons.triangle_warning,
                              size: 18,
                              color: AppColors.textWarning(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                phrase.confidenceNote ??
                                    'Double-check this one — the translation may not be the most natural phrasing.',
                                style: GoogleFonts.googleSans(
                                  fontSize: 13,
                                  color: AppColors.textWarning(context),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Register note (FR-1.3) ───────────────────────────────
                    if ((phrase.registerNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When to use it',
                              style: GoogleFonts.googleSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              phrase.registerNote!,
                              style: GoogleFonts.googleSans(
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Collapsible explanation sections (FR-1.4) ────────────
                    if (phrase.vocabBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _ExplanationSection(
                        title: 'Vocabulary breakdown',
                        initiallyExpanded: true,
                        child: Column(
                          children: phrase.vocabBreakdown
                              .map((entry) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimary
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: AppColors.brandPrimary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            entry.term,
                                            style: GoogleFonts.googleSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.brandPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: 5),
                                            child: Text(
                                              entry.meaning,
                                              style: GoogleFonts.googleSans(
                                                fontSize: 13,
                                                color: AppColors.textSecondary(
                                                    context),
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    if ((phrase.grammarNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ExplanationSection(
                        title: 'Grammar note',
                        child: Text(
                          phrase.grammarNote!,
                          style: GoogleFonts.googleSans(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],

                    if ((phrase.phonetic ?? '').isNotEmpty ||
                        (phrase.ipa ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ExplanationSection(
                        title: 'Pronunciation',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((phrase.phonetic ?? '').isNotEmpty)
                              _PronunciationRow(
                                label: 'Sounds like',
                                value: phrase.phonetic!,
                              ),
                            if ((phrase.ipa ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _PronunciationRow(
                                label: 'IPA',
                                value: phrase.ipa!,
                              ),
                            ],
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => player.speak(
                                phrase.translatedText,
                                phrase.targetLang,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.backgroundSecondary(context),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color:
                                        AppColors.borderSecondary(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CoolIcons.volume_max,
                                      size: 18,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Play audio',
                                      style: GoogleFonts.googleSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: hasActions
                    ? Row(
                        children: [
                          if (onRecategorize != null)
                            Expanded(
                              child: _SheetActionButton(
                                label: 'Re-categorize',
                                icon: CoolIcons.folder_edit,
                                onTap: onRecategorize!,
                              ),
                            ),
                          if (onRecategorize != null && onDelete != null)
                            const SizedBox(width: 12),
                          if (onDelete != null)
                            Expanded(
                              child: _SheetActionButton(
                                label: 'Delete',
                                icon: CoolIcons.trash_empty,
                                destructive: true,
                                onTap: onDelete!,
                              ),
                            ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CoolIcons.circle_check,
                            size: 18,
                            color: AppColors.textSuccess(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saved to Phrasebook · ${phrase.category.label}',
                            style: GoogleFonts.googleSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final PhraseCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: GoogleFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collapsible explanation section ───────────────────────────────────────────

class _ExplanationSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _ExplanationSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderTertiary(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(),
          iconColor: AppColors.textSecondary(context),
          collapsedIconColor: AppColors.textTertiary(context),
          title: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.googleSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          children: [
            Align(alignment: Alignment.centerLeft, child: child),
          ],
        ),
      ),
    );
  }
}

class _PronunciationRow extends StatelessWidget {
  final String label;
  final String value;
  const _PronunciationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.googleSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer action button ──────────────────────────────────────────────────────

class _SheetActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.textDanger(context)
        : AppColors.textPrimary(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 47,
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.backgroundDanger(context)
              : AppColors.backgroundSecondary(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: destructive
                ? AppColors.borderDanger(context)
                : AppColors.borderSecondary(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
