import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {
  final TextEditingController searchController =
  TextEditingController();

  int selectedFilter = 0;

  final List<String> filters = const [
    'All',
    'Expense',
    'Income',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<TransactionModel> _getFilteredTransactions(
      List<TransactionModel> transactions,
      ) {
    final query =
    searchController.text.trim().toLowerCase();

    return transactions.where((transaction) {
      bool matchesType = true;

      if (selectedFilter == 1) {
        matchesType = transaction.isExpense;
      } else if (selectedFilter == 2) {
        matchesType = transaction.isIncome;
      }

      if (!matchesType) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return transaction.title
          .toLowerCase()
          .contains(query) ||
          transaction.category
              .toLowerCase()
              .contains(query) ||
          transaction.note
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  // ============================================================
  // DATE
  // ============================================================

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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  String _formatAmount(
      TransactionModel transaction,
      ) {
    final currency =
        SettingsService.currency.value;

    final amount = transaction.amount.abs();

    final prefix =
    transaction.isIncome ? '+' : '-';

    return '$prefix $currency${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editTransaction(
      TransactionModel transaction,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddTransactionScreen(
              transaction: transaction,
            ),
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> _deleteTransaction(
      TransactionModel transaction,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete transaction?',
          ),
          content: Text(
            'Delete "${transaction.title}" permanently?',
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
                'Delete',
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

    if (confirmed != true) {
      return false;
    }

    await TransactionService.delete(
      transaction.id,
    );

    if (!mounted) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction deleted',
        ),
      ),
    );

    return true;
  }

  // ============================================================
  // FILTER SHEET
  // ============================================================

  void _showFilterSheet() {
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
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                ...List.generate(
                  filters.length,
                      (index) {
                    final selected =
                        selectedFilter == index;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      tileColor: selected
                          ? const Color(0xFFB7F23D)
                          : null,
                      leading: Icon(
                        index == 0
                            ? Icons.receipt_long_rounded
                            : index == 1
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                      ),
                      title: Text(
                        filters[index],
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                        Icons.check_circle_rounded,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          selectedFilter = index;
                        });

                        Navigator.pop(sheetContext);
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ========================================================
            // HEADER
            // ========================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transactions',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _showFilterSheet,
                    icon: const Icon(
                      Icons.filter_list_rounded,
                    ),
                    tooltip: 'Filter',
                  ),
                ],
              ),
            ),

            // ========================================================
            // SEARCH
            // ========================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                height: 54,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction:
                  TextInputAction.search,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: const Icon(
                      Icons.search_rounded,
                    ),
                    hintText:
                    'Search transactions...',
                    suffixIcon:
                    searchController.text
                        .isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        searchController.clear();
                      },
                      icon: const Icon(
                        Icons.clear_rounded,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // FILTER CHIPS
            // ========================================================

            SizedBox(
              height: 42,
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final selected =
                      selectedFilter == index;

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      right: 10,
                    ),
                    child: ChoiceChip(
                      label: Text(filters[index]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = index;
                        });
                      },
                      selectedColor:
                      const Color(0xFFB7F23D),
                      labelStyle: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ========================================================
            // TRANSACTIONS
            // ========================================================

            Expanded(
              child: ValueListenableBuilder<
                  List<TransactionModel>>(
                valueListenable:
                TransactionService.transactions,
                builder: (
                    context,
                    transactions,
                    child,
                    ) {
                  final filtered =
                  _getFilteredTransactions(
                    transactions,
                  );

                  if (filtered.isEmpty) {
                    return _EmptyTransactions(
                      isSearching:
                      searchController.text
                          .trim()
                          .isNotEmpty,
                    );
                  }

                  return ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      30,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction =
                      filtered[index];

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _TransactionTile(
                          transaction: transaction,
                          dateText:
                          _formatDate(
                            transaction.date,
                          ),
                          amountText:
                          _formatAmount(
                            transaction,
                          ),
                          onEdit: () {
                            _editTransaction(
                              transaction,
                            );
                          },
                          onDelete: () {
                            return _deleteTransaction(
                              transaction,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// EMPTY STATE
// ======================================================================

class _EmptyTransactions
    extends StatelessWidget {
  final bool isSearching;

  const _EmptyTransactions({
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 60,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(height: 18),

            Text(
              isSearching
                  ? 'No matching transactions'
                  : 'No transactions yet',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSearching
                  ? 'Try another search term.'
                  : 'Add your first transaction from Home.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// TRANSACTION TILE
// ======================================================================

class _TransactionTile
    extends StatelessWidget {
  final TransactionModel transaction;
  final String dateText;
  final String amountText;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.dateText,
    required this.amountText,
    required this.onEdit,
    required this.onDelete,
  });

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
        return transaction.isIncome
            ? Icons.account_balance_wallet_rounded
            : Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF1A2724)
        : const Color(0xFFEFF3E6);

    final iconBackground = isDark
        ? const Color(0xFF24332F)
        : const Color(0xFFF8FAF3);

    final amountColor = transaction.isIncome
        ? const Color(0xFF5C9E1E)
        : Theme.of(context)
        .colorScheme
        .onSurface;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction:
      DismissDirection.endToStart,

      confirmDismiss: (_) async {
        return await onDelete();
      },

      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB3261E),
          borderRadius:
          BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding:
        const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),
        onTap: onEdit,

        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
            BorderRadius.circular(20),
          ),

          child: Row(
            children: [
              // ICON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: Icon(
                  _categoryIcon(
                    transaction.category,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // DETAILS
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
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      transaction.note
                          .trim()
                          .isEmpty
                          ? '${transaction.category} • $dateText'
                          : '${transaction.note} • $dateText',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
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

              const SizedBox(width: 10),

              // AMOUNT
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}