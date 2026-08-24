import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatAmount(double amount) {
    final currency = SettingsService.currency.value;

    return '$currency${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final transactionDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (transactionDate == today) {
      return 'Today';
    }

    final yesterday =
    today.subtract(const Duration(days: 1));

    if (transactionDate == yesterday) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
        return Icons.more_horiz_rounded;
    }
  }

  Future<void> _addTransaction(
      BuildContext context,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AddTransactionScreen(),
      ),
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _showProfile(
      BuildContext context,
      ) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

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
                // PROFILE PHOTO
                CircleAvatar(
                  radius: 45,
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
                    size: 45,
                    color:
                    Color(0xFF172015),
                  )
                      : null,
                ),

                const SizedBox(height: 14),

                // NAME
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                // EMAIL
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

                // GOOGLE ACCOUNT
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(15),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<
        List<TransactionModel>>(
      valueListenable:
      TransactionService.transactions,
      builder: (
          context,
          transactions,
          child,
          ) {
        final income =
            TransactionService.totalIncome;

        final expense =
            TransactionService.totalExpense;

        final balance =
            TransactionService.balance;

        final currency =
            SettingsService.currency.value;

        final budget =
            SettingsService.monthlyBudget.value;

        final now = DateTime.now();

        final monthlyExpense =
        TransactionService.monthlyExpense(
          now.year,
          now.month,
        );

        final budgetProgress = budget <= 0
            ? 0.0
            : (monthlyExpense / budget)
            .clamp(0.0, 1.0);

        final recentTransactions =
        transactions.take(5).toList();

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(
                  const Duration(
                    milliseconds: 200,
                  ),
                );
              },
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  32,
                ),
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day 👋',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expense Tracker',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium,
                            ),
                          ],
                        ),
                      ),

                      // REAL PROFILE BUTTON
                      _ProfileButton(
                        onTap: () {
                          _showProfile(context);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // BALANCE
                  // ==================================================

                  Container(
                    padding:
                    const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFB7F23D),
                      borderRadius:
                      BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color:
                            Color(0xFF172015),
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '$currency${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color:
                            Color(0xFF172015),
                            fontSize: 34,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child:
                              _BalanceItem(
                                icon: Icons
                                    .arrow_downward_rounded,
                                title: 'Income',
                                value:
                                _formatAmount(
                                  income,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child:
                              _BalanceItem(
                                icon: Icons
                                    .arrow_upward_rounded,
                                title: 'Expense',
                                value:
                                _formatAmount(
                                  expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ADD
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _addTransaction(
                            context,
                          ),
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Text(
                        'Add Transaction',
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BUDGET
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Monthly Budget',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                      ),
                      if (budget > 0)
                        Text(
                          '${_formatAmount(monthlyExpense)} / ${_formatAmount(budget)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        )
                      else
                        Text(
                          'Not set',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding:
                    const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFB7F23D,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  14,
                                ),
                              ),
                              child: const Icon(
                                Icons
                                    .account_balance_wallet_rounded,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    budget > 0
                                        ? '${(budgetProgress * 100).toStringAsFixed(0)}% used'
                                        : 'No budget set',
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    budget > 0
                                        ? monthlyExpense >
                                        budget
                                        ? 'Budget exceeded'
                                        : 'Within budget'
                                        : 'Set a budget in Settings',
                                    style:
                                    Theme.of(
                                      context,
                                    )
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (budget > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                            child:
                            LinearProgressIndicator(
                              value:
                              budgetProgress,
                              minHeight: 9,
                              backgroundColor:
                              Theme.of(context)
                                  .colorScheme
                                  .surface,
                              valueColor:
                              const AlwaysStoppedAnimation<
                                  Color>(
                                Color(0xFFB7F23D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // RECENT
                  // ==================================================

                  Text(
                    'Recent Transactions',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 12),

                  if (recentTransactions.isEmpty)
                    _EmptyRecentTransactions(
                      onAdd: () =>
                          _addTransaction(
                            context,
                          ),
                    )
                  else
                    ...recentTransactions.map(
                          (transaction) =>
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child:
                            _RecentTransactionTile(
                              transaction:
                              transaction,
                              dateText:
                              _formatDate(
                                transaction.date,
                              ),
                              icon:
                              _categoryIcon(
                                transaction.category,
                              ),
                            ),
                          ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ======================================================================
// PROFILE BUTTON
// ======================================================================

class _ProfileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final photoUrl = user?.photoURL;

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
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
          color:
          Color(0xFF172015),
        )
            : null,
      ),
    );
  }
}

// ======================================================================
// BALANCE ITEM
// ======================================================================

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _BalanceItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x55FFFFFF),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
              const Color(0xFF172015),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF394334),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF172015),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// RECENT TRANSACTION
// ======================================================================

class _RecentTransactionTile
    extends StatelessWidget {
  final TransactionModel transaction;
  final String dateText;
  final IconData icon;

  const _RecentTransactionTile({
    required this.transaction,
    required this.dateText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF1A2724)
        : const Color(0xFFEFF3E6);

    final currency =
        SettingsService.currency.value;

    final amount =
    transaction.amount.abs();

    final prefix =
    transaction.isIncome ? '+' : '-';

    final amountColor =
    transaction.isIncome
        ? const Color(0xFF5C9E1E)
        : Theme.of(context)
        .colorScheme
        .onSurface;

    return InkWell(
      borderRadius:
      BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddTransactionScreen(
                  transaction: transaction,
                ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF24332F)
                    : const Color(0xFFF8FAF3),
                borderRadius:
                BorderRadius.circular(15),
              ),
              child: Icon(icon),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${transaction.category} • $dateText',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              '$prefix $currency${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight:
                FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// EMPTY
// ======================================================================

class _EmptyRecentTransactions
    extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRecentTransactions({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 42,
          ),

          const SizedBox(height: 12),

          const Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Start tracking your money by adding your first transaction.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Add Transaction',
            ),
          ),
        ],
      ),
    );
  }
}