import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'ai_chat_screen.dart';
import 'explore_insights_screen.dart';
import 'plan_ahead_screen.dart';
import '../services/gemini_service.dart';
import '../services/settings_service.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  List<String> _dynamicInsights = [];

  @override
  void initState() {
    super.initState();
    _fetchMoreInsights();
  }

  Future<void> _fetchMoreInsights() async {
    try {
      final insights = await GeminiService.fetchDynamicInsights();
      if (mounted) {
        setState(() {
          _dynamicInsights = insights;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, transactions, child) {
        final catTotals = TransactionService.categoryTotals();
        final sortedCats = catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCats = sortedCats.take(3).toList();

        return Scaffold(
          backgroundColor: PaisaTheme.background,
          appBar: AppBar(
            backgroundColor: PaisaTheme.background,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: PaisaTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
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
                      fontSize: 20,
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
              ],
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            children: [
              // ====================================================
              // CARD 1: Expense Predictions
              // ====================================================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: PaisaTheme.surfaceBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Predictions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Based on your past spending, here are your projected expenses for the next month:',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaisaTheme.textGray,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (topCats.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text(
                          'No spending history to generate predictions yet.',
                          style: TextStyle(
                            color: PaisaTheme.textGray,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          // Donut Ring
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 36,
                                startDegreeOffset: -90,
                                sections: topCats.map((item) {
                                  return PieChartSectionData(
                                    color: PaisaTheme.getCategoryColor(item.key),
                                    value: item.value,
                                    radius: 16,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Legend
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: topCats.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LegendRow(
                                    color: PaisaTheme.getCategoryColor(item.key),
                                    label: item.key,
                                    amount: '₹ ${item.value.toStringAsFixed(0)}',
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlanAheadScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: PaisaTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Plan Ahead',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // QUICK ACTION: Chat with Paisa AI
          // ====================================================
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiChatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.smart_toy_rounded, size: 20, color: Color(0xFF0F9D58)),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(text: 'Chat with '),
                    TextSpan(
                      text: 'Paisa AI',
                      style: TextStyle(color: Color(0xFF0F9D58)),
                    ),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // CARD 2: Personalized Insights (Google Gemini AI)
          // ====================================================
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PaisaTheme.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: PaisaTheme.surfaceBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Personalized Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (_dynamicInsights.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: PaisaTheme.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PaisaTheme.primaryGreen.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 11, color: PaisaTheme.primaryGreen),
                            SizedBox(width: 4),
                            Text(
                              'Gemini API',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: PaisaTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _dynamicInsights.isNotEmpty
                      ? 'Live insights dynamically generated by Google Gemini API from your real-time expenses:'
                      : 'Based on your spending habits, here are insights to help optimize your finances:',
                  style: const TextStyle(
                    fontSize: 13,
                    color: PaisaTheme.textGray,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                if (_dynamicInsights.isNotEmpty) ...[
                  ..._dynamicInsights.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BulletPoint(
                        number: '${entry.key + 1}',
                        text: entry.value,
                      ),
                    ),
                  ),
                ] else ...[
                  _BulletPoint(
                    number: '1',
                    text: topCats.isNotEmpty
                        ? 'Your highest expense category is ${topCats.first.key} (${SettingsService.currency.value}${topCats.first.value.toStringAsFixed(0)}). Consider setting a weekly budget to save more.'
                        : 'Track all your daily expenses to receive personalized AI optimization tips.',
                  ),
                  const SizedBox(height: 12),
                  const _BulletPoint(
                    number: '2',
                    text: 'Great job maintaining your account! Allocate 20% of your income toward your active savings goals.',
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExploreInsightsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: PaisaTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: PaisaTheme.surfaceBorder,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: PaisaTheme.primaryGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Explore More Insights',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // CARD 3: Budget Recommendations
          // ====================================================
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PaisaTheme.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: PaisaTheme.surfaceBorder,
                width: 1,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Our recommendations to optimize your budget',
                  style: TextStyle(
                    fontSize: 13,
                    color: PaisaTheme.textGray,
                  ),
                ),
                SizedBox(height: 16),
                _BulletPoint(
                  number: '1',
                  text:
                      'Allocate 20% of your income to savings to meet your financial goals.',
                ),
                SizedBox(height: 12),
                _BulletPoint(
                  number: '2',
                  text:
                      'Reduce discretionary spending on entertainment to build an emergency fund.',
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
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PaisaTheme.textLightGray,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String number;
  final String text;

  const _BulletPoint({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: PaisaTheme.primaryGreen,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: PaisaTheme.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}
