import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/auth_service.dart';
import 'services/goal_service.dart';
import 'services/settings_service.dart';
import 'services/split_service.dart';
import 'services/transaction_service.dart';
import 'theme/paisa_theme.dart';

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

  String? currentUid;
  try {
    currentUid = FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {}
  final initialUid = currentUid ?? 'guest';

  try {
    await SettingsService.init(userId: initialUid);
  } catch (e) {
    debugPrint('SettingsService.init error: $e');
  }

  try {
    await GoalService.init(userId: initialUid);
  } catch (e) {
    debugPrint('GoalService.init error: $e');
  }

  try {
    await TransactionService.init(userId: initialUid);
  } catch (e) {
    debugPrint('TransactionService.init error: $e');
  }

  try {
    await SplitService.init(userId: initialUid);
  } catch (e) {
    debugPrint('SplitService.init error: $e');
  }

  try {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? 'guest';
      AuthService.switchUserSession(uid);
    });
  } catch (e) {
    debugPrint('Auth listener error: $e');
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
          title: 'Paisa - Track Money',
          themeMode: themeMode,
          theme: PaisaTheme.lightTheme,
          darkTheme: PaisaTheme.darkTheme,
          home: initError != null
              ? Scaffold(
                  backgroundColor: PaisaTheme.background,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Startup Notice',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            initError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: PaisaTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              runApp(const MaterialApp(
                                debugShowCheckedModeBanner: false,
                                home: MainNavigation(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
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
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    StatisticsScreen(),
    AiChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaTheme.background,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: PaisaTheme.background,
          border: Border(
            top: BorderSide(
              color: PaisaTheme.surfaceBorder,
              width: 0.8,
            ),
          ),
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
                  label: 'Tracking',
                  isSelected: currentIndex == 1,
                  onTap: () => setState(() => currentIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Bot',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? PaisaTheme.primaryGreen : PaisaTheme.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : PaisaTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}