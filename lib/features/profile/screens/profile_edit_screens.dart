import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/cool_icons.dart';
import '../../../core/constants/languages.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../features/personalization/widgets/personalization_widgets.dart';

// ── Shared edit scaffold ──────────────────────────────────────────────────────

class _EditScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final bool canSave;
  final VoidCallback onSave;

  const _EditScaffold({
    required this.title,
    this.subtitle,
    required this.body,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(CoolIcons.chevron_left, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.googleSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.googleSans(
                        fontSize: 14,
                        color: AppColors.textTertiary(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                child: body,
              ),
            ),

            // ── Save button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: PersonalizationPrimaryButton(
                label: 'Save changes',
                enabled: canSave,
                onTap: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Edit Target Language
// ─────────────────────────────────────────────────────────────────────────────

class EditTargetLanguageScreen extends ConsumerStatefulWidget {
  const EditTargetLanguageScreen({super.key});

  @override
  ConsumerState<EditTargetLanguageScreen> createState() =>
      _EditTargetLanguageScreenState();
}

class _EditTargetLanguageScreenState
    extends ConsumerState<EditTargetLanguageScreen> {
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(userSnapshotProvider)?.targetLanguage;
  }

  Future<void> _save() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid != null) {
      await ref
          .read(userRepositoryProvider)
          .updateTargetLanguage(uid, _selected!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Which language are you learning?',
      subtitle:
          'New translations will use this language. Saved phrases keep theirs.',
      canSave: _selected != null && !_saving,
      onSave: _save,
      body: Column(
        children: kTargetLanguages.map((language) {
          final selected = _selected == language.code;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PersonalizationOptionRow(
              label: '${language.flag}  ${language.label} · ${language.nativeLabel}',
              selected: selected,
              onTap: () => setState(() => _selected = language.code),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Edit Learning Goal
// ─────────────────────────────────────────────────────────────────────────────

class EditLearningGoalScreen extends ConsumerStatefulWidget {
  const EditLearningGoalScreen({super.key});

  @override
  ConsumerState<EditLearningGoalScreen> createState() =>
      _EditLearningGoalScreenState();
}

class _EditLearningGoalScreenState
    extends ConsumerState<EditLearningGoalScreen> {
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userSnapshotProvider)?.learningGoal;
    _selected = (current?.isNotEmpty ?? false) ? current : null;
  }

  Future<void> _save() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid != null) {
      await ref
          .read(userRepositoryProvider)
          .updateLearningGoal(uid, _selected!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'What brings you here?',
      canSave: _selected != null && !_saving,
      onSave: _save,
      body: Column(
        children: AppConstants.goals.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PersonalizationOptionRow(
              label: option,
              selected: _selected == option,
              onTap: () => setState(() => _selected = option),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Edit Name ─────────────────────────────────────────────────────────────────

class EditNameScreen extends ConsumerStatefulWidget {
  const EditNameScreen({super.key});

  @override
  ConsumerState<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends ConsumerState<EditNameScreen> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(userSnapshotProvider)?.name ?? '';
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _controller.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid != null) {
      await ref
          .read(userRepositoryProvider)
          .updateName(uid, _controller.text.trim());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _EditScaffold(
      title: 'Your name',
      subtitle: 'This is how you\'ll appear across the app.',
      canSave: _canSave,
      onSave: _save,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSecondary(context)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.googleSans(
                    fontSize: 16,
                    color: AppColors.textGhost(context),
                  ),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, val, _) => val.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _controller.clear(),
                            child: Icon(Icons.cancel_rounded,
                                size: 18,
                                color: AppColors.textTertiary(context)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
