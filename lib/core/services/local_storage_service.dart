import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  LocalStorageService._(this._prefs);

  final SharedPreferences _prefs;

  static LocalStorageService? _instance;

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = LocalStorageService._(prefs);
    return _instance!;
  }

  static LocalStorageService get instance {
    assert(_instance != null, 'LocalStorageService.init() must be called first');
    return _instance!;
  }

  // ── User identity ──────────────────────────────────────────────────────────

  String? get userId => _prefs.getString(AppConstants.userIdKey);
  Future<void> setUserId(String id) => _prefs.setString(AppConstants.userIdKey, id);

  // ── Onboarding ─────────────────────────────────────────────────────────────

  int get onboardingStep => _prefs.getInt(AppConstants.onboardingStepKey) ?? 0;
  Future<void> setOnboardingStep(int step) =>
      _prefs.setInt(AppConstants.onboardingStepKey, step);

  bool get onboardingComplete =>
      _prefs.getBool('onboarding_complete') ?? false;
  Future<void> setOnboardingComplete() =>
      _prefs.setBool('onboarding_complete', true);
  Future<void> clearOnboardingComplete() =>
      _prefs.setBool('onboarding_complete', false);

  // ── Theme ──────────────────────────────────────────────────────────────────

  String get selectedTheme =>
      _prefs.getString(AppConstants.themeKey) ?? 'theme_1';
  Future<void> setSelectedTheme(String theme) =>
      _prefs.setString(AppConstants.themeKey, theme);

  // ── App theme mode ─────────────────────────────────────────────────────────

  /// 'system' | 'light' | 'dark'
  String get themeMode => _prefs.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String mode) =>
      _prefs.setString('theme_mode', mode);

  // ── Cached profile (offline resilience) ───────────────────────────────────

  /// Last known profile snapshot (raw `UserModel.toJson()`, JSON-encoded),
  /// kept so the UI can show real data instead of falling back to a guest
  /// state when the realtime `profiles` stream has nothing yet — e.g. a
  /// cold app start with no connectivity, or a dropped connection mid-session.
  String? get cachedProfileJson => _prefs.getString('cached_profile');
  Future<void> setCachedProfileJson(String json) =>
      _prefs.setString('cached_profile', json);

  /// Last-known phrasebook (JSON-encoded list of `Phrase.toJson()`, keyed
  /// per user) — read when the realtime `phrases` stream has nothing yet,
  /// so a dropped connection or offline restart doesn't wipe previous
  /// translations from the UI.
  String? cachedPhrasesJson(String uid) =>
      _prefs.getString('cached_phrases_$uid');
  Future<void> setCachedPhrasesJson(String uid, String json) =>
      _prefs.setString('cached_phrases_$uid', json);

  // ── Generic helpers ────────────────────────────────────────────────────────

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}
