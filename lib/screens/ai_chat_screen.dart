import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/gemini_service.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const AiChatScreen({super.key, this.initialPrompt});

  static String generateBotReply(String userQuery) {
    return _AiChatScreenState.generateBotReply(userQuery);
  }

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<AiChatMessage> _messages = [
    AiChatMessage(
      text:
          "Hello! 👋 I'm your Paisa AI Financial Assistant. I can track your spending, analyze goals, evaluate purchases, and give you smart budgeting advice. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  final List<String> _suggestedPrompts = [
    'How much did I spend today?',
    'What is my spending this week?',
    'How are my savings goals?',
    'What is my highest expense?',
    'Give me a 50/30/20 budget breakdown',
    'Tips to save money',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(AiChatMessage(
        text: clean,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Call Gemini 3.8 Flash via GeminiService (with automatic local engine fallback)
    final reply = await GeminiService.askGemini(clean);

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(AiChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  static String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  static String generateBotReply(String userQuery) {
    final q = userQuery.toLowerCase().trim();
    final balance = TransactionService.balance;
    final currency = SettingsService.currency.value;
    final budget = SettingsService.monthlyBudget.value;
    final now = DateTime.now();
    final allTxs = TransactionService.transactions.value;
    final expenses = allTxs.where((t) => t.isExpense).toList();
    final goals = GoalService.goals.value;

    // 1. GREETING / INTRO
    if (q == 'hi' ||
        q == 'hello' ||
        q == 'hey' ||
        q.contains('who are you') ||
        q.contains('what can you do') ||
        q.contains('help me')) {
      final monthlyExp = TransactionService.monthlyExpense(now.year, now.month);
      return "Hello! 👋 I'm your Paisa AI Financial Assistant.\n\n"
          "Here is a quick snapshot of your finances:\n"
          "• Total Balance: $currency${balance.toStringAsFixed(0)}\n"
          "• This Month's Expenses: $currency${monthlyExp.toStringAsFixed(0)}\n"
          "• Active Savings Goals: ${goals.length}\n\n"
          "You can ask me anything about your spending, today's expenses, top categories, goal progress, or budgeting tips! 💡";
    }

    // 2. BALANCE / ACCOUNT STATUS
    if (q.contains('balance') || q.contains('net worth') || q.contains('account status')) {
      return "Your total available balance is **$currency${balance.toStringAsFixed(0)}**.\n\n"
          "• Total Income Tracked: $currency${TransactionService.totalIncome.toStringAsFixed(0)}\n"
          "• Total Expenses Tracked: $currency${TransactionService.totalExpense.toStringAsFixed(0)}\n\n"
          "Your cash flow is currently healthy! 💳";
    }

    // 3. TODAY'S SPENDING
    if (q.contains('today') || q.contains('daily spend') || q.contains('spent today')) {
      final todayTxs = expenses.where((t) {
        final d = t.date.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();

      final todayTotal = todayTxs.fold(0.0, (s, t) => s + t.amount);

      if (todayTxs.isEmpty || todayTotal == 0) {
        return "You haven't spent anything today! 🎉 Your total spending today is $currency 0. Great job staying frugal!";
      }

      final itemsSummary = todayTxs
          .take(3)
          .map((t) => "• ${t.title}: $currency${t.amount.toStringAsFixed(0)}")
          .join('\n');
      final moreCount = todayTxs.length - 3;
      final moreText = moreCount > 0 ? "\n...and $moreCount more item(s)" : "";

      return "Today you've spent $currency${todayTotal.toStringAsFixed(0)} across ${todayTxs.length} transaction(s):\n\n$itemsSummary$moreText\n\nKeep track to stay well within your daily allowance! 📊";
    }

    // 3. THIS WEEK'S SPENDING / 7 DAYS
    if (q.contains('week') || q.contains('weekly') || q.contains('7 days')) {
      final weekTxs = expenses.where((t) {
        final d = t.date.toLocal();
        final diff = now.difference(d);
        return !diff.isNegative && diff.inDays <= 7;
      }).toList();

      final weekTotal = weekTxs.fold(0.0, (s, t) => s + t.amount);

      final catMap = <String, double>{};
      for (final t in weekTxs) {
        catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      }
      final topCat = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCatText = topCat.isNotEmpty
          ? "\nYour highest spend category this week is **${topCat.first.key}** ($currency${topCat.first.value.toStringAsFixed(0)})."
          : "";

      return "Your total spending over the last 7 days is **$currency${weekTotal.toStringAsFixed(0)}** across ${weekTxs.length} expense(s).$topCatText\n\nYour available balance is $currency${balance.toStringAsFixed(0)}. 📈";
    }

    // 4. HIGHEST / BIGGEST EXPENSE
    if (q.contains('highest') ||
        q.contains('biggest') ||
        q.contains('largest') ||
        q.contains('most expensive') ||
        q.contains('max spend')) {
      if (expenses.isEmpty) {
        return "You have no recorded expenses yet! Once you add transactions, I'll identify your largest purchases for you. 🛍️";
      }

      final sorted = List<TransactionModel>.from(expenses)
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final top = sorted.first;
      final d = top.date.toLocal();

      return "Your highest recorded expense is **${top.title}** for **$currency${top.amount.toStringAsFixed(0)}** under **${top.category}** on ${d.day} ${_monthName(d.month)} ${d.year}. 🏷️";
    }

    // 5. GOALS / SAVINGS TARGETS
    if (q.contains('goal') ||
        q.contains('saving') ||
        q.contains('bicycle') ||
        q.contains('vacation') ||
        q.contains('fund') ||
        q.contains('target')) {
      if (goals.isEmpty) {
        return "You haven't set up any savings goals yet! 🎯\n\nYou can create goals like 'Emergency Fund', 'New Laptop', or 'Holiday Trip' directly from the Home screen by tapping the '+' card.";
      }

      final buffer = StringBuffer();
      buffer.writeln("Here is your live savings goals progress:\n");
      for (final g in goals) {
        final pct = (g.progressPercentage * 100).toStringAsFixed(0);
        buffer.writeln("• **${g.name}**: $currency${g.currentAmount.toStringAsFixed(0)} of $currency${g.targetAmount.toStringAsFixed(0)} ($pct%) — $currency${g.remainingAmount.toStringAsFixed(0)} left");
      }

      final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
      final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
      final overallPct = totalTarget > 0 ? ((totalSaved / totalTarget) * 100).toStringAsFixed(0) : '0';

      buffer.writeln("\nOverall, you have saved **$currency${totalSaved.toStringAsFixed(0)}** across your goals ($overallPct% completed). Keep up the great discipline! 🚀");
      return buffer.toString();
    }

    // 6. CATEGORY SPENDING (Food, Groceries, Shopping, Transport, Entertainment, Utilities, etc.)
    final categories = [
      'Food',
      'Groceries',
      'Shopping',
      'Transportation',
      'Entertainment',
      'Utilities',
      'Housing',
      'Health',
    ];
    for (final cat in categories) {
      if (q.contains(cat.toLowerCase()) ||
          (cat == 'Food' && (q.contains('dining') || q.contains('restaurant') || q.contains('eat'))) ||
          (cat == 'Transportation' && (q.contains('travel') || q.contains('transit') || q.contains('metro') || q.contains('uber') || q.contains('cab'))) ||
          (cat == 'Entertainment' && (q.contains('netflix') || q.contains('spotify') || q.contains('movie'))) ||
          (cat == 'Utilities' && (q.contains('bill') || q.contains('electricity') || q.contains('water')))) {
        final catTxs = expenses.where((t) {
          final c = t.category.toLowerCase();
          final target = cat.toLowerCase();
          return c == target || (cat == 'Food' && c == 'groceries') || (cat == 'Groceries' && c == 'food');
        }).toList();

        final catTotal = catTxs.fold(0.0, (s, t) => s + t.amount);

        if (catTxs.isEmpty || catTotal == 0) {
          return "You haven't recorded any expenses in the **$cat** category yet! Your total for this category is $currency 0. 💳";
        }

        final recentList = catTxs.take(3).map((t) => "• ${t.title}: $currency${t.amount.toStringAsFixed(0)}").join('\n');
        return "You've spent a total of **$currency${catTotal.toStringAsFixed(0)}** on **$cat** across ${catTxs.length} transaction(s):\n\n$recentList\n\nManaging this category well is key to keeping your monthly budget on track! 📊";
      }
    }

    // 7. RECENT TRANSACTIONS / HISTORY
    if (q.contains('recent') || q.contains('history') || q.contains('latest') || q.contains('transactions')) {
      if (allTxs.isEmpty) {
        return "You have no transactions recorded yet. Tap '+ Add New' on the Home screen to add your first expense or income! 📝";
      }

      final recent = allTxs.take(4).map((t) {
        final sign = t.isExpense ? '-' : '+';
        final d = t.date.toLocal();
        return "• **${t.title}**: $sign $currency${t.amount.toStringAsFixed(0)} (${t.category} · ${d.day} ${_monthName(d.month)})";
      }).join('\n');

      return "Here are your latest transactions:\n\n$recent\n\nYou can review all transactions anytime in the Tracking tab! 🔍";
    }

    // 8. CAN I AFFORD / PURCHASE CHECK
    if (q.contains('can i afford') || q.contains('can i buy') || q.contains('should i buy')) {
      final numbers = RegExp(r'\d[\d,]*').allMatches(q);
      double? itemPrice;
      if (numbers.isNotEmpty) {
        itemPrice = double.tryParse(numbers.first.group(0)!.replaceAll(',', ''));
      }

      if (itemPrice != null && itemPrice > 0) {
        if (balance >= itemPrice * 2) {
          return "Yes! You have $currency${balance.toStringAsFixed(0)} available. Spending $currency${itemPrice.toStringAsFixed(0)} would leave you with $currency${(balance - itemPrice).toStringAsFixed(0)}, which still keeps a comfortable safety buffer! ✅";
        } else if (balance >= itemPrice) {
          return "You can afford it with your current balance of $currency${balance.toStringAsFixed(0)}, but spending $currency${itemPrice.toStringAsFixed(0)} leaves you with only $currency${(balance - itemPrice).toStringAsFixed(0)}. Consider waiting until your next income cycle to maintain an emergency cushion! ⚠️";
        } else {
          return "Currently, you don't have enough balance ($currency${balance.toStringAsFixed(0)}) to afford this $currency${itemPrice.toStringAsFixed(0)} purchase. Try creating a savings goal to accumulate the funds steadily! 🎯";
        }
      }

      return "To give you an exact affordability assessment, let me know the estimated cost! (e.g., 'Can I afford ₹15,000 for a new phone?'). With your current balance of $currency${balance.toStringAsFixed(0)}, I'll calculate your safety buffer. 💳";
    }

    // 9. 50/30/20 BUDGETING RULE
    if (q.contains('50/30/20') || q.contains('budget rule') || q.contains('how to budget')) {
      final income = TransactionService.totalIncome > 0 ? TransactionService.totalIncome : (balance > 0 ? balance : 50000.0);
      final needs = income * 0.50;
      final wants = income * 0.30;
      final savings = income * 0.20;

      return "Here is your personalized **50/30/20 budget framework** based on your tracked income ($currency${income.toStringAsFixed(0)}):\n\n"
          "• **50% Needs ($currency${needs.toStringAsFixed(0)})**: Essential housing, groceries, utilities, and transport.\n"
          "• **30% Wants ($currency${wants.toStringAsFixed(0)})**: Dining out, shopping, streaming subscriptions, entertainment.\n"
          "• **20% Savings & Debt ($currency${savings.toStringAsFixed(0)})**: Emergency fund, goals, and investments.\n\n"
          "Follow this formula to steadily increase your wealth each month! 💡";
    }

    // 10. TIPS TO SAVE MONEY / REDUCE SPENDING
    if (q.contains('save') || q.contains('cut') || q.contains('tips') || q.contains('reduce')) {
      final catTotals = TransactionService.categoryTotals();
      final sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCatName = sortedCats.isNotEmpty ? sortedCats.first.key : 'Food';
      final topCatAmt = sortedCats.isNotEmpty ? sortedCats.first.value : 0;

      return "Here are 3 tailored money-saving strategies for you:\n\n"
          "1. **Optimize $topCatName**: This is your highest spending area ($currency${topCatAmt.toStringAsFixed(0)}). Cutting just 15% here saves $currency${(topCatAmt * 0.15).toStringAsFixed(0)} this month!\n"
          "2. **Use the 48-Hour Rule**: Before making non-essential purchases over $currency 1,000, wait 48 hours to prevent impulse buys.\n"
          "3. **Automate Goal Contributions**: Allocate a set amount directly to your savings goals right after payday. 💰";
    }

    // 11. GENERAL / MONTHLY SPENDING
    if (q.contains('spending') || q.contains('expense') || q.contains('spent')) {
      final monthlyExp = TransactionService.monthlyExpense(now.year, now.month);
      final budgetText = budget > 0 ? ' against your budget of $currency${budget.toStringAsFixed(0)}' : '';
      return "Your total monthly spending is currently **$currency${monthlyExp.toStringAsFixed(0)}**$budgetText with an available balance of **$currency${balance.toStringAsFixed(0)}**. You're managing your finances well! 📊";
    }

    // 12. FALLBACK
    return "I'm here to help with your finances! Your current balance is **$currency${balance.toStringAsFixed(0)}** with **${expenses.length}** tracked expense(s).\n\n"
        "Try asking me:\n"
        "• 'How much did I spend today?'\n"
        "• 'What is my spending this week?'\n"
        "• 'How are my savings goals?'\n"
        "• 'What is my highest expense?'\n"
        "• 'Tips to save money' 🤖";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaTheme.background,
      appBar: AppBar(
        backgroundColor: PaisaTheme.background,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? Padding(
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
              )
            : null,
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
                  TextSpan(text: 'Chatbot'),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              PaisaTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Paisa bot is thinking...',
                          style: TextStyle(
                            fontSize: 12,
                            color: PaisaTheme.textGray,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Suggestion Chips Carousel
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return GestureDetector(
                  onTap: () => _handleSendMessage(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: Center(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PaisaTheme.textLightGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(
              color: PaisaTheme.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      onSubmitted: _handleSendMessage,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ask Paisa bot anything...',
                        hintStyle: TextStyle(
                          color: PaisaTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _handleSendMessage(_controller.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: PaisaTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
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

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                color: PaisaTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: PaisaTheme.primaryGreen,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? PaisaTheme.primaryGreen : PaisaTheme.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 22),
                ),
                border: isUser
                    ? null
                    : Border.all(color: PaisaTheme.surfaceBorder, width: 1),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                  color: isUser ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
