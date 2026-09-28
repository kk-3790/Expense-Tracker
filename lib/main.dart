import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/settings_screen.dart';

import 'services/settings_service.dart';
import 'services/transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stack) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('Firebase.initializeApp error: $e\n$stack');
      initError = 'Firebase initialization error:\n$e';
    }
  }

  try {
    await SettingsService.init();
  } catch (e) {
    debugPrint('SettingsService.init error: $e');
  }

  try {
    await TransactionService.init();
  } catch (e) {
    debugPrint('TransactionService.init error: $e');
  }

  runApp(ExpenseTrackerApp(initError: initError));
}

class ExpenseTrackerApp extends StatelessWidget {
  final String? initError;
  const ExpenseTrackerApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',
          themeMode: themeMode,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F8FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F1115),
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F8FA),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF121417),
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121417),
                letterSpacing: -0.3,
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121417),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121417),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Color(0xFF121417),
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A9099),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF121417),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0D0F13),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.white,
              brightness: Brightness.dark,
              surface: const Color(0xFF171A21),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D0F13),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A9099),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF121417),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          home: initError != null
              ? Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Startup Notice',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            initError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              runApp(const MaterialApp(
                                debugShowCheckedModeBanner: false,
                                home: MainNavigation(),
                              ));
                            },
                            child: const Text('Continue in Offline Mode'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : StreamBuilder<User?>(
                  initialData: FirebaseAuth.instance.currentUser,
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      return const MainNavigation();
                    }

                    return const LoginScreen();
                  },
                ),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    StatisticsScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121418),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => setState(() => currentIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.donut_large_rounded,
                  label: 'Insights',
                  isSelected: currentIndex == 1,
                  onTap: () => setState(() => currentIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Wallet',
                  isSelected: currentIndex == 2,
                  onTap: () => setState(() => currentIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  isSelected: currentIndex == 3,
                  onTap: () => setState(() => currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}