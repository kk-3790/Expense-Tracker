import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier<ThemeMode>(ThemeMode.light);

  static void setTheme(ThemeMode mode) {
    themeMode.value = mode;
  }
}