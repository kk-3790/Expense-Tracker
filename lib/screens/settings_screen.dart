import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'ai_chat_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  void _showCurrencyPicker() {
    const currencies = [
      {'code': '₹ Rupee', 'symbol': '₹'},
      {'code': '\$ Dollar', 'symbol': '\$'},
      {'code': '€ Euro', 'symbol': '€'},
      {'code': '£ Pound', 'symbol': '£'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PaisaTheme.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ...currencies.map((c) {
                  final isSelected = SettingsService.currency.value == c['symbol'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      c['code']!,
                      style: TextStyle(
                        color: isSelected ? PaisaTheme.primaryGreen : Colors.white,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: PaisaTheme.primaryGreen)
                        : null,
                    onTap: () async {
                      await SettingsService.setCurrency(c['symbol']!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(() {});
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountDetails() {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Guest User';
    final email = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : 'guest@paisa.app';
    final photo = user?.photoURL;

    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: PaisaTheme.surface,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? const Icon(Icons.person_rounded, size: 36, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: PaisaTheme.textGray,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaisaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content,
            style: const TextStyle(color: PaisaTheme.textLightGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: PaisaTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showClearTransactionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaisaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4B4B), size: 24),
            SizedBox(width: 8),
            Text(
              'Clear Transactions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all recorded income and expense transactions? Your balance will be reset to ₹0. This action cannot be undone.',
          style: TextStyle(color: PaisaTheme.textLightGray, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              await TransactionService.clearAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All transactions cleared successfully'),
                    backgroundColor: Color(0xFFFF4B4B),
                  ),
                );
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PaisaTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Notifications & Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enable automated alerts when goals and budget limits are near or reached:',
                      style: TextStyle(fontSize: 12, color: PaisaTheme.textGray),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Goal Near Reach Alert',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Notify when savings goal reaches 75% or 100% target',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.goalAlertsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setGoalAlertsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const Divider(color: PaisaTheme.surfaceBorder, height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Category Budget Limit Alert',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Notify when category spending is near limit (80%) or full (100%)',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.categoryBudgetAlertsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setCategoryBudgetAlertsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const Divider(color: PaisaTheme.surfaceBorder, height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Allow notifications and split bill updates',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.notificationsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setNotificationsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaisaTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Open Notification Center', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaTheme.background,
      appBar: AppBar(
        backgroundColor: PaisaTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          _SettingsRow(
            icon: Icons.person_outline_rounded,
            title: 'Account',
            onTap: _showAccountDetails,
          ),
          _SettingsRow(
            icon: Icons.smart_toy_outlined,
            title: 'AI Bot',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
          ),
          _SettingsRow(
            icon: Icons.attach_money_rounded,
            title: 'Currency',
            valueText: SettingsService.currency.value == '₹'
                ? '₹ Rupee'
                : '${SettingsService.currency.value} Default',
            hasDropdown: true,
            onTap: _showCurrencyPicker,
          ),
          _SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notification',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _SettingsRow(
            icon: Icons.notifications_active_outlined,
            title: 'Smart Alerts & Preferences',
            onTap: _showNotificationSettingsModal,
          ),
          _SettingsRow(
            icon: Icons.cloud_download_outlined,
            title: 'Data Export',
            onTap: () => _showInfoDialog(
              'Data Export',
              'Your financial transaction history is saved securely on your device. Export to CSV is ready anytime.',
            ),
          ),
          _SettingsRow(
            icon: Icons.language_rounded,
            title: 'Language',
            valueText: 'English',
            onTap: () => _showInfoDialog('Language', 'Default language is English (US).'),
          ),
          _SettingsRow(
            icon: Icons.shield_outlined,
            title: 'Privacy',
            onTap: () => _showInfoDialog(
              'Privacy',
              'Paisa respects your financial privacy. All offline transactions are encrypted locally.',
            ),
          ),
          _SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            onTap: () => _showInfoDialog(
              'Security',
              'Biometric Face ID / Fingerprint lock enabled for maximum security.',
            ),
          ),
          _SettingsRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Feedback and Suggestions',
            onTap: () => _showInfoDialog(
              'Feedback',
              'Thank you for using Paisa! Send your suggestions to support@paisa.app',
            ),
          ),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help and Support',
            onTap: () => _showInfoDialog(
              'Help & Support',
              'Need assistance? Contact our 24/7 financial concierge.',
            ),
          ),
          _SettingsRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Seed Demo Data',
            valueText: 'Generate',
            onTap: () async {
              await TransactionService.seedDemoData(force: true);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demo transactions populated successfully! 🚀'),
                  backgroundColor: PaisaTheme.primaryGreen,
                ),
              );
            },
          ),
          _SettingsRow(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear All Transactions',
            valueText: 'Reset ₹0',
            onTap: _showClearTransactionsDialog,
          ),

          const SizedBox(height: 24),

          // Sign Out Button
          Container(
            decoration: BoxDecoration(
              color: PaisaTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PaisaTheme.surfaceBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF4B4B)),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFFF4B4B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onTap: () async {
                await _authService.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? valueText;
  final bool hasDropdown;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.valueText,
    this.hasDropdown = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: PaisaTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PaisaTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (valueText != null) ...[
                Text(
                  valueText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: PaisaTheme.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                hasDropdown
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: PaisaTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}