import 'package:flutter/material.dart';

class PaisaTheme {
  // Paisa Behance Design Colors
  static const Color primaryGreen = Color(0xFF72FF2F); // Brand Accent Green
  static const Color primaryGreenDark = Color(0xFF5ED625);
  static const Color background = Color(0xFF0D0F12); // Deep Matte Black
  static const Color surface = Color(0xFF181A1F); // Elevated Surface
  static const Color card = Color(0xFF212121); // Primary Card Surface
  static const Color surfaceBorder = Color(0xFF2A2E38); // Subtle Border

  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFFADADAD);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLightGray = Color(0xFFDADADA);

  // Accents for categories and badges
  static const Color danger = Color(0xFFFF4B4B); // Red for expense / alerts
  static const Color cyan = Color(0xFF38D5F8); // Insights cyan
  static const Color purple = Color(0xFFA855F7); // Category purple
  static const Color orange = Color(0xFFF97316); // Category orange
  static const Color yellow = Color(0xFFEAB308); // Category yellow
  static const Color blue = Color(0xFF3B82F6); // Category blue

  // Category Color Map
  static const Map<String, Color> categoryColorMap = {
    'Food': orange,
    'Dining Out': purple,
    'Groceries': primaryGreen,
    'Utilities': cyan,
    'Transportation': yellow,
    'Transport': yellow,
    'Entertainment': danger,
    'Housing': blue,
    'Bills': orange,
    'Shopping': purple,
    'Health': primaryGreen,
    'Education': cyan,
    'Other': textGray,
  };

  static Color getCategoryColor(String category) {
    return categoryColorMap[category] ?? primaryGreen;
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
      case 'Dining Out':
        return Icons.restaurant_rounded;
      case 'Groceries':
        return Icons.local_grocery_store_rounded;
      case 'Utilities':
        return Icons.power_rounded;
      case 'Transportation':
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Entertainment':
        return Icons.movie_filter_rounded;
      case 'Housing':
        return Icons.home_work_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Education':
        return Icons.school_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: surface,
        onSurface: textWhite,
        onPrimary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: surfaceBorder,
      cardColor: card,
    );
  }

  // Light Theme (clean fallback)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF121417),
        surface: Colors.white,
        onSurface: Color(0xFF121417),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F8FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF121417),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
