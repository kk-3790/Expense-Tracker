import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() =>
      _StatisticsScreenState();
}

class _StatisticsScreenState
    extends State<StatisticsScreen> {
  DateTime selectedMonth = DateTime.now();

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  // ============================================================
  // CATEGORY COLORS
  // ============================================================

  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFFA726),
    'Transport': Color(0xFF42A5F5),
    'Shopping': Color(0xFFAB47BC),
    'Bills': Color(0xFFEF5350),
    'Entertainment': Color(0xFFEC407A),
    'Health': Color(0xFF66BB6A),
    'Education': Color(0xFF26A69A),
    'Other': Color(0xFF78909C),
  };

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  // ============================================================
  // PREVIOUS MONTH
  // ============================================================

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  // ============================================================
  // NEXT MONTH
  // ============================================================

  void _nextMonth() {
    final now = DateTime.now();

    final nextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );

    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year &&
            nextMonth.month > now.month)) {
      return;
    }

    setState(() {
      selectedMonth = nextMonth;
    });
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(double amount) {
    final currency =
        SettingsService.currency.value;

    return '$currency${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

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

  // ============================================================
  // CATEGORY COLOR
  // ============================================================

  Color _categoryColor(String category) {
    return categoryColors[category] ??
        const Color(0xFF78909C);
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
        // ==========================================================
        // THIS MONTH'S TRANSACTIONS
        // ==========================================================

        final monthlyTransactions =
        TransactionService.forMonth(
          selectedMonth.year,
          selectedMonth.month,
        );

        // ==========================================================
        // MONTHLY INCOME
        // ==========================================================

        final monthlyIncome =
        monthlyTransactions
            .where(
              (transaction) =>
          transaction.isIncome,
        )
            .fold<double>(
          0,
              (sum, transaction) =>
          sum +
              transaction.amount.abs(),
        );

        // ==========================================================
        // MONTHLY EXPENSES
        // ==========================================================

        final monthlyExpenses =
        monthlyTransactions
            .where(
              (transaction) =>
          transaction.isExpense,
        )
            .toList();

        final totalExpense =
        monthlyExpenses.fold<double>(
          0,
              (sum, transaction) =>
          sum + transaction.amount.abs(),
        );

        // ==========================================================
        // GROUP EXPENSES BY CATEGORY
        // ==========================================================

        final Map<String, double>
        categoryTotals = {};

        for (final transaction
        in monthlyExpenses) {
          categoryTotals[transaction.category] =
              (categoryTotals[
              transaction.category] ??
                  0) +
                  transaction.amount.abs();
        }

        categoryTotals.removeWhere(
              (_, amount) => amount <= 0,
        );

        // Largest expense first.
        final sortedCategories =
        categoryTotals.entries.toList()
          ..sort(
                (a, b) =>
                b.value.compareTo(
                  a.value,
                ),
          );

        return Scaffold(
          body: SafeArea(
            child: ListView(
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

                Text(
                  'Statistics',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium,
                ),

                const SizedBox(height: 22),

                // ==================================================
                // MONTH SELECTOR
                // ==================================================

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                        _previousMonth,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: Text(
                            '${_monthName(selectedMonth)} ${selectedMonth.year}',
                            style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed:
                        _nextMonth,
                        icon: const Icon(
                          Icons
                              .chevron_right_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SUMMARY
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        value:
                        _money(monthlyIncome),
                        icon: Icons
                            .arrow_downward_rounded,
                        iconColor:
                        const Color(
                          0xFF5C9E1E,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _SummaryCard(
                        title: 'Expenses',
                        value:
                        _money(totalExpense),
                        icon: Icons
                            .arrow_upward_rounded,
                        iconColor:
                        const Color(
                          0xFFB3261E,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // EXPENSE BY CATEGORY
                // ==================================================

                Text(
                  'Expenses by Category',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                Container(
                  height: 340,
                  padding:
                  const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                    BorderRadius.circular(24),
                  ),
                  child: totalExpense > 0
                      ? _ExpenseCategoryChart(
                    categoryTotals:
                    categoryTotals,
                    totalExpense:
                    totalExpense,
                    categoryColors:
                    categoryColors,
                  )
                      : const _NoDataState(
                    message:
                    'No expenses for this month',
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // CATEGORY BREAKDOWN
                // ==================================================

                Text(
                  'Category Breakdown',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                if (sortedCategories.isEmpty)
                  const _NoDataState(
                    message:
                    'No expenses recorded this month',
                  )
                else
                  ...sortedCategories.map(
                        (entry) {
                      final percentage =
                      totalExpense == 0
                          ? 0.0
                          : entry.value /
                          totalExpense;

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _CategoryCard(
                          category:
                          entry.key,
                          amount:
                          entry.value,
                          percentage:
                          percentage,
                          icon:
                          _categoryIcon(
                            entry.key,
                          ),
                          color:
                          _categoryColor(
                            entry.key,
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // ==================================================
                // MONTHLY BALANCE
                // ==================================================

                Text(
                  'Monthly Balance',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                Container(
                  padding:
                  const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFB7F23D),
                    borderRadius:
                    BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0x55FFFFFF,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .account_balance_wallet_rounded,
                          color:
                          Color(0xFF172015),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            const Text(
                              'Net this month',
                              style: TextStyle(
                                color: Color(
                                  0xFF394334,
                                ),
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              _money(
                                monthlyIncome -
                                    totalExpense,
                              ),
                              style:
                              const TextStyle(
                                color: Color(
                                  0xFF172015,
                                ),
                                fontSize: 23,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
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
// SUMMARY CARD
// ======================================================================

class _SummaryCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// EXPENSE CATEGORY CHART
// ======================================================================

class _ExpenseCategoryChart
    extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalExpense;
  final Map<String, Color> categoryColors;

  const _ExpenseCategoryChart({
    required this.categoryTotals,
    required this.totalExpense,
    required this.categoryColors,
  });

  @override
  Widget build(BuildContext context) {
    final entries =
    categoryTotals.entries.toList()
      ..sort(
            (a, b) =>
            b.value.compareTo(a.value),
      );

    final sections =
    entries.map((entry) {
      final percentage =
          (entry.value / totalExpense) *
              100;

      return PieChartSectionData(
        value: entry.value,

        color:
        categoryColors[entry.key] ??
            const Color(0xFF78909C),

        title:
        percentage >= 5
            ? '${percentage.toStringAsFixed(0)}%'
            : '',

        radius: 82,

        titleStyle:
        const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight:
          FontWeight.w800,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 58,
              sectionsSpace: 3,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          alignment:
          WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children:
          entries.map((entry) {
            final color =
                categoryColors[entry.key] ??
                    const Color(0xFF78909C);

            return Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                  BoxDecoration(
                    color: color,
                    shape:
                    BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 5),

                Text(
                  entry.key,
                  style:
                  const TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ======================================================================
// CATEGORY CARD
// ======================================================================

class _CategoryCard
    extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        SettingsService.currency.value;

    return Container(
      padding:
      const EdgeInsets.all(15),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}% of expenses',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),

              Text(
                '$currency${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child:
            LinearProgressIndicator(
              value: percentage.clamp(
                0.0,
                1.0,
              ),
              minHeight: 7,
              backgroundColor:
              Theme.of(context)
                  .colorScheme
                  .surface,
              valueColor:
              AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// NO DATA
// ======================================================================

class _NoDataState
    extends StatelessWidget {
  final String message;

  const _NoDataState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pie_chart_outline_rounded,
            size: 48,
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ],
      ),
    );
  }
}