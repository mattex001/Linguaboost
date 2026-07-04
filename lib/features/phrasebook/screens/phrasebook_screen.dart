import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cool_icons.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/phrase.dart';
import '../providers/phrasebook_provider.dart';
import '../widgets/phrase_detail_sheet.dart';

/// Phrasebook tab: browse, search, and manage every saved phrase (FR-2.x).
class PhrasebookScreen extends ConsumerStatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  ConsumerState<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends ConsumerState<PhrasebookScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = ref.watch(filteredPhrasesProvider);
    final total = ref.watch(phrasesSavedCountProvider);
    final selectedCategory = ref.watch(phraseCategoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phrasebook',
                    style: GoogleFonts.chauPhilomeneOne(
                      fontSize: 28,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 1 ? '1 phrase saved' : '$total phrases saved',
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      color: AppColors.textTertiary(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Search (FR-2.4) ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderTertiary(context)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => ref
                      .read(phraseSearchQueryProvider.notifier)
                      .setQuery(value),
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search in English or your language',
                    hintStyle: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textTertiary(context),
                    ),
                    prefixIcon: Icon(
                      CoolIcons.search_magnifying_glass,
                      size: 20,
                      color: AppColors.textTertiary(context),
                    ),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Category chips (FR-2.3) ───────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _CategoryFilterChip(
                    label: 'All',
                    icon: null,
                    selected: selectedCategory == null,
                    onTap: () => ref
                        .read(phraseCategoryFilterProvider.notifier)
                        .select(null),
                  ),
                  ...PhraseCategory.values.map(
                    (category) => _CategoryFilterChip(
                      label: category.label,
                      icon: category.icon,
                      selected: selectedCategory == category,
                      onTap: () => ref
                          .read(phraseCategoryFilterProvider.notifier)
                          .select(
                            selectedCategory == category ? null : category,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Phrase list ───────────────────────────────────────────────
            Expanded(
              child: phrases.isEmpty
                  ? _EmptyState(hasAnyPhrases: total > 0)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                      itemCount: phrases.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final phrase = phrases[index];
                        return _PhraseCard(
                          phrase: phrase,
                          onTap: () => _openPhrase(phrase),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhrase(Phrase phrase) {
    PhraseDetailSheet.show(
      context,
      phrase: phrase,
      onRecategorize: () {
        Navigator.of(context).pop();
        _showRecategorizeSheet(phrase);
      },
      onDelete: () {
        Navigator.of(context).pop();
        _confirmDelete(phrase);
      },
    );
  }

  void _showRecategorizeSheet(Phrase phrase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSecondary(sheetContext),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Move to category',
              style: GoogleFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(sheetContext),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                children: PhraseCategory.values.map((category) {
                  final selected = category == phrase.category;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(
                      category.icon,
                      size: 22,
                      color: selected
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary(sheetContext),
                    ),
                    title: Text(
                      category.label,
                      style: GoogleFonts.googleSans(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? AppColors.brandPrimary
                            : AppColors.textPrimary(sheetContext),
                      ),
                    ),
                    trailing: selected
                        ? const Icon(CoolIcons.check,
                            size: 20, color: AppColors.brandPrimary)
                        : null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(phraseRepositoryProvider)
                          .updateCategory(phrase.id, category);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Phrase phrase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(sheetContext),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete this phrase?',
              style: GoogleFonts.googleSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(sheetContext),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${phrase.sourceText}" will be removed from your phrasebook and review queue.',
              textAlign: TextAlign.center,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textTertiary(sheetContext),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 47,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await ref
                      .read(phraseRepositoryProvider)
                      .deletePhrase(phrase.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDanger(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.googleSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(sheetContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phrase card ───────────────────────────────────────────────────────────────

class _PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final VoidCallback onTap;

  const _PhraseCard({required this.phrase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderTertiary(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.sourceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phrase.translatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        phrase.category.icon,
                        size: 13,
                        color: AppColors.textTertiary(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        phrase.category.label,
                        style: GoogleFonts.googleSans(
                          fontSize: 12,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                      if (phrase.isDue) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Due',
                          style: GoogleFonts.googleSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              CoolIcons.chevron_right,
              size: 20,
              color: AppColors.textTertiary(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category filter chip ──────────────────────────────────────────────────────

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPrimary
                : AppColors.backgroundPrimary(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : AppColors.borderSecondary(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color:
                      selected ? Colors.white : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.googleSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected ? Colors.white : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final bool hasAnyPhrases;
  const _EmptyState({required this.hasAnyPhrases});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasAnyPhrases
                  ? CoolIcons.search_magnifying_glass
                  : CoolIcons.book_open,
              size: 40,
              color: AppColors.textTertiary(context),
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyPhrases ? 'No matches' : 'No phrases yet',
              style: GoogleFonts.googleSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyPhrases
                  ? 'Try a different search or category.'
                  : 'Translate something you need to say and it will be saved here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textTertiary(context),
                height: 1.5,
              ),
            ),
            if (!hasAnyPhrases) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () =>
                    ref.read(activeNavTabProvider.notifier).setTab(1),
                child: Container(
                  width: 179,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF141413),
                        blurRadius: 0,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Translate a phrase',
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
