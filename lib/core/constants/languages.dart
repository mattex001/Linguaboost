/// Target-language catalog. Single source of truth for the language picker,
/// TTS locale mapping, and labels. Mirrored server-side in
/// supabase/functions/_shared/taxonomy.ts (SUPPORTED_LANGS) — keep in sync.
class TargetLanguage {
  final String code; // ISO 639-1, e.g. 'es'
  final String label; // English name
  final String nativeLabel; // name in the language itself
  final String ttsLocale; // flutter_tts locale, e.g. 'es-ES'
  final String flag; // emoji flag

  const TargetLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.ttsLocale,
    required this.flag,
  });
}

const List<TargetLanguage> kTargetLanguages = [
  TargetLanguage(
    code: 'es',
    label: 'Spanish',
    nativeLabel: 'Español',
    ttsLocale: 'es-ES',
    flag: '🇪🇸',
  ),
  TargetLanguage(
    code: 'fr',
    label: 'French',
    nativeLabel: 'Français',
    ttsLocale: 'fr-FR',
    flag: '🇫🇷',
  ),
  TargetLanguage(
    code: 'pt',
    label: 'Portuguese',
    nativeLabel: 'Português',
    ttsLocale: 'pt-BR',
    flag: '🇧🇷',
  ),
  TargetLanguage(
    code: 'de',
    label: 'German',
    nativeLabel: 'Deutsch',
    ttsLocale: 'de-DE',
    flag: '🇩🇪',
  ),
  TargetLanguage(
    code: 'it',
    label: 'Italian',
    nativeLabel: 'Italiano',
    ttsLocale: 'it-IT',
    flag: '🇮🇹',
  ),
  TargetLanguage(
    code: 'sw',
    label: 'Swahili',
    nativeLabel: 'Kiswahili',
    ttsLocale: 'sw-KE',
    flag: '🇰🇪',
  ),
];

TargetLanguage? targetLanguageForCode(String? code) {
  if (code == null) return null;
  for (final lang in kTargetLanguages) {
    if (lang.code == code) return lang;
  }
  return null;
}
