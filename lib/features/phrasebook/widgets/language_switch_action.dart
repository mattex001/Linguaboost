import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/constants/languages.dart';
import '../../../core/providers/user_provider.dart';
import '../providers/phrasebook_provider.dart';

/// Switches the active practicing language everywhere in the app — Translate,
/// Phrasebook, Review, and Home all read [activeLanguageCodeProvider], so
/// this one action is what every language switcher (Translate's header pill,
/// Phrasebook's, Review's) calls from [showLanguageSwitcherSheet]'s onSelect.
///
/// If the user has never saved a phrase in [code] before, re-runs the same
/// 8-phrase seed flow used at onboarding, so switching to a fresh language
/// doesn't leave the phrasebook empty.
Future<void> switchActiveLanguage(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  final uid = ref.read(authUserIdProvider);
  if (uid == null) return;

  final alreadyHasPhrases = ref
      .read(phrasesSnapshotProvider)
      .any((p) => p.targetLang == code);

  await ref.read(userRepositoryProvider).updateTargetLanguage(uid, code);
  if (alreadyHasPhrases) return;

  final label = targetLanguageForCode(code)?.label ?? 'this language';
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Setting up your $label phrasebook…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  try {
    await Supabase.instance.client.functions.invoke(
      'seed-phrasebook',
      body: {'targetLang': code},
    );
  } catch (e) {
    debugPrint('seed-phrasebook failed (non-blocking): $e');
  }
}
