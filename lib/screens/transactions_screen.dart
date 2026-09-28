import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController searchController = TextEditingController();
  int selectedFilter = 0; // 0: All, 1: Expense, 2: Income
  String selectedCategory = 'All';

  final List<String> typeFilters = const ['All', 'Expense', 'Income'];

  final List<String> categories = const [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other'
  ];

  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF9500),
    'Transport': Color(0xFF007AFF),
    'Shopping': Color(0xFFAF52DE),
    'Bills': Color(0xFFFF3B30),
    'Entertainment': Color(0xFFFF2D55),
    'Health': Color(0xFF34C759),
    'Education': Color(0xFF30B0C7),
    'Other': Color(0xFF8E8E93),
  };

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
    if (mounted) setState(() {});
  }

  String _formatAmount(double amount) {
    final currency = SettingsService.currency.value;
    return '$currency${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (itemDate == yesterday) return 'Yesterday';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
    return categoryColors[category] ?? const Color(0xFF8E8E93);
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    final query = searchController.text.trim().toLowerCase();

    return transactions.where((tx) {
      if (selectedFilter == 1 && !tx.isExpense) return false;
      if (selectedFilter == 2 && !tx.isIncome) return false;

      if (selectedCategory != 'All' && tx.category != selectedCategory) {
        return false;
      }

      if (query.isEmpty) return true;

      return tx.title.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query) ||
          tx.note.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFEBEFF5);

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<List<TransactionModel>>(
          valueListenable: TransactionService.transactions,
          builder: (context, transactions, child) {
            final filtered = _filterTransactions(transactions);

            // Group filtered items by date header
            final grouped = <String, List<TransactionModel>>{};
            for (final tx in filtered) {
              final header = _formatDateHeader(tx.date);
              grouped.putIfAbsent(header, () => []).add(tx);
            }

            return CustomScrollView(
              slivers: [
                // Top Header & Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          children: [
                            Text(
                              'Transactions',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF121417),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddTransactionScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : const Color(0xFF121417),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: isDark ? const Color(0xFF121417) : Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF121417) : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Search Bar (Conceptzilla rounded input)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E222A) : const Color(0xFFEFF2F6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search_rounded,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                                size: 20,
                              ),
                              hintText: 'Search operations, merchants...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                              ),
                              border: InputBorder.none,
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => searchController.clear(),
                              )
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Type Filter Pills (All | Expense | Income)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E222A) : const Color(0xFFEFF2F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: List.generate(typeFilters.length, (idx) {
                              final isSelected = selectedFilter == idx;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedFilter = idx),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF121418) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        typeFilters[idx],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? (isDark ? Colors.white : const Color(0xFF121417))
                                              : const Color(0xFF8A9099),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Horizontal Category Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((cat) {
                              final isSelected = selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedCategory = selected ? cat : 'All';
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF555B63)),
                                  ),
                                  selectedColor: const Color(0xFF121417),
                                  backgroundColor: isDark ? const Color(0xFF1E222A) : const Color(0xFFEFF2F6),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),

                // Transactions List
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final groupKey = grouped.keys.elementAt(index);
                          final groupItems = grouped[groupKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 10),
                                child: Text(
                                  groupKey,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A9099),
                                  ),
                                ),
                              ),

                              // Card containing transactions in this date group
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: cardBorder, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(isDark ? 20 : 6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groupItems.length,
                                  separatorBuilder: (context, index) => Divider(
                                    color: isDark ? Colors.white10 : const Color(0xFFF0F3F7),
                                    height: 1,
                                  ),
                                  itemBuilder: (context, itemIdx) {
                                    final tx = groupItems[itemIdx];
                                    final color = _categoryColor(tx.category);
                                    final isIncome = tx.isIncome;

                                    return Dismissible(
                                      key: Key(tx.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 18),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF3B30),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onDismissed: (_) async {
                                        await TransactionService.delete(tx.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Transaction deleted'),
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                textColor: const Color(0xFFB7F23D),
                                                onPressed: () async {
                                                  await TransactionService.add(tx);
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
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
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          child: Row(
                                            children: [
                                              // Circular Icon
                                              Container(
                                                width: 42,
                                                height: 42,
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

                                              // Title & Note
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
                                                    const SizedBox(height: 2),
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

                                              // Amount
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
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                        childCount: grouped.keys.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}