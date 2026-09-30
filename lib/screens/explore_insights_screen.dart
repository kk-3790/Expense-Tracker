import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemini_service.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'ai_chat_screen.dart';

class ExploreInsightsScreen extends StatefulWidget {
  const ExploreInsightsScreen({super.key});

  @override
  State<ExploreInsightsScreen> createState() => _ExploreInsightsScreenState();
}

class _ExploreInsightsScreenState extends State<ExploreInsightsScreen> {
  List<String> _insights = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    final results = await GeminiService.fetchDynamicInsights();
    if (mounted) {
      setState(() {
        _insights = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService.currency.value;
    final balance = TransactionService.balance;
    final totalExpense = TransactionService.totalExpense;
    final totalIncome = TransactionService.totalIncome;
    final catTotals = TransactionService.categoryTotals();
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final goals = GoalService.goals.value;

    // Calculate a dynamic Financial Health Score (0-100)
    int healthScore = 70;
    if (balance > 20000) healthScore += 10;
    if (totalIncome > totalExpense) healthScore += 10;
    if (goals.any((g) => g.progressPercentage >= 0.5)) healthScore += 10;
    healthScore = healthScore.clamp(40, 98);

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
            const Icon(Icons.auto_awesome_rounded,
                color: PaisaTheme.primaryGreen, size: 20),
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
                      style: TextStyle(color: PaisaTheme.primaryGreen)),
                  TextSpan(text: 'Deep Insights'),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Insights',
            onPressed: _isLoading ? null : _loadInsights,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // ====================================================
          // HEALTH SCORE CARD
          // ====================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PaisaTheme.card,
                  const Color(0xFF1B2B1B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: PaisaTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 6,
                        backgroundColor: PaisaTheme.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            PaisaTheme.primaryGreen),
                      ),
                    ),
                    Text(
                      '$healthScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Health Score',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthScore >= 80
                            ? 'Excellent! Your savings rate and cash balance are well balanced.'
                            : 'Good baseline. Consider trimming your top spending category to optimize cash flow.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PaisaTheme.textLightGray,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // LIVE GEMINI AI INSIGHTS
          // ====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      color: PaisaTheme.primaryGreen, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Personalized AI Tips',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PaisaTheme.primaryGreen,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _loadInsights,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 14, color: PaisaTheme.primaryGreen),
                  label: const Text(
                    'Re-analyze',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PaisaTheme.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_insights.isEmpty && _isLoading) ...[
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PaisaTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(color: PaisaTheme.primaryGreen),
                  SizedBox(height: 14),
                  Text(
                    'Analyzing expenses with Google Gemini...',
                    style: TextStyle(fontSize: 13, color: PaisaTheme.textLightGray),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._insights.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final text = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: PaisaTheme.primaryGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              color: PaisaTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tip copied to clipboard'),
                                backgroundColor: PaisaTheme.primaryGreen,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13, color: PaisaTheme.textGray),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                    fontSize: 11, color: PaisaTheme.textGray),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiChatScreen(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 13, color: PaisaTheme.primaryGreen),
                              SizedBox(width: 4),
                              Text(
                                'Ask AI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: PaisaTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          // ====================================================
          // SPENDING PREDICTIONS & OPTIMIZATION
          // ====================================================
          Container(
            padding: const EdgeInsets.all(20),
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
                    Icon(Icons.trending_up_rounded,
                        color: Color(0xFF60A5FA), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '30-Day Budget Optimization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sortedCats.isNotEmpty) ...[
                  Text(
                    'Your top category is ${sortedCats.first.key} at $currency${sortedCats.first.value.toStringAsFixed(0)}. Below is your recommended allocation:',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: PaisaTheme.textLightGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...sortedCats.take(3).map((e) {
                    final recommended = (e.value * 0.85).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$currency${e.value.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: PaisaTheme.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Target: $currency$recommended',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: PaisaTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  const Text(
                    'Add more transactions to receive individualized category targets.',
                    style: TextStyle(fontSize: 12.5, color: PaisaTheme.textLightGray),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button: Chat with AI
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
                'Discuss Plan with Paisa AI',
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
}
