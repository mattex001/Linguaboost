/// Target-language catalog. Single source of truth for the language picker,
/// TTS locale mapping, and labels. Mirrored server-side in
/// supabase/functions/_shared/taxonomy.ts (SUPPORTED_LANGS) — keep in sync.
class TargetLanguage {
  final String code; // ISO 639-1, e.g. 'es'
  final String label; // English name
  final String nativeLabel; // name in the language itself
  final String ttsLocale; // flutter_tts locale, e.g. 'es-ES'
  final String flag; // emoji flag
  final String previewPhrase; // short greeting, used to preview TTS voices

  const TargetLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.ttsLocale,
    required this.flag,
    required this.previewPhrase,
  });
}

const List<TargetLanguage> kTargetLanguages = [
  TargetLanguage(
    code: 'es',
    label: 'Spanish',
    nativeLabel: 'Español',
    ttsLocale: 'es-ES',
    flag: '🇪🇸',
    previewPhrase: 'Hola, ¿cómo estás?',
  ),
  TargetLanguage(
    code: 'fr',
    label: 'French',
    nativeLabel: 'Français',
    ttsLocale: 'fr-FR',
    flag: '🇫🇷',
    previewPhrase: 'Bonjour, comment ça va ?',
  ),
  TargetLanguage(
    code: 'pt',
    label: 'Portuguese',
    nativeLabel: 'Português',
    ttsLocale: 'pt-BR',
    flag: '🇧🇷',
    previewPhrase: 'Olá, como você está?',
  ),
  TargetLanguage(
    code: 'de',
    label: 'German',
    nativeLabel: 'Deutsch',
    ttsLocale: 'de-DE',
    flag: '🇩🇪',
    previewPhrase: 'Hallo, wie geht es dir?',
  ),
  TargetLanguage(
    code: 'it',
    label: 'Italian',
    nativeLabel: 'Italiano',
    ttsLocale: 'it-IT',
    flag: '🇮🇹',
    previewPhrase: 'Ciao, come stai?',
  ),
  TargetLanguage(
    code: 'sw',
    label: 'Swahili',
    nativeLabel: 'Kiswahili',
    ttsLocale: 'sw-KE',
    flag: '🇰🇪',
    previewPhrase: 'Habari, hujambo?',
  ),
  TargetLanguage(
    code: 'yo',
    label: 'Yoruba',
    nativeLabel: 'Yorùbá',
    ttsLocale: 'yo-NG',
    flag: '🇳🇬',
    previewPhrase: 'Bawo, se alafia ni?',
  ),
  TargetLanguage(
    code: 'ig',
    label: 'Igbo',
    nativeLabel: 'Igbo',
    ttsLocale: 'ig-NG',
    flag: '🇳🇬',
    previewPhrase: 'Kedu, kedu ka ị mere?',
  ),
  TargetLanguage(
    code: 'el',
    label: 'Greek',
    nativeLabel: 'Ελληνικά',
    ttsLocale: 'el-GR',
    flag: '🇬🇷',
    previewPhrase: 'Γεια σου, τι κάνεις;',
  ),
  TargetLanguage(
    code: 'ar',
    label: 'Arabic',
    nativeLabel: 'العربية',
    ttsLocale: 'ar-SA',
    flag: '🇸🇦',
    previewPhrase: 'مرحبا، كيف حالك؟',
  ),
  TargetLanguage(
    code: 'zh',
    label: 'Chinese (Mandarin)',
    nativeLabel: '中文',
    ttsLocale: 'zh-CN',
    flag: '🇨🇳',
    previewPhrase: '你好，你怎么样？',
  ),
  TargetLanguage(
    code: 'hi',
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
    ttsLocale: 'hi-IN',
    flag: '🇮🇳',
    previewPhrase: 'नमस्ते, आप कैसे हैं?',
  ),
  TargetLanguage(
    code: 'ja',
    label: 'Japanese',
    nativeLabel: '日本語',
    ttsLocale: 'ja-JP',
    flag: '🇯🇵',
    previewPhrase: 'こんにちは、元気ですか？',
  ),
  TargetLanguage(
    code: 'ko',
    label: 'Korean',
    nativeLabel: '한국어',
    ttsLocale: 'ko-KR',
    flag: '🇰🇷',
    previewPhrase: '안녕하세요, 어떻게 지내세요?',
  ),
  // English is last (not first) so `kTargetLanguages.first` still defaults
  // to a sensible *target* language everywhere that fallback is used; this
  // entry exists so English is selectable as a *source* language too, now
  // that translation is bidirectional.
  TargetLanguage(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
    ttsLocale: 'en-US',
    flag: '🇺🇸',
    previewPhrase: 'Hello, how are you?',
  ),
];

TargetLanguage? targetLanguageForCode(String? code) {
  if (code == null) return null;
  for (final lang in kTargetLanguages) {
    if (lang.code == code) return lang;
  }
  return null;
}
