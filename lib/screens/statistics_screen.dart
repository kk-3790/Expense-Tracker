import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'ai_insights_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedGraphPeriod = 0; // 0: 7 days, 1: 30 days, 2: 1 year
  int _selectedCategoryPeriod = 0; // 0: 7 days, 1: 30 days, 2: 1 year
  int _touchedBarIndex = 6; // Highlight today by default
  int _touchedDonutIndex = -1;

  final List<String> _periodOptions = ['7 days', '30 days', '1 year'];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, transactions, child) {
        final now = DateTime.now();

        // 1. Dynamic expenses computation based on _selectedGraphPeriod
        final List<String> dayLabels = [];
        final List<double> chartExpenses = [];
        final double barWidth;

        if (_selectedGraphPeriod == 0) {
          // 7 days: 7 daily bars (mon - sun)
          barWidth = 14.0;
          final weekdayNames = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
          for (int i = 0; i < 7; i++) {
            final dayDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
            dayLabels.add(weekdayNames[dayDate.weekday - 1]);

            final dayTotal = transactions.where((t) {
              if (!t.isExpense) return false;
              final d = t.date.toLocal();
              return d.year == dayDate.year &&
                  d.month == dayDate.month &&
                  d.day == dayDate.day;
            }).fold(0.0, (sum, t) => sum + t.amount);

            chartExpenses.add(dayTotal);
          }
        } else if (_selectedGraphPeriod == 1) {
          // 30 days: 5 interval bars of 6 days each
          barWidth = 16.0;
          for (int i = 0; i < 5; i++) {
            final int daysAgoEnd = (4 - i) * 6;
            final int daysAgoStart = daysAgoEnd + 5;
            final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgoStart));
            final end = DateTime(now.year, now.month, now.day, 23, 59, 59).subtract(Duration(days: daysAgoEnd));

            dayLabels.add('${start.day} ${_monthShort(start.month)}');

            final intervalTotal = transactions.where((t) {
              if (!t.isExpense) return false;
              final d = t.date.toLocal();
              return !d.isBefore(start) && !d.isAfter(end);
            }).fold(0.0, (sum, t) => sum + t.amount);

            chartExpenses.add(intervalTotal);
          }
        } else {
          // 1 year: 12 monthly bars (Jan - Dec)
          barWidth = 9.0;
          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          for (int m = 1; m <= 12; m++) {
            dayLabels.add(monthNames[m - 1]);

            final monthTotal = transactions.where((t) {
              if (!t.isExpense) return false;
              final d = t.date.toLocal();
              return d.year == now.year && d.month == m;
            }).fold(0.0, (sum, t) => sum + t.amount);

            chartExpenses.add(monthTotal);
          }
        }

        final double maxDaily = chartExpenses.isEmpty ? 0.0 : chartExpenses.reduce(math.max);
        final double chartMaxY =
            maxDaily > 0 ? (maxDaily * 1.3).ceilToDouble() : 1000.0;
        final double interval = (chartMaxY / 5).ceilToDouble();

        // 2. Dynamic Category filtering based on _selectedCategoryPeriod
        final filteredExpenses = transactions.where((tx) {
          if (!tx.isExpense) return false;
          final txDate = tx.date.toLocal();
          final Duration diff = now.difference(txDate);
          if (diff.isNegative) return true;
          final diffDays = diff.inDays;
          if (_selectedCategoryPeriod == 0) {
            return diffDays <= 7;
          } else if (_selectedCategoryPeriod == 1) {
            return diffDays <= 30;
          } else {
            return diffDays <= 365;
          }
        }).toList();

        final categoryMap = <String, double>{};
        for (final tx in filteredExpenses) {
          final cat = tx.category.isNotEmpty ? tx.category : 'Other';
          categoryMap[cat] = (categoryMap[cat] ?? 0) + tx.amount;
        }

        final sortedCategories = categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          backgroundColor: PaisaTheme.background,
          appBar: AppBar(
            backgroundColor: PaisaTheme.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Expense tracking',
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
              // ======================================================
              // CARD 1: Expenses Graph (7 days vertical bar chart)
              // ======================================================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expenses Graph',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        _buildDropdownPill(
                          value: _periodOptions[_selectedGraphPeriod],
                          onTap: () {
                            setState(() {
                              _selectedGraphPeriod =
                                  (_selectedGraphPeriod + 1) %
                                      _periodOptions.length;
                              _touchedBarIndex = -1;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bar Chart
                    SizedBox(
                      height: 190,
                      child: BarChart(
                        BarChartData(
                          alignment: _selectedGraphPeriod == 2
                              ? BarChartAlignment.spaceAround
                              : BarChartAlignment.spaceBetween,
                          maxY: chartMaxY,
                          barTouchData: BarTouchData(
                            touchCallback:
                                (FlTouchEvent event, barTouchResponse) {
                              if (event.isInterestedForInteractions &&
                                  barTouchResponse != null &&
                                  barTouchResponse.spot != null) {
                                setState(() {
                                  _touchedBarIndex = barTouchResponse
                                      .spot!.touchedBarGroupIndex;
                                });
                              }
                            },
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => PaisaTheme.surface,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '₹ ${rod.toY.toInt()}',
                                  const TextStyle(
                                    color: PaisaTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                interval: interval > 0 ? interval : 200,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0 || value > chartMaxY) {
                                    return const SizedBox.shrink();
                                  }
                                  if (value >= 1000) {
                                    return _yAxisLabel(
                                        '${(value / 1000).toStringAsFixed(1)}k');
                                  }
                                  return _yAxisLabel(value.toInt().toString());
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < dayLabels.length) {
                                    final isHigh = idx == _touchedBarIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        dayLabels[idx],
                                        style: TextStyle(
                                          color: isHigh
                                              ? Colors.white
                                              : PaisaTheme.textMuted,
                                          fontSize: _selectedGraphPeriod == 2
                                              ? 9.5
                                              : 11,
                                          fontWeight: isHigh
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                interval > 0 ? interval : 200,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: PaisaTheme.surfaceBorder.withAlpha(80),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(chartExpenses.length, (i) {
                            return _buildBarGroup(
                                i, chartExpenses[i], barWidth);
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ======================================================
              // CARD 2: AI Insights Banner ("Track with AI →")
              // ======================================================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: PaisaTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: 'AI ',
                            style: TextStyle(color: PaisaTheme.primaryGreen),
                          ),
                          TextSpan(text: 'Insights'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiInsightsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Track with AI',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ======================================================
              // CARD 3: Expense Categories (Donut chart & breakdown list)
              // ======================================================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expense Categories',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        _buildDropdownPill(
                          value: _periodOptions[_selectedCategoryPeriod],
                          onTap: () {
                            setState(() {
                              _selectedCategoryPeriod =
                                  (_selectedCategoryPeriod + 1) %
                                      _periodOptions.length;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    if (sortedCategories.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        alignment: Alignment.center,
                        child: const Text(
                          'No expenses recorded in this period',
                          style: TextStyle(
                            color: PaisaTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      // Donut Chart + Categories List
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Interactive Donut Ring
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedDonutIndex = -1;
                                        return;
                                      }
                                      _touchedDonutIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 4,
                                centerSpaceRadius: 42,
                                startDegreeOffset: -90,
                                sections: sortedCategories
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  final isTouched = idx == _touchedDonutIndex;
                                  return PieChartSectionData(
                                    color: PaisaTheme.getCategoryColor(item.key),
                                    value: item.value,
                                    radius: isTouched ? 20 : 15,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // Categories breakdown list with values
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedCategories.take(5).map((entry) {
                                final color =
                                    PaisaTheme.getCategoryColor(entry.key);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: PaisaTheme.textLightGray,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '₹${entry.value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ======================================================
              // CARD 4: Budget Recommendations - from AI
              // ======================================================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Recommendations - from AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our recommendations to optimize your budget',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: PaisaTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RecommendationBullet(
                      number: '1',
                      text: sortedCategories.isNotEmpty
                          ? 'Your highest spending category is ${sortedCategories.first.key} (₹${sortedCategories.first.value.toStringAsFixed(0)}). Consider keeping an eye on this category to optimize your budget.'
                          : 'Allocate 20% of your income to savings to meet your financial goals.',
                    ),
                    const SizedBox(height: 12),
                    _RecommendationBullet(
                      number: '2',
                      text: sortedCategories.length > 1
                          ? 'Track ${sortedCategories[1].key} expenses (₹${sortedCategories[1].value.toStringAsFixed(0)}) regularly to ensure you stay within your monthly budget limits.'
                          : 'Reduce discretionary spending on entertainment to stay within limits.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, double width) {
    final isSelected = x == _touchedBarIndex;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isSelected ? PaisaTheme.primaryGreen : const Color(0xFF2C3038),
          width: width,
          borderRadius: BorderRadius.circular(width / 2),
        ),
      ],
    );
  }

  static String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return m[month - 1];
    return '';
  }

  Widget _yAxisLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: PaisaTheme.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdownPill({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: PaisaTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PaisaTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: PaisaTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: PaisaTheme.textGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationBullet extends StatelessWidget {
  final String number;
  final String text;

  const _RecommendationBullet({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: PaisaTheme.primaryGreen,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: PaisaTheme.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}