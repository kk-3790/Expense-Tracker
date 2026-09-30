import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'ai_chat_screen.dart';

class PlanAheadScreen extends StatefulWidget {
  const PlanAheadScreen({super.key});

  @override
  State<PlanAheadScreen> createState() => _PlanAheadScreenState();
}

class _PlanAheadScreenState extends State<PlanAheadScreen> {
  late double _customBudget;

  @override
  void initState() {
    super.initState();
    _customBudget = SettingsService.monthlyBudget.value > 0
        ? SettingsService.monthlyBudget.value
        : (TransactionService.totalExpense > 0
            ? TransactionService.totalExpense * 1.1
            : 30000.0);
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService.currency.value;
    final totalExpense = TransactionService.totalExpense;
    final totalIncome = TransactionService.totalIncome > 0
        ? TransactionService.totalIncome
        : 60000.0;
    final catTotals = TransactionService.categoryTotals();
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final goals = GoalService.goals.value;

    final needsBudget = totalIncome * 0.50;
    final wantsBudget = totalIncome * 0.30;
    final savingsBudget = totalIncome * 0.20;

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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                color: PaisaTheme.primaryGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'Plan Ahead',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PaisaTheme.card,
                  const Color(0xFF1B2234),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Next Month Projection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AI Forecast',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$currency${(totalExpense * 1.05).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Target Budget Cap: $currency${_customBudget.toStringAsFixed(0)} • Forecast is within your monthly safety parameters.',
                  style: const TextStyle(fontSize: 12.5, color: PaisaTheme.textLightGray),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 50 / 30 / 20 Rule Section
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PaisaTheme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PaisaTheme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded,
                        color: PaisaTheme.primaryGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '50 / 30 / 20 Budgeting Rule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRuleRow(
                  title: 'Needs (50%)',
                  subtitle: 'Rent, groceries, utilities, transit',
                  amount: '$currency${needsBudget.toStringAsFixed(0)}',
                  color: PaisaTheme.primaryGreen,
                  progress: 0.50,
                ),
                const Divider(color: PaisaTheme.surfaceBorder, height: 24),
                _buildRuleRow(
                  title: 'Wants (30%)',
                  subtitle: 'Dining out, shopping, entertainment',
                  amount: '$currency${wantsBudget.toStringAsFixed(0)}',
                  color: const Color(0xFFF472B6),
                  progress: 0.30,
                ),
                const Divider(color: PaisaTheme.surfaceBorder, height: 24),
                _buildRuleRow(
                  title: 'Savings & Goals (20%)',
                  subtitle: 'Bicycle, emergency fund, investments',
                  amount: '$currency${savingsBudget.toStringAsFixed(0)}',
                  color: const Color(0xFF60A5FA),
                  progress: 0.20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Category Allocation Targets
          if (sortedCats.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: PaisaTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Category Ceilings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Setting category caps prevents unplanned spikes in your expenditure.',
                    style: TextStyle(fontSize: 12, color: PaisaTheme.textGray),
                  ),
                  const SizedBox(height: 14),
                  ...sortedCats.take(4).map((c) {
                    final target = (c.value * 0.9).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 5,
                                backgroundColor:
                                    PaisaTheme.getCategoryColor(c.key),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Target: $currency$target',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: PaisaTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Savings Goals Plan
          if (goals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: PaisaTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Goals Acceleration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...goals.map((g) {
                    final monthlyContribution =
                        (g.remainingAmount / 4).clamp(500, 50000).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Remaining: $currency${g.remainingAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: PaisaTheme.textLightGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: PaisaTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: PaisaTheme.surfaceBorder),
                            ),
                            child: Text(
                              'Save $currency$monthlyContribution/mo',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: PaisaTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action button: Ask AI to customize plan
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatScreen()),
                );
              },
              icon: const Icon(Icons.smart_toy_rounded, size: 20),
              label: const Text(
                'Customize Plan with AI Bot',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PaisaTheme.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: PaisaTheme.textGray),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: PaisaTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
