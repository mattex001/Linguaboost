import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';

// ── Theme definitions ─────────────────────────────────────────────────────────

class _ThemeDef {
  final String name;
  final String? assetPath; // null = Default (no background)
  const _ThemeDef(this.name, this.assetPath);
}

const _kThemes = [
  _ThemeDef('Default', null),
  _ThemeDef('Metrop', 'assets/backgrounds/bg_metrop.png'),
  _ThemeDef('Volcanic', 'assets/backgrounds/bg_volcanic.png'),
  _ThemeDef('Castro', 'assets/backgrounds/bg_castro.png'),
  _ThemeDef('Fury', 'assets/backgrounds/bg_fury.png'),
  _ThemeDef('Sans', 'assets/backgrounds/bg_sans.png'),
];

// Keep a parallel list that maps from backgroundThemeProvider index → asset path
// index -1 = Default, 0 = Metrop, 1 = Volcanic, 2 = Castro, 3 = Fury, 4 = Sans
const kBgThemeAssets = [
  'assets/backgrounds/bg_metrop.png',
  'assets/backgrounds/bg_volcanic.png',
  'assets/backgrounds/bg_castro.png',
  'assets/backgrounds/bg_fury.png',
  'assets/backgrounds/bg_sans.png',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeThemesScreen extends ConsumerStatefulWidget {
  const HomeThemesScreen({super.key});

  @override
  ConsumerState<HomeThemesScreen> createState() => _HomeThemesScreenState();
}

class _HomeThemesScreenState extends ConsumerState<HomeThemesScreen> {
  late int _selected; // -1 = Default, 0–4 = theme index

  @override
  void initState() {
    super.initState();
    _selected = ref.read(backgroundThemeProvider);
  }

  bool get _hasChange => _selected != ref.read(backgroundThemeProvider);

  void _save() {
    if (!_hasChange) return;
    ref.read(backgroundThemeProvider.notifier).select(_selected);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: AppColors.textPrimary(context),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // ── Title block ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home themes',
                    style: GoogleFonts.googleSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 25 / 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your preferred background',
                    style: GoogleFonts.googleSans(
                      fontSize: 14,
                      color: AppColors.textTertiary(context),
                      height: 19.6 / 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Theme grid ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 104.5 / 208.5,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: List.generate(_kThemes.length, (i) {
                    final theme = _kThemes[i];
                    // index in provider: Default = -1, others = i - 1
                    final providerIndex = i - 1;
                    final isSelected = _selected == providerIndex;

                    return GestureDetector(
                      onTap: () => setState(() => _selected = providerIndex),
                      child: _ThemeCard(
                        theme: theme,
                        isSelected: isSelected,
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ── Save button ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Center(
                child: Opacity(
                  opacity: _hasChange ? 1.0 : 0.4,
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: 179,
                      height: 47,
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
                          'Save',
                          style: GoogleFonts.googleSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 22.4 / 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final _ThemeDef theme;
  final bool isSelected;

  const _ThemeCard({required this.theme, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDefault = theme.assetPath == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ────────────────────────────────────────────────────
          if (isDefault)
            Container(color: AppColors.backgroundSecondary(context))
          else
            Image.asset(
              theme.assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF141413),
              ),
            ),

          // ── Name label ────────────────────────────────────────────────────
          Positioned(
            left: 10,
            bottom: 12,
            child: Text(
              theme.name,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDefault
                    ? AppColors.textPrimary(context)
                    : Colors.white,
                height: 25 / 14,
              ),
            ),
          ),

          // ── Selected checkmark ────────────────────────────────────────────
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          // ── Selection border ──────────────────────────────────────────────
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
