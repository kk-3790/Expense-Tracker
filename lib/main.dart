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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SettingsService.init();

  await TransactionService.init();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

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
            scaffoldBackgroundColor:
            const Color(0xFFF5F7EE),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB7F23D),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F7EE),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172015),
              ),
              headlineMedium: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172015),
              ),
              titleLarge: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172015),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF172015),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Color(0xFF172015),
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFF66705F),
              ),
            ),
            elevatedButtonTheme:
            ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFB7F23D),
                foregroundColor:
                const Color(0xFF172015),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
            ),
            navigationBarTheme:
            const NavigationBarThemeData(
              backgroundColor:
              Color(0xFFF5F7EE),
              indicatorColor:
              Color(0xFFB7F23D),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor:
            const Color(0xFF101716),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB7F23D),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor:
              Color(0xFF101716),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              headlineMedium: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              titleLarge: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Color(0xFFB7C0B5),
              ),
            ),
            elevatedButtonTheme:
            ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFB7F23D),
                foregroundColor:
                const Color(0xFF172015),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
            ),
            navigationBarTheme:
            const NavigationBarThemeData(
              backgroundColor:
              Color(0xFF101716),
              indicatorColor:
              Color(0xFFB7F23D),
            ),
          ),

          home: StreamBuilder<User?>(
            stream:
            FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasData) {
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
    TransactionsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon:
            Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon:
            Icon(Icons.receipt_long_outlined),
            selectedIcon:
            Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon:
            Icon(Icons.bar_chart_outlined),
            selectedIcon:
            Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon:
            Icon(Icons.settings_outlined),
            selectedIcon:
            Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}