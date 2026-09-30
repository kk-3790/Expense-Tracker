import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static late SharedPreferences _prefs;

  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier<ThemeMode>(ThemeMode.system);

  static final ValueNotifier<String> currency =
  ValueNotifier<String>('₹');

  static final ValueNotifier<double> monthlyBudget =
  ValueNotifier<double>(0);

  static final ValueNotifier<bool> notificationsEnabled =
  ValueNotifier<bool>(true);

  static final ValueNotifier<bool> budgetAlertsEnabled =
  ValueNotifier<bool>(false);

  static final ValueNotifier<bool> goalAlertsEnabled =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> categoryBudgetAlertsEnabled =
      ValueNotifier<bool>(true);

  static const String _defaultGeminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static final ValueNotifier<String> geminiApiKey =
      ValueNotifier<String>(_defaultGeminiApiKey);

  static String? _currentUserId;

  static String _key(String base) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return base;
    }
    return '${base}_$_currentUserId';
  }

  static String? _getStringScoped(String baseKey, {String? defaultValue}) {
    final scopedKey = _key(baseKey);
    if (_prefs.containsKey(scopedKey)) {
      return _prefs.getString(scopedKey);
    }
    final migratedTo = _prefs.getString('settings_migrated_to');
    if (_prefs.containsKey(baseKey) && (migratedTo == null || migratedTo == _currentUserId)) {
      final val = _prefs.getString(baseKey);
      if (val != null) {
        _prefs.setString(scopedKey, val);
        _prefs.setString('settings_migrated_to', _currentUserId ?? 'migrated');
        return val;
      }
    }
    return defaultValue;
  }

  static double _getDoubleScoped(String baseKey, {double defaultValue = 0.0}) {
    final scopedKey = _key(baseKey);
    if (_prefs.containsKey(scopedKey)) {
      return _prefs.getDouble(scopedKey) ?? defaultValue;
    }
    final migratedTo = _prefs.getString('settings_migrated_to');
    if (_prefs.containsKey(baseKey) && (migratedTo == null || migratedTo == _currentUserId)) {
      final val = _prefs.getDouble(baseKey);
      if (val != null) {
        _prefs.setDouble(scopedKey, val);
        _prefs.setString('settings_migrated_to', _currentUserId ?? 'migrated');
        return val;
      }
    }
    return defaultValue;
  }

  static bool _getBoolScoped(String baseKey, {bool defaultValue = false}) {
    final scopedKey = _key(baseKey);
    if (_prefs.containsKey(scopedKey)) {
      return _prefs.getBool(scopedKey) ?? defaultValue;
    }
    final migratedTo = _prefs.getString('settings_migrated_to');
    if (_prefs.containsKey(baseKey) && (migratedTo == null || migratedTo == _currentUserId)) {
      final val = _prefs.getBool(baseKey);
      if (val != null) {
        _prefs.setBool(scopedKey, val);
        _prefs.setString('settings_migrated_to', _currentUserId ?? 'migrated');
        return val;
      }
    }
    return defaultValue;
  }

  static Future<void> init({String? userId}) async {
    _prefs = await SharedPreferences.getInstance();
    await switchUser(userId ?? _currentUserId);
  }

  /// Switch the active user session and load their settings
  static Future<void> switchUser(String? userId) async {
    _currentUserId = userId;

    geminiApiKey.value =
        _getStringScoped('gemini_api_key', defaultValue: _defaultGeminiApiKey) ??
        _defaultGeminiApiKey;

    final savedTheme = _getStringScoped('theme_mode');

    switch (savedTheme) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;

      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;

      default:
        themeMode.value = ThemeMode.system;
    }

    currency.value = _getStringScoped('currency', defaultValue: '₹') ?? '₹';

    monthlyBudget.value = _getDoubleScoped('monthly_budget', defaultValue: 0);

    notificationsEnabled.value =
        _getBoolScoped('notifications_enabled', defaultValue: true);

    budgetAlertsEnabled.value =
        _getBoolScoped('budget_alerts_enabled', defaultValue: false);

    goalAlertsEnabled.value =
        _getBoolScoped('goal_alerts_enabled', defaultValue: true);

    categoryBudgetAlertsEnabled.value =
        _getBoolScoped('category_budget_alerts_enabled', defaultValue: true);
  }

  // ============================================================
  // THEME
  // ============================================================

  static Future<void> setThemeMode(
      ThemeMode mode,
      ) async {
    themeMode.value = mode;

    String value;

    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;

      case ThemeMode.dark:
        value = 'dark';
        break;

      case ThemeMode.system:
        value = 'system';
        break;
    }

    await _prefs.setString(
      _key('theme_mode'),
      value,
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  static Future<void> setCurrency(
      String value,
      ) async {
    currency.value = value;

    await _prefs.setString(
      _key('currency'),
      value,
    );
  }

  // ============================================================
  // MONTHLY BUDGET
  // ============================================================

  static Future<void> setMonthlyBudget(
      double value,
      ) async {
    monthlyBudget.value = value;

    await _prefs.setDouble(
      _key('monthly_budget'),
      value,
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  static Future<void> setNotificationsEnabled(
      bool value,
      ) async {
    notificationsEnabled.value = value;

    await _prefs.setBool(
      _key('notifications_enabled'),
      value,
    );
  }

  // ============================================================
  // BUDGET ALERTS
  // ============================================================

  static Future<void> setBudgetAlertsEnabled(
      bool value,
      ) async {
    budgetAlertsEnabled.value = value;

    await _prefs.setBool(
      _key('budget_alerts_enabled'),
      value,
    );
  }

  static Future<void> setGoalAlertsEnabled(bool value) async {
    goalAlertsEnabled.value = value;
    await _prefs.setBool(_key('goal_alerts_enabled'), value);
  }

  static Future<void> setCategoryBudgetAlertsEnabled(bool value) async {
    categoryBudgetAlertsEnabled.value = value;
    await _prefs.setBool(_key('category_budget_alerts_enabled'), value);
  }

  // ============================================================
  // GEMINI API KEY
  // ============================================================

  static Future<void> setGeminiApiKey(String key) async {
    geminiApiKey.value = key.trim();
    await _prefs.setString(_key('gemini_api_key'), key.trim());
  }

  // ============================================================
  // RESET SETTINGS
  // ============================================================

  static Future<void> reset() async {
    await _prefs.remove(_key('theme_mode'));
    await _prefs.remove(_key('currency'));
    await _prefs.remove(_key('monthly_budget'));
    await _prefs.remove(_key('notifications_enabled'));
    await _prefs.remove(_key('budget_alerts_enabled'));
    await _prefs.remove(_key('goal_alerts_enabled'));
    await _prefs.remove(_key('category_budget_alerts_enabled'));
    await _prefs.remove(_key('gemini_api_key'));

    themeMode.value = ThemeMode.system;
    currency.value = '₹';
    monthlyBudget.value = 0;
    notificationsEnabled.value = true;
    budgetAlertsEnabled.value = false;
    goalAlertsEnabled.value = true;
    categoryBudgetAlertsEnabled.value = true;
    geminiApiKey.value = _defaultGeminiApiKey;
  }
}