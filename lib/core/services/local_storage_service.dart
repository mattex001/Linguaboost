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

  // ── Generic helpers ────────────────────────────────────────────────────────

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}
