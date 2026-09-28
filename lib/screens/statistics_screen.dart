import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime selectedDate = DateTime.now();
  int selectedPeriodIndex = 1; // 0: Week, 1: Month, 2: Year
  int touchedIndex = -1;

  static const List<String> periods = ['Week', 'Month', 'Year'];

  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF9500),         // Orange
    'Transport': Color(0xFF007AFF),    // Blue
    'Shopping': Color(0xFFAF52DE),     // Purple
    'Bills': Color(0xFFFF3B30),        // Coral
    'Entertainment': Color(0xFFFF2D55),// Pink
    'Health': Color(0xFF34C759),       // Green
    'Education': Color(0xFF30B0C7),    // Teal
    'Other': Color(0xFF5856D6),        // Indigo
  };

  String _periodLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    if (selectedPeriodIndex == 0) {
      return 'this Week';
    } else if (selectedPeriodIndex == 1) {
      return 'this ${months[date.month - 1]}';
    } else {
      return 'in ${date.year}';
    }
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(12, (index) {
                    final monthNum = index + 1;
                    final isCurrent = selectedDate.month == monthNum;
                    final isFuture = selectedDate.year == now.year && monthNum > now.month;

                    return ChoiceChip(
                      label: Text(months[index]),
                      selected: isCurrent,
                      onSelected: isFuture
                          ? null
                          : (selected) {
                        if (selected) {
                          setState(() {
                            selectedDate = DateTime(selectedDate.year, monthNum);
                          });
                          Navigator.pop(sheetContext);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return categoryColors[category] ?? const Color(0xFF5856D6);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171A21) : Colors.white;
    final cardBorder = isDark ? Colors.white10 : const Color(0xFFEBEFF5);
    final currency = SettingsService.currency.value;

    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, transactions, child) {
        // Filter transactions for selected period
        final filteredExpenses = transactions.where((tx) {
          if (!tx.isExpense) return false;

          if (selectedPeriodIndex == 0) {
            // Week filter
            final diff = tx.date.difference(selectedDate).inDays;
            return diff.abs() <= 7;
          } else if (selectedPeriodIndex == 1) {
            // Month filter
            return tx.date.year == selectedDate.year &&
                tx.date.month == selectedDate.month;
          } else {
            // Year filter
            return tx.date.year == selectedDate.year;
          }
        }).toList();

        // Calculate totals and group by category
        double totalExpense = 0;
        final categoryTotals = <String, double>{};

        for (final tx in filteredExpenses) {
          totalExpense += tx.amount;
          categoryTotals[tx.category] =
              (categoryTotals[tx.category] ?? 0) + tx.amount;
        }

        // Sort categories by highest spend
        final sortedEntries = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (touchedIndex >= sortedEntries.length) {
          touchedIndex = -1;
        }

        final isAnyTouched = touchedIndex >= 0 && touchedIndex < sortedEntries.length;
        final touchedEntry = isAnyTouched ? sortedEntries[touchedIndex] : null;
        final touchedPct = isAnyTouched && totalExpense > 0
            ? (touchedEntry!.value / totalExpense) * 100
            : 0.0;
        final touchedColor = isAnyTouched
            ? _categoryColor(touchedEntry!.key)
            : Colors.transparent;

        // Screen-adaptive sizing for pie chart
        final screenWidth = MediaQuery.of(context).size.width;
        final chartDiameter = (screenWidth * 0.68).clamp(240.0, 285.0);
        const ringThickness = 22.0;
        final centerRadius = (chartDiameter / 2) - ringThickness - 6.0;

        // Build Donut Sections
        final sections = <PieChartSectionData>[];
        if (totalExpense > 0) {
          for (int i = 0; i < sortedEntries.length; i++) {
            final entry = sortedEntries[i];
            final pct = (entry.value / totalExpense) * 100;
            final color = _categoryColor(entry.key);
            final isTouched = i == touchedIndex;
            final radius = isTouched ? ringThickness + 6.0 : ringThickness;

            sections.add(
              PieChartSectionData(
                color: color,
                value: entry.value,
                radius: radius,
                showTitle: isTouched || pct >= 7.0,
                title: '${pct.toStringAsFixed(0)}%',
                titlePositionPercentageOffset: 0.55,
                titleStyle: TextStyle(
                  fontSize: isTouched ? 12.5 : 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Top Screen Title
                Row(
                  children: [
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF121417),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ======================================================
                // CIRCULAR DONUT CHART (Conceptzilla Responsive & Interactive)
                // ======================================================
                SizedBox(
                  height: chartDiameter + 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Donut Chart or Empty Ring
                      RepaintBoundary(
                        child: SizedBox(
                          width: chartDiameter,
                          height: chartDiameter,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    final idx = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                    if (idx >= 0 && idx < sortedEntries.length) {
                                      touchedIndex = idx;
                                    } else {
                                      touchedIndex = -1;
                                    }
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: centerRadius,
                              startDegreeOffset: -90,
                              sections: sections.isNotEmpty
                                  ? sections
                                  : [
                                      PieChartSectionData(
                                        color: isDark
                                            ? const Color(0xFF1E222A)
                                            : const Color(0xFFE9ECF1),
                                        value: 1,
                                        radius: ringThickness,
                                        showTitle: false,
                                      ),
                                    ],
                            ),
                          ),
                        ),
                      ),

                      // Center Typography: Interactive Selection or Period Spend
                      SizedBox(
                        width: centerRadius * 1.55,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (touchedEntry != null) ...[
                              // Touched Category Pill
                              GestureDetector(
                                onTap: () => setState(() => touchedIndex = -1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: touchedColor.withAlpha(isDark ? 45 : 30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: touchedColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          touchedEntry.key,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF121417),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Touched Amount with FittedBox
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency${touchedEntry.value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF121417),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${touchedPct.toStringAsFixed(0)}% of spending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8A9099),
                                ),
                              ),
                            ] else ...[
                              // Default: Spent this Month / Period Dropdown
                              GestureDetector(
                                onTap: () => _showMonthPicker(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withAlpha(15)
                                        : const Color(0xFFEFF2F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Spent ${_periodLabel(selectedDate)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF8E8E93)
                                              : const Color(0xFF8A9099),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 15,
                                        color: isDark
                                            ? const Color(0xFF8E8E93)
                                            : const Color(0xFF8A9099),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Total Amount with FittedBox
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currency${totalExpense.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF121417),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalExpense > 0
                                    ? '${sortedEntries.length} ${sortedEntries.length == 1 ? 'category' : 'categories'}'
                                    : 'No expenses yet',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8A9099),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ======================================================
                // PERIOD TOGGLE: Week | Month | Year (Conceptzilla)
                // ======================================================
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222A) : const Color(0xFFEFF2F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(periods.length, (idx) {
                        final isSelected = selectedPeriodIndex == idx;
                        return GestureDetector(
                          onTap: () => setState(() {
                            selectedPeriodIndex = idx;
                            touchedIndex = -1;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
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
                            child: Text(
                              periods[idx],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.white : const Color(0xFF121417))
                                    : const Color(0xFF8A9099),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ======================================================
                // SPENDING CATEGORIES SECTION (2x2 Grid)
                // ======================================================
                Text(
                  'Spending Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF121417),
                  ),
                ),

                const SizedBox(height: 16),

                if (sortedEntries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder, width: 1.2),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 40,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No expenses in this period',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedEntries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    itemBuilder: (context, index) {
                      final item = sortedEntries[index];
                      final pct = totalExpense > 0
                          ? (item.value / totalExpense) * 100
                          : 0.0;
                      final color = _categoryColor(item.key);
                      final isSelectedCard = touchedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            touchedIndex = touchedIndex == index ? -1 : index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelectedCard
                                ? color.withAlpha(isDark ? 40 : 25)
                                : cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelectedCard ? color : cardBorder,
                              width: isSelectedCard ? 1.8 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelectedCard
                                    ? color.withAlpha(30)
                                    : Colors.black.withAlpha(isDark ? 25 : 6),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Row: Amount & Percentage
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$currency${item.value.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF121417),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelectedCard
                                          ? color
                                          : (isDark
                                              ? Colors.white10
                                              : const Color(0xFFEFF2F6)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelectedCard
                                            ? Colors.white
                                            : (isDark
                                                ? const Color(0xFF8E8E93)
                                                : const Color(0xFF8A9099)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom Row: Category Name & Circular Icon Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.key,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelectedCard
                                            ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF121417))
                                            : (isDark
                                                ? const Color(0xFF8E8E93)
                                                : const Color(0xFF8A9099)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(isDark ? 45 : 30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _categoryIcon(item.key),
                                      size: 16,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}