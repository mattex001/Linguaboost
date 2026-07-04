import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/personalization_widgets.dart';

class WhatIsYourGoalScreen extends ConsumerStatefulWidget {
  const WhatIsYourGoalScreen({super.key});

  @override
  ConsumerState<WhatIsYourGoalScreen> createState() =>
      _WhatIsYourGoalScreenState();
}

class _WhatIsYourGoalScreenState extends ConsumerState<WhatIsYourGoalScreen> {
  String? _selected;

  Future<void> _continue() async {
    final goal = _selected;
    if (goal == null) return;

    final uid = ref.read(authStateProvider).asData?.value?.id;
    if (uid != null) {
      // Fire-and-forget — the goal is motivational copy, not load-bearing.
      ref.read(userRepositoryProvider).updateLearningGoal(uid, goal);
    }
    if (!mounted) return;
    context.push(AppRoutes.personalizationJustAMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTertiary(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            const PersonalizationHeader(),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What brings you here?',
                      style: GoogleFonts.googleSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 36 / 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
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
                  ],
                ),
              ),
            ),

            // ── Continue button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: PersonalizationPrimaryButton(
                label: 'Continue',
                enabled: _selected != null,
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
