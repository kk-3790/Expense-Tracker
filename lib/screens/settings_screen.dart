import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    SettingsService.themeMode.addListener(_refresh);
    SettingsService.currency.addListener(_refresh);
    SettingsService.monthlyBudget.addListener(_refresh);
    SettingsService.notificationsEnabled
        .addListener(_refresh);
    SettingsService.budgetAlertsEnabled
        .addListener(_refresh);
  }

  @override
  void dispose() {
    SettingsService.themeMode.removeListener(_refresh);
    SettingsService.currency.removeListener(_refresh);
    SettingsService.monthlyBudget
        .removeListener(_refresh);
    SettingsService.notificationsEnabled
        .removeListener(_refresh);
    SettingsService.budgetAlertsEnabled
        .removeListener(_refresh);

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _showProfile() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final name =
    user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'User';

    final email =
        user.email ?? 'No email available';

    final photoUrl = user.photoURL;

    showModalBottomSheet(
      context: context,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                  const Color(0xFFB7F23D),
                  backgroundImage:
                  photoUrl != null &&
                      photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child:
                  photoUrl == null ||
                      photoUrl.isEmpty
                      ? const Icon(
                    Icons.person_rounded,
                    size: 44,
                    color:
                    Color(0xFF172015),
                  )
                      : null,
                ),

                const SizedBox(height: 14),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Signed in with Google',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // APPEARANCE
  // ============================================================

  void _showAppearance() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        final current =
            SettingsService.themeMode.value;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                _ThemeOption(
                  title: 'System',
                  subtitle:
                  'Follow your device theme',
                  icon: Icons.brightness_auto_rounded,
                  selected:
                  current == ThemeMode.system,
                  onTap: () async {
                    await SettingsService
                        .setThemeMode(
                      ThemeMode.system,
                    );

                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),

                _ThemeOption(
                  title: 'Light',
                  subtitle:
                  'Use light appearance',
                  icon: Icons.light_mode_rounded,
                  selected:
                  current == ThemeMode.light,
                  onTap: () async {
                    await SettingsService
                        .setThemeMode(
                      ThemeMode.light,
                    );

                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),

                _ThemeOption(
                  title: 'Dark',
                  subtitle:
                  'Use dark appearance',
                  icon: Icons.dark_mode_rounded,
                  selected:
                  current == ThemeMode.dark,
                  onTap: () async {
                    await SettingsService
                        .setThemeMode(
                      ThemeMode.dark,
                    );

                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  void _showCurrency() {
    const currencies = [
      {
        'name': 'Indian Rupee',
        'code': '₹',
      },
      {
        'name': 'US Dollar',
        'code': '\$',
      },
      {
        'name': 'Euro',
        'code': '€',
      },
      {
        'name': 'British Pound',
        'code': '£',
      },
      {
        'name': 'Japanese Yen',
        'code': '¥',
      },
      {
        'name': 'Australian Dollar',
        'code': 'A\$',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currency',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                ...currencies.map(
                      (currency) {
                    final code =
                    currency['code']!;

                    final selected =
                        SettingsService
                            .currency
                            .value ==
                            code;

                    return ListTile(
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                      ),
                      tileColor: selected
                          ? const Color(
                        0xFFB7F23D,
                      )
                          : null,
                      leading: CircleAvatar(
                        backgroundColor:
                        selected
                            ? Colors.white
                            : Theme.of(
                          context,
                        )
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Text(
                          code,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        currency['name']!,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                        Icons
                            .check_circle_rounded,
                      )
                          : null,
                      onTap: () async {
                        await SettingsService
                            .setCurrency(code);

                        if (sheetContext.mounted) {
                          Navigator.pop(
                            sheetContext,
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MONTHLY BUDGET
  // ============================================================

  Future<void> _editBudget() async {
    final controller =
    TextEditingController(
      text: SettingsService.monthlyBudget.value
          .toStringAsFixed(0),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            autofocus: true,
            decoration: InputDecoration(
              prefixText:
              '${SettingsService.currency.value} ',
              hintText: 'Enter budget',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                double.tryParse(
                  controller.text.trim(),
                );

                if (value == null || value < 0) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value != null) {
      await SettingsService.setMonthlyBudget(
        value,
      );
    }
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  Future<void> _clearData() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear all transaction data?',
          ),
          content: const Text(
            'This will permanently delete all '
                'locally stored transactions. '
                'Your Google account will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Clear Data',
                style: TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await TransactionService.clearAll();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'All transaction data has been cleared.',
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // ============================================================
  // EXPORT
  // ============================================================

  void _showExport() {
    final count =
        TransactionService.transactions.value.length;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export'),
          content: Text(
            count == 0
                ? 'There are no transactions to export yet.'
                : '$count transaction${count == 1 ? '' : 's'} '
                'are ready to export.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // IMPORT
  // ============================================================

  void _showImport() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import'),
          content: const Text(
            'Import will be connected to a file picker '
                'when external file access is added.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationLegalese:
      'Personal expense management application.',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFB7F23D),
          borderRadius:
          BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: Color(0xFF172015),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final name =
    user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'User';

    final email =
        user?.email ?? 'No email available';

    final photoUrl = user?.photoURL;

    final currency =
        SettingsService.currency.value;

    final budget =
        SettingsService.monthlyBudget.value;

    final notifications =
        SettingsService.notificationsEnabled.value;

    final alerts =
        SettingsService.budgetAlertsEnabled.value;

    final currentMonthExpense =
    TransactionService.monthlyExpense(
      DateTime.now().year,
      DateTime.now().month,
    );

    final budgetProgress =
    budget <= 0
        ? 0.0
        : (currentMonthExpense / budget)
        .clamp(0.0, 1.0);

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            32,
          ),
          children: [
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),

            const SizedBox(height: 24),

            // ========================================================
            // PROFILE
            // ========================================================

            GestureDetector(
              onTap: _showProfile,
              child: Container(
                padding:
                const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2724)
                      : const Color(0xFFEFF3E6),
                  borderRadius:
                  BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                      const Color(0xFFB7F23D),
                      backgroundImage:
                      photoUrl != null &&
                          photoUrl.isNotEmpty
                          ? NetworkImage(
                        photoUrl,
                      )
                          : null,
                      child:
                      photoUrl == null ||
                          photoUrl.isEmpty
                          ? const Icon(
                        Icons.person_rounded,
                        color: Color(
                          0xFF172015,
                        ),
                        size: 30,
                      )
                          : null,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            _SectionTitle(
              title: 'Preferences',
            ),

            const SizedBox(height: 10),

            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _themeName(
                SettingsService.themeMode.value,
              ),
              onTap: _showAppearance,
            ),

            _SettingsTile(
              icon: Icons.currency_exchange_rounded,
              title: 'Currency',
              subtitle: currency,
              onTap: _showCurrency,
            ),

            _SettingsTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Monthly Budget',
              subtitle: budget <= 0
                  ? 'Not set'
                  : '$currency ${budget.toStringAsFixed(0)}',
              onTap: _editBudget,
            ),

            const SizedBox(height: 24),

            _SectionTitle(
              title: 'Notifications',
            ),

            const SizedBox(height: 10),

            _SwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle:
              'Receive expense reminders',
              value: notifications,
              onChanged: (value) async {
                await SettingsService
                    .setNotificationsEnabled(
                  value,
                );
              },
            ),

            _SwitchTile(
              icon: Icons.warning_amber_rounded,
              title: 'Budget Alerts',
              subtitle:
              budget <= 0
                  ? 'Set a budget first'
                  : '${(budgetProgress * 100).toStringAsFixed(0)}% of budget used',
              value: alerts,
              onChanged: budget <= 0
                  ? null
                  : (value) async {
                await SettingsService
                    .setBudgetAlertsEnabled(
                  value,
                );
              },
            ),

            const SizedBox(height: 24),

            _SectionTitle(
              title: 'Data',
            ),

            const SizedBox(height: 10),

            _SettingsTile(
              icon: Icons.upload_file_outlined,
              title: 'Export',
              subtitle:
              'View your transaction export',
              onTap: _showExport,
            ),

            _SettingsTile(
              icon: Icons.download_outlined,
              title: 'Import',
              subtitle:
              'Import transaction data',
              onTap: _showImport,
            ),

            _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Clear Transaction Data',
              subtitle:
              'Delete all local transactions',
              destructive: true,
              onTap: _clearData,
            ),

            const SizedBox(height: 24),

            _SectionTitle(
              title: 'Account',
            ),

            const SizedBox(height: 10),

            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle:
              'Sign out of your Google account',
              destructive: true,
              onTap: _logout,
            ),

            const SizedBox(height: 24),

            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle:
              'Expense Tracker information',
              onTap: _showAbout,
            ),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFB3261E)
        : Theme.of(context)
        .colorScheme
        .onSurface;

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0x1AB3261E)
              : const Color(0xFFB7F23D),
          borderRadius:
          BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
      ),
      onTap: onTap,
    );
  }
}

// ============================================================
// SWITCH TILE
// ============================================================

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFB7F23D),
          borderRadius:
          BorderRadius.circular(14),
        ),
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor:
        const Color(0xFF172015),
        activeTrackColor:
        const Color(0xFFB7F23D),
      ),
    );
  }
}

// ============================================================
// THEME OPTION
// ============================================================

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: selected
          ? const Color(0xFFB7F23D)
          : null,
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(
        Icons.check_circle_rounded,
      )
          : null,
    );
  }
}