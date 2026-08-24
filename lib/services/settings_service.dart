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

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // ============================================================
    // THEME
    // ============================================================

    final savedTheme =
    _prefs.getString('theme_mode');

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

    // ============================================================
    // CURRENCY
    // ============================================================

    currency.value =
        _prefs.getString('currency') ?? '₹';

    // ============================================================
    // MONTHLY BUDGET
    // ============================================================

    monthlyBudget.value =
        _prefs.getDouble('monthly_budget') ?? 0;

    // ============================================================
    // NOTIFICATIONS
    // ============================================================

    notificationsEnabled.value =
        _prefs.getBool('notifications_enabled') ?? true;

    // ============================================================
    // BUDGET ALERTS
    // ============================================================

    budgetAlertsEnabled.value =
        _prefs.getBool('budget_alerts_enabled') ?? false;
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
      'theme_mode',
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
      'currency',
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
      'monthly_budget',
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
      'notifications_enabled',
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
      'budget_alerts_enabled',
      value,
    );
  }

  // ============================================================
  // RESET SETTINGS
  // ============================================================

  static Future<void> reset() async {
    await _prefs.remove('theme_mode');
    await _prefs.remove('currency');
    await _prefs.remove('monthly_budget');
    await _prefs.remove('notifications_enabled');
    await _prefs.remove('budget_alerts_enabled');

    themeMode.value = ThemeMode.system;
    currency.value = '₹';
    monthlyBudget.value = 0;
    notificationsEnabled.value = true;
    budgetAlertsEnabled.value = false;
  }
}