import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    SettingsService.themeMode.addListener(_refresh);
    SettingsService.currency.addListener(_refresh);
    SettingsService.monthlyBudget.addListener(_refresh);
  }

  @override
  void dispose() {
    SettingsService.themeMode.removeListener(_refresh);
    SettingsService.currency.removeListener(_refresh);
    SettingsService.monthlyBudget.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _changeCurrency() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const currencies = [
      {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
      {'symbol': '\$', 'name': 'US Dollar (USD)'},
      {'symbol': '€', 'name': 'Euro (EUR)'},
      {'symbol': '£', 'name': 'British Pound (GBP)'},
      {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
      {'symbol': 'C\$', 'name': 'Canadian Dollar (CAD)'},
      {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF171A21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Currency',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  ...currencies.map((curr) {
                    final isSelected = SettingsService.currency.value == curr['symbol'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF121418)
                              : (isDark ? Colors.white12 : const Color(0xFFEFF2F6)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            curr['symbol']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF121417)),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        curr['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759))
                          : null,
                      onTap: () async {
                        await SettingsService.setCurrency(curr['symbol']!);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editBudget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBudget = SettingsService.monthlyBudget.value;
    final textController = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF171A21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Set Monthly Budget Limit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your monthly spending with automated progress warnings.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '${SettingsService.currency.value} ',
                      prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      hintText: 'e.g. 15000',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1F242E) : const Color(0xFFEFF2F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final val = double.tryParse(textController.text.trim()) ?? 0.0;
                            await SettingsService.setMonthlyBudget(val);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF121417),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Save Budget',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearData() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF171A21) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Transactions?'),
        content: const Text(
          'This will permanently delete all recorded income and expenses. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await TransactionService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All transactions cleared.')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF171A21) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF121417),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFEBEFF5);
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'User';
    final userEmail = user?.email ?? 'Google Account';
    final photoUrl = user?.photoURL;
    final currentTheme = SettingsService.themeMode.value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Title
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF121417),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 6),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF121418),
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded, size: 28, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF121417),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 18,
                      color: Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                ),
              ),
            ),

            Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  // Currency Setting
                  ListTile(
                    onTap: _changeCurrency,
                    leading: _iconBox(Icons.currency_exchange_rounded, const Color(0xFFFF9500), isDark),
                    title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          SettingsService.currency.value,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Colors.white10 : const Color(0xFFF0F3F7), height: 1),

                  // Monthly Budget Setting
                  ListTile(
                    onTap: _editBudget,
                    leading: _iconBox(Icons.pie_chart_outline_rounded, const Color(0xFF007AFF), isDark),
                    title: const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          SettingsService.monthlyBudget.value > 0
                              ? '${SettingsService.currency.value}${SettingsService.monthlyBudget.value.toStringAsFixed(0)}'
                              : 'Not set',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Colors.white10 : const Color(0xFFF0F3F7), height: 1),

                  // Theme Setting
                  ListTile(
                    leading: _iconBox(Icons.dark_mode_outlined, const Color(0xFFAF52DE), isDark),
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: DropdownButton<ThemeMode>(
                      value: currentTheme,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) SettingsService.setThemeMode(mode);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data & Actions Section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Data & Storage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                ),
              ),
            ),

            Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: _clearData,
                    leading: _iconBox(Icons.delete_outline_rounded, const Color(0xFFFF3B30), isDark),
                    title: const Text(
                      'Clear All Transactions',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFFF3B30)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF222831) : const Color(0xFFEFF2F6),
                  foregroundColor: const Color(0xFFFF3B30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}