import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatAmount(double amount) {
    final currency = SettingsService.currency.value;
    return '$currency${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (itemDate == yesterday) {
      return 'Yesterday';
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Education':
        return Icons.school_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFF9500); // Vibrant orange
      case 'Transport':
        return const Color(0xFF007AFF); // Electric blue
      case 'Shopping':
        return const Color(0xFFAF52DE); // Royal purple
      case 'Bills':
        return const Color(0xFFFF3B30); // Coral red
      case 'Entertainment':
        return const Color(0xFFFF2D55); // Pink
      case 'Health':
        return const Color(0xFF34C759); // Mint green
      case 'Education':
        return const Color(0xFF30B0C7); // Teal
      default:
        return const Color(0xFF8E8E93); // Slate
    }
  }

  Future<void> _openAddTransaction(BuildContext context, {bool isExpense = true}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }

  void _showProfile(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : 'User';
    final email = user.email ?? 'No email available';
    final photoUrl = user.photoURL;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF171A21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF121418),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121418),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Krish Patel';
    final photoUrl = user?.photoURL;

    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFEBEFF5);

    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, transactions, child) {
        final balance = TransactionService.balance;
        final currency = SettingsService.currency.value;
        final budget = SettingsService.monthlyBudget.value;
        final now = DateTime.now();
        final monthlyExpense = TransactionService.monthlyExpense(now.year, now.month);

        final budgetProgress = budget <= 0
            ? 0.0
            : (monthlyExpense / budget).clamp(0.0, 1.0);

        // Group recent transactions by date
        final recentTransactions = transactions.take(10).toList();
        final grouped = <String, List<TransactionModel>>{};
        for (final tx in recentTransactions) {
          final header = _formatDateHeader(tx.date);
          grouped.putIfAbsent(header, () => []).add(tx);
        }

        return Scaffold(
          body: SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                // ======================================================
                // TOP HEADER: Profile Avatar + Name + Action Icons
                // ======================================================
                Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: () => _showProfile(context),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF121418),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? const Icon(Icons.person_rounded, size: 22, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Expanded(
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF121417),
                        ),
                      ),
                    ),
                    // Scan QR button
                    _HeaderCircleButton(
                      icon: Icons.qr_code_scanner_rounded,
                      isDark: isDark,
                      onTap: () => _openScanner(context),
                    ),
                    const SizedBox(width: 10),
                    // Settings/Profile button
                    _HeaderCircleButton(
                      icon: Icons.tune_rounded,
                      isDark: isDark,
                      onTap: () => _showProfile(context),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ======================================================
                // AVAILABLE BALANCE CARD (Dribbble Conceptzilla Style)
                // ======================================================
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 8),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Giant Balance
                      Text(
                        '$currency${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: isDark ? Colors.white : const Color(0xFF121417),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transfer Limit / Monthly Budget Row
                      Row(
                        children: [
                          Text(
                            budget > 0 ? 'Monthly Budget' : 'Budget Limit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF555B63),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            budget > 0
                                ? '$currency${budget.toStringAsFixed(0)}'
                                : 'Not set',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF121417),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Thin Progress Track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? Colors.white12
                              : const Color(0xFFEFEFEF),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetProgress >= 1.0
                                ? const Color(0xFFFF3B30)
                                : budgetProgress >= 0.8
                                ? const Color(0xFFFF9500)
                                : const Color(0xFF007AFF),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Subtext: Spent $X.XX
                      Row(
                        children: [
                          Text(
                            'Spent: ${_formatAmount(monthlyExpense)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (budget > 0)
                            Text(
                              '${(budgetProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF555B63),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Two Pill Action Buttons: [ Pay ↑ ] and [ Deposit ↓ / Scan QR ]
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openAddTransaction(context, isExpense: true),
                              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                              label: const Text(
                                'Pay',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF121417),
                                foregroundColor: isDark
                                    ? const Color(0xFF121417)
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openScanner(context),
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                              label: const Text(
                                'Scan QR',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF222831)
                                    : const Color(0xFF121417),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ======================================================
                // OPERATIONS / TRANSACTIONS CARD (Dribbble Conceptzilla)
                // ======================================================
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 8),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Operations + View All
                      Row(
                        children: [
                          Text(
                            'Operations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : const Color(0xFF121417),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              // Direct user to Add or View transactions
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Add New',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      if (recentTransactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: isDark ? Colors.white38 : Colors.black26,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No operations yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Scan a QR or tap Pay to record your first expense',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header (e.g. Today, Yesterday)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 12),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                                  ),
                                ),
                              ),

                              // Items in this date group
                              ...entry.value.map((tx) {
                                final color = _categoryColor(tx.category);
                                final isIncome = tx.isIncome;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTransactionScreen(
                                            transaction: tx,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Row(
                                      children: [
                                        // Circular Brand/Category Icon
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(isDark ? 45 : 30),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _categoryIcon(tx.category),
                                            size: 20,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Title & Note/Subtitle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.title.isNotEmpty ? tx.title : tx.category,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF121417),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                tx.note.isNotEmpty ? tx.note : tx.category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Amount: -$34.99 or +$100.00
                                        Text(
                                          isIncome
                                              ? '+ ${_formatAmount(tx.amount)}'
                                              : '- ${_formatAmount(tx.amount)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isIncome
                                                ? const Color(0xFF34C759)
                                                : (isDark ? Colors.white : const Color(0xFF121417)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================================
// TOP HEADER CIRCLE BUTTON
// ======================================================================

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F242D) : const Color(0xFFEFF2F6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white70 : const Color(0xFF3A3F47),
        ),
      ),
    );
  }
}