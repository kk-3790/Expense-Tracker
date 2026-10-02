import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import '../services/split_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import '../widgets/create_goal_modal.dart';
import 'add_transaction_screen.dart';
import 'ai_chat_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _goalScrollController = ScrollController();
  int _activeGoalIndex = 0;

  @override
  void initState() {
    super.initState();
    _goalScrollController.addListener(_onGoalScroll);
  }

  @override
  void dispose() {
    _goalScrollController.removeListener(_onGoalScroll);
    _goalScrollController.dispose();
    super.dispose();
  }

  void _onGoalScroll() {
    if (!_goalScrollController.hasClients) return;
    final offset = _goalScrollController.offset;
    const itemWidth = 187.0;
    int index = (offset / itemWidth).round();
    final maxIndex = (GoalService.goals.value.isEmpty ? 2 : GoalService.goals.value.length + 1) - 1;
    index = index.clamp(0, maxIndex < 0 ? 0 : maxIndex);
    if (index != _activeGoalIndex && mounted) {
      setState(() {
        _activeGoalIndex = index;
      });
    }
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(parts[i]);
    }
    return '${isNegative ? '- ₹ ' : '₹ '}${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, transactions, child) {
        final balance = TransactionService.balance;
        final now = DateTime.now();

        // Today's expense
        final todayExpense = transactions.where((t) {
          return t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).fold(0.0, (sum, t) => sum + t.amount);

        // Yesterday's expense for accurate trend
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayExpense = transactions.where((t) {
          return t.isExpense &&
              t.date.year == yesterday.year &&
              t.date.month == yesterday.month &&
              t.date.day == yesterday.day;
        }).fold(0.0, (sum, t) => sum + t.amount);

        // Weekly expense (last 7 days)
        final weeklyExpense = transactions.where((t) {
          final diff = now.difference(t.date).inDays;
          return t.isExpense && diff >= 0 && diff <= 7;
        }).fold(0.0, (sum, t) => sum + t.amount);

        // Previous week expense (days 8 to 14) for accurate trend
        final prevWeeklyExpense = transactions.where((t) {
          final diff = now.difference(t.date).inDays;
          return t.isExpense && diff > 7 && diff <= 14;
        }).fold(0.0, (sum, t) => sum + t.amount);

        final String todayPercentText;
        if (todayExpense <= 0) {
          todayPercentText = '0.0%';
        } else if (yesterdayExpense > 0) {
          final delta =
              ((todayExpense - yesterdayExpense) / yesterdayExpense) * 100;
          todayPercentText =
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';
        } else if (weeklyExpense > 0) {
          final share = (todayExpense / weeklyExpense) * 100;
          todayPercentText = '+${share.toStringAsFixed(1)}%';
        } else {
          todayPercentText = '0.0%';
        }

        final String weeklyPercentText;
        if (weeklyExpense <= 0) {
          weeklyPercentText = '0.0%';
        } else if (prevWeeklyExpense > 0) {
          final delta =
              ((weeklyExpense - prevWeeklyExpense) / prevWeeklyExpense) * 100;
          weeklyPercentText =
              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}%';
        } else if (balance.abs() > 0) {
          final share = (weeklyExpense / (balance.abs() + weeklyExpense)) * 100;
          weeklyPercentText = '+${share.toStringAsFixed(1)}%';
        } else {
          weeklyPercentText = '0.0%';
        }

        // Weekly income to determine savings rate trend
        final weeklyIncome = transactions.where((t) {
          final diff = now.difference(t.date).inDays;
          return t.isIncome && diff >= 0 && diff <= 7;
        }).fold(0.0, (sum, t) => sum + t.amount);

        final String balanceDeltaText;
        final bool isBalancePositive;
        if (weeklyIncome > 0) {
          final savingsRate =
              ((weeklyIncome - weeklyExpense) / weeklyIncome) * 100;
          balanceDeltaText =
              '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(1)}%';
          isBalancePositive = savingsRate >= 0;
        } else {
          balanceDeltaText = balance >= 0 ? '+ 0.0%' : '- 0.0%';
          isBalancePositive = balance >= 0;
        }

        final bool isTodayNegative = todayPercentText.startsWith('-');
        final Color todayBadgeColor =
            isTodayNegative ? PaisaTheme.danger : PaisaTheme.primaryGreen;

        final bool isWeeklyNegative = weeklyPercentText.startsWith('-');
        final Color weeklyBadgeColor =
            isWeeklyNegative ? PaisaTheme.danger : PaisaTheme.primaryGreen;

        final Color balanceBadgeColor =
            isBalancePositive ? PaisaTheme.primaryGreen : PaisaTheme.danger;

        return Scaffold(
          backgroundColor: PaisaTheme.background,
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                // ======================================================
                // TOP BAR: User Avatar + Notifications + Options
                // ======================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Avatar
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PaisaTheme.primaryGreen,
                            width: 1.8,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: PaisaTheme.surface,
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                    ),

                    // Right action icons
                    Row(
                      children: [
                        // Notification Bell with dynamic pending badge
                        ValueListenableBuilder<List<SplitRequest>>(
                          valueListenable: SplitService.splitRequests,
                          builder: (context, requests, _) {
                            final pendingIncoming = requests
                                .where((r) =>
                                    SplitService.isRequestIncoming(r) &&
                                    r.isPending)
                                .length;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: PaisaTheme.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: pendingIncoming > 0
                                        ? PaisaTheme.primaryGreen
                                        : PaisaTheme.surfaceBorder,
                                    width: pendingIncoming > 0 ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      pendingIncoming > 0
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_none_rounded,
                                      color: pendingIncoming > 0
                                          ? PaisaTheme.primaryGreen
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    if (pendingIncoming > 0)
                                      Positioned(
                                        top: 3,
                                        right: 3,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF4B4B),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$pendingIncoming',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                // In-App Alert Banner for incoming split bill requests
                ValueListenableBuilder<List<SplitRequest>>(
                  valueListenable: SplitService.splitRequests,
                  builder: (context, requests, _) {
                    final incoming = requests
                        .where((r) =>
                            SplitService.isRequestIncoming(r) && r.isPending)
                        .toList();
                    if (incoming.isEmpty) return const SizedBox.shrink();

                    final first = incoming.first;
                    final currency = SettingsService.currency.value;
                    return Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B281E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: PaisaTheme.primaryGreen.withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PaisaTheme.primaryGreen.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              color: PaisaTheme.primaryGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Split Request Received',
                                      style: TextStyle(
                                        color: PaisaTheme.primaryGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (incoming.length > 1) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF4B4B),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '+${incoming.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${first.senderName} requested $currency${first.splitAmount.toStringAsFixed(0)} for "${first.expenseTitle}"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PaisaTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Review',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ======================================================
                // TOTAL BALANCE SECTION (Behance layout)
                // ======================================================
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 13,
                      color: PaisaTheme.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Big Balance Row: Dynamic from TransactionService
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatCurrency(balance),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: balanceBadgeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBalancePositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: balanceBadgeColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            balanceDeltaText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: balanceBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Dual Expense Cards: Today's Expense & Weekly Expense
                Row(
                  children: [
                    // Today's Expense
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Expense",
                            style: TextStyle(
                              fontSize: 12,
                              color: PaisaTheme.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '- ${_formatCurrency(todayExpense)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: todayBadgeColor.withAlpha(35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  todayPercentText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: todayBadgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Weekly Expense
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Expense',
                            style: TextStyle(
                              fontSize: 12,
                              color: PaisaTheme.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '- ${_formatCurrency(weeklyExpense)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: weeklyBadgeColor.withAlpha(35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  weeklyPercentText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: weeklyBadgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ======================================================
                // ACTIONS ROW: [ + Add Expense & Income ]  [ [::] QR ]
                // ======================================================
                Row(
                  children: [
                    // Add Expense & Income (Primary Green Pill Button)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Add Expense & Income',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaisaTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // QR Scanner Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QrScannerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: PaisaTheme.card,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: PaisaTheme.surfaceBorder),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ======================================================
                // FEATURE CARDS CAROUSEL (AI Assistant & Goals)
                // ======================================================
                ValueListenableBuilder<List<GoalModel>>(
                  valueListenable: GoalService.goals,
                  builder: (context, goals, _) {
                    return SizedBox(
                      height: 160,
                      child: ListView(
                        controller: _goalScrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add/Create Goal Dash Button on Left
                          GestureDetector(
                            onTap: () => CreateGoalModal.show(context),
                            child: Container(
                              width: 48,
                              height: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: PaisaTheme.card.withAlpha(120),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: PaisaTheme.surfaceBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_rounded,
                                    color: PaisaTheme.textGray, size: 24),
                              ),
                            ),
                          ),

                          // Card 1: AI Assistant
                          _buildAiAssistantCard(context),

                          // Dynamic Goal Cards from Database
                          if (goals.isEmpty)
                            _buildEmptyGoalCard(context)
                          else
                            ...goals.map((goal) => _buildGoalCard(context, goal)),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Interactive Animated Dots Indicator
                ValueListenableBuilder<List<GoalModel>>(
                  valueListenable: GoalService.goals,
                  builder: (context, goals, _) {
                    final count =
                        (goals.isEmpty ? 2 : goals.length + 1).clamp(1, 6);
                    final safeActiveIndex =
                        _activeGoalIndex.clamp(0, count - 1);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(count, (idx) {
                        final isActive = idx == safeActiveIndex;
                        return GestureDetector(
                          onTap: () {
                            if (_goalScrollController.hasClients) {
                              const itemWidth = 187.0;
                              final target = (idx * itemWidth).clamp(
                                0.0,
                                _goalScrollController
                                    .position.maxScrollExtent,
                              );
                              _goalScrollController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            width: isActive ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? PaisaTheme.primaryGreen
                                  : PaisaTheme.surfaceBorder,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ======================================================
                // RECENT TRANSACTIONS (Behance Brand Tiles)
                // ======================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '+ Add New',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PaisaTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Transactions list
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'No transactions recorded yet',
                        style: TextStyle(
                          color: PaisaTheme.textGray,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...transactions.take(8).map((tx) {
                    final isSpotify = tx.title.toLowerCase().contains('spotify');
                    final isAmazon = tx.title.toLowerCase().contains('amazon');
                    final isExpense = tx.isExpense;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionDetailScreen(transaction: tx),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: PaisaTheme.card,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: PaisaTheme.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              // Brand/Category Tile
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSpotify
                                      ? const Color(0xFF1DB954)
                                      : isAmazon
                                          ? Colors.white
                                          : PaisaTheme.getCategoryColor(
                                                  tx.category)
                                              .withAlpha(45),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: isSpotify
                                      ? const Icon(Icons.music_note_rounded,
                                          color: Colors.black, size: 24)
                                      : isAmazon
                                          ? const Text(
                                              'a',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'serif',
                                              ),
                                            )
                                          : Icon(
                                              PaisaTheme.getCategoryIcon(
                                                  tx.category),
                                              color:
                                                  PaisaTheme.getCategoryColor(
                                                      tx.category),
                                              size: 22,
                                            ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Title & Timestamp
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title.isNotEmpty
                                          ? tx.title
                                          : tx.category,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          '${tx.date.day} ${_monthShort(tx.date.month)} · ${_timeString(tx.date)}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: PaisaTheme.textGray,
                                          ),
                                        ),
                                        if (tx.isSplitTransaction) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: PaisaTheme.primaryGreen.withAlpha(25),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: PaisaTheme.primaryGreen.withAlpha(60),
                                                  width: 0.8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.call_split_rounded,
                                                    size: 9,
                                                    color: PaisaTheme.primaryGreen),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Split (${tx.displayPeopleCount})',
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: PaisaTheme.primaryGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Amount
                              Text(
                                isExpense
                                    ? '- ₹ ${tx.amount.toStringAsFixed(0)}'
                                    : '+ ₹ ${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isExpense
                                      ? Colors.white
                                      : PaisaTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (transactions.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: PaisaTheme.primaryGreen,
                        ),
                        label: Text(
                          'View All (${transactions.length}) Transactions',
                          style: const TextStyle(
                            color: PaisaTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiAssistantCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatScreen(),
          ),
        );
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: PaisaTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PaisaTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'AI ',
                        style: TextStyle(color: PaisaTheme.primaryGreen),
                      ),
                      TextSpan(text: 'Assistant'),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: PaisaTheme.textGray,
                ),
              ],
            ),
            const Text(
              'Get free personal finance assistant from AI powered chat bot.',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: PaisaTheme.textGray,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Start new\nchat with '),
                      TextSpan(
                        text: 'AI',
                        style: TextStyle(color: PaisaTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalCard(BuildContext context) {
    return GestureDetector(
      onTap: () => CreateGoalModal.show(context),
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: PaisaTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PaisaTheme.surfaceBorder),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_rounded, color: PaisaTheme.primaryGreen, size: 30),
            SizedBox(height: 8),
            Text(
              'No Goals Yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap + to create your first savings goal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: PaisaTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal) {
    return GestureDetector(
      onTap: () => _showGoalDetailsModal(context, goal),
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: PaisaTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PaisaTheme.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.category.isNotEmpty ? goal.category : 'Goal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PaisaTheme.textLightGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: PaisaTheme.textGray,
                ),
              ],
            ),

            // Circular Progress Ring
            Center(
              child: SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: goal.progressPercentage,
                      strokeWidth: 4,
                      backgroundColor: PaisaTheme.surfaceBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        PaisaTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '${goal.percentageInt}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Goal Title and Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.targetDate.day} ${_monthShort(goal.targetDate.month).substring(0, 3)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PaisaTheme.textGray,
                      ),
                    ),
                    Text(
                      '₹${_formatCompactNumber(goal.currentAmount)}/₹${_formatCompactNumber(goal.targetAmount)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: PaisaTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetailsModal(BuildContext context, GoalModel goal) {
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PaisaTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final currentList = GoalService.goals.value;
            final liveGoal = currentList.firstWhere(
              (g) => g.id == goal.id,
              orElse: () => goal,
            );
            final remaining = (liveGoal.targetAmount - liveGoal.currentAmount)
                .clamp(0.0, double.infinity);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 16, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PaisaTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PaisaTheme.primaryGreen.withAlpha(35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                PaisaTheme.getCategoryIcon(liveGoal.category),
                                color: PaisaTheme.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  liveGoal.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${liveGoal.category} · Target: ${liveGoal.targetDate.day} ${_monthShort(liveGoal.targetDate.month)} ${liveGoal.targetDate.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PaisaTheme.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 22),
                          tooltip: 'Delete Goal',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: PaisaTheme.card,
                                title: const Text('Delete Goal',
                                    style: TextStyle(color: Colors.white)),
                                content: Text(
                                    'Are you sure you want to delete "${liveGoal.name}"?',
                                    style: const TextStyle(
                                        color: PaisaTheme.textGray)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            color: PaisaTheme.textGray)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await GoalService.deleteGoal(liveGoal.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: PaisaTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹ ${liveGoal.currentAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: PaisaTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                'of ₹ ${liveGoal.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: PaisaTheme.textGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: liveGoal.progressPercentage,
                              minHeight: 8,
                              backgroundColor: PaisaTheme.card,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  PaisaTheme.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${liveGoal.percentageInt}% completed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: PaisaTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                remaining > 0
                                    ? '₹ ${remaining.toStringAsFixed(0)} left to save'
                                    : 'Goal Achieved! 🎉',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: remaining > 0
                                      ? PaisaTheme.textGray
                                      : PaisaTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Quick Contribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [500, 1000, 2000, 5000].map((quickAmt) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () async {
                                await GoalService.updateGoalProgress(
                                    liveGoal.id, quickAmt.toDouble());
                                setModalState(() {});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Added ₹$quickAmt to "${liveGoal.name}"!'),
                                      backgroundColor: PaisaTheme.primaryGreen,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: PaisaTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: PaisaTheme.surfaceBorder),
                                ),
                                child: Center(
                                  child: Text(
                                    '+₹$quickAmt',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: PaisaTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter custom amount (₹)',
                        hintStyle:
                            const TextStyle(color: PaisaTheme.textMuted),
                        filled: true,
                        fillColor: PaisaTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded,
                              color: PaisaTheme.primaryGreen),
                          onPressed: () async {
                            final val =
                                double.tryParse(amountCtrl.text.trim()) ?? 0;
                            if (val > 0) {
                              await GoalService.updateGoalProgress(
                                  liveGoal.id, val);
                              amountCtrl.clear();
                              setModalState(() {});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Added ₹$val to "${liveGoal.name}"!'),
                                    backgroundColor: PaisaTheme.primaryGreen,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCompactNumber(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  String _monthShort(int month) {
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
      'December'
    ];
    return months[month - 1];
  }

  String _timeString(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$hour:$min $ampm';
  }
}