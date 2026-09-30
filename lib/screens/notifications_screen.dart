import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import '../services/split_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Split', 'Goals', 'Budget'

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PaisaTheme.surfaceBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Smart Alert Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Customize automated alerts and notifications in Paisa:',
                      style: TextStyle(fontSize: 12, color: PaisaTheme.textGray),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Goal Near Reach Alert',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Alert when goal reaches 75% or 100% target',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.goalAlertsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setGoalAlertsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const Divider(color: PaisaTheme.surfaceBorder, height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Category Budget Limit Alert',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Alert when category spending approaches or reaches limit',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.categoryBudgetAlertsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setCategoryBudgetAlertsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const Divider(color: PaisaTheme.surfaceBorder, height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'General financial reminders and split updates',
                        style: TextStyle(color: PaisaTheme.textGray, fontSize: 12),
                      ),
                      activeThumbColor: PaisaTheme.primaryGreen,
                      value: SettingsService.notificationsEnabled.value,
                      onChanged: (v) async {
                        await SettingsService.setNotificationsEnabled(v);
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PaisaTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Save Preferences',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _approveSplit(SplitRequest req) async {
    final success = await SplitService.approveRequest(req.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Split approved! ₹${req.splitAmount.toStringAsFixed(0)} debited from your account to ${req.senderName}.',
          ),
          backgroundColor: PaisaTheme.primaryGreen,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _rejectSplit(SplitRequest req) async {
    final success = await SplitService.rejectRequest(req.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Split request from ${req.senderName} rejected.'),
          backgroundColor: const Color(0xFFFF4B4B),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _simulateFriendApprove(SplitRequest req) async {
    final success = await SplitService.simulateFriendApproval(req.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${req.recipientName} approved! ₹${req.splitAmount.toStringAsFixed(0)} transferred to your account.',
          ),
          backgroundColor: PaisaTheme.primaryGreen,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _simulateFriendReject(SplitRequest req) async {
    final success = await SplitService.simulateFriendRejection(req.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${req.recipientName} declined the split request.'),
          backgroundColor: const Color(0xFFFF4B4B),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = SettingsService.currency.value;

    return ValueListenableBuilder<List<SplitRequest>>(
      valueListenable: SplitService.splitRequests,
      builder: (context, splitRequests, _) {
        return ValueListenableBuilder<List<GoalModel>>(
          valueListenable: GoalService.goals,
          builder: (context, goals, _) {
            // Compute dynamic goal notifications
            final goalNotifications = <Map<String, dynamic>>[];
            if (SettingsService.goalAlertsEnabled.value) {
              for (final goal in goals) {
                if (goal.progressPercentage >= 1.0) {
                  goalNotifications.add({
                    'tag': 'Goal Completed 🎉',
                    'color': PaisaTheme.primaryGreen,
                    'title': '100% Target Reached!',
                    'message':
                        'Congratulations! You reached 100% of your "${goal.name}" goal ($currency${goal.currentAmount.toStringAsFixed(0)} saved).',
                    'time': 'Just now',
                    'type': 'goal',
                  });
                } else if (goal.progressPercentage >= 0.75) {
                  goalNotifications.add({
                    'tag': 'Goal Near Reach 🎯',
                    'color': const Color(0xFFFFD166),
                    'title': '${(goal.progressPercentage * 100).toInt()}% of "${goal.name}"',
                    'message':
                        'You are almost at the finish line! Only $currency${goal.remainingAmount.toStringAsFixed(0)} left to complete this goal.',
                    'time': 'Active',
                    'type': 'goal',
                  });
                }
              }
            }

            // Compute dynamic category budget notifications
            final budgetNotifications = <Map<String, dynamic>>[];
            if (SettingsService.categoryBudgetAlertsEnabled.value) {
              final catTotals = TransactionService.categoryTotals();
              final sortedCats = catTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              for (final entry in sortedCats.take(2)) {
                if (entry.value > 1000) {
                  budgetNotifications.add({
                    'tag': 'Category Budget Alert ⚠️',
                    'color': const Color(0xFFFF9F1C),
                    'title': '${entry.key} Budget Limit',
                    'message':
                        'You have spent $currency${entry.value.toStringAsFixed(0)} on ${entry.key}. Spending is nearing monthly recommended limit.',
                    'time': 'Recent',
                    'type': 'budget',
                  });
                }
              }
            }

            // Filter logic
            final showSplit = _selectedFilter == 'All' || _selectedFilter == 'Split';
            final showGoals = _selectedFilter == 'All' || _selectedFilter == 'Goals';
            final showBudget = _selectedFilter == 'All' || _selectedFilter == 'Budget';

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
                title: const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    tooltip: 'Alert Preferences',
                    onPressed: _showNotificationSettings,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: Column(
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Split', count: splitRequests.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Goals', count: goalNotifications.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Budget', count: budgetNotifications.length),
                      ],
                    ),
                  ),

                  // Notifications List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      children: [
                        // 1. Split Requests
                        if (showSplit && splitRequests.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.call_split_rounded,
                                    size: 16, color: PaisaTheme.primaryGreen),
                                SizedBox(width: 6),
                                Text(
                                  'In-App Split Requests',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...splitRequests.map((req) => _buildSplitCard(req, currency)),
                          const SizedBox(height: 12),
                        ],

                        // 2. Goal Near Reach Notifications
                        if (showGoals && goalNotifications.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded,
                                    size: 16, color: Color(0xFFFFD166)),
                                SizedBox(width: 6),
                                Text(
                                  'Goal Alerts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...goalNotifications.map((g) => _buildAlertCard(g)),
                          const SizedBox(height: 12),
                        ],

                        // 3. Category Budget Alerts
                        if (showBudget && budgetNotifications.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.pie_chart_outline_rounded,
                                    size: 16, color: Color(0xFFFF9F1C)),
                                SizedBox(width: 6),
                                Text(
                                  'Category Budget Alerts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...budgetNotifications.map((b) => _buildAlertCard(b)),
                          const SizedBox(height: 12),
                        ],

                        // 4. Default System notifications if filter is All
                        if (_selectedFilter == 'All') ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.notifications_active_rounded,
                                    size: 16, color: PaisaTheme.primaryGreen),
                                SizedBox(width: 6),
                                Text(
                                  'System Reminders',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStaticCard(
                            tag: 'Expense Reminder',
                            time: '5h ago',
                            message:
                                'Don’t forget to log your recent grocery purchase to stay on top of your monthly budget.',
                          ),
                          const SizedBox(height: 12),
                          _buildStaticCard(
                            tag: 'Monthly Report',
                            time: '1d ago',
                            message:
                                'Your spending report is ready! You saved 14% more compared to last month.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, {int? count}) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? PaisaTheme.primaryGreen : PaisaTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? PaisaTheme.primaryGreen : PaisaTheme.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black.withOpacity(0.15) : PaisaTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : PaisaTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitCard(SplitRequest req, String currency) {
    final isIncoming = SplitService.isRequestIncoming(req);
    final avatarLetter = isIncoming
        ? (req.senderName.isNotEmpty ? req.senderName[0].toUpperCase() : 'S')
        : (req.recipientName.isNotEmpty ? req.recipientName[0].toUpperCase() : 'R');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaisaTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: req.isPending
              ? PaisaTheme.primaryGreen.withOpacity(0.4)
              : PaisaTheme.surfaceBorder,
          width: req.isPending ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tag + Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncoming
                      ? PaisaTheme.primaryGreen
                      : const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isIncoming ? 'Split Request Received' : 'Split Request Sent',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 12),

          // Detail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PaisaTheme.surface,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PaisaTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.expenseTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isIncoming
                          ? '${req.senderName} (${req.senderEmail}) requested your share ($currency${req.splitAmount.toStringAsFixed(0)} of $currency${req.totalAmount.toStringAsFixed(0)})'
                          : 'Requested $currency${req.splitAmount.toStringAsFixed(0)} from ${req.recipientName} (${req.recipientEmail})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaisaTheme.textLightGray,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 12, color: PaisaTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          isIncoming ? 'Verified Sender' : 'Verified Paisa Recipient',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PaisaTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency${req.splitAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: PaisaTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Share',
                    style: TextStyle(fontSize: 10, color: PaisaTheme.textGray),
                  ),
                ],
              ),
            ],
          ),

          // Action buttons for Incoming Pending Request
          if (isIncoming && req.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveSplit(req),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('Approve & Pay $currency${req.splitAmount.toStringAsFixed(0)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PaisaTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _rejectSplit(req),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF4B4B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFFFF4B4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Simulation buttons for Outgoing Request so the user can test the flow
          if (!isIncoming && req.isPending) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PaisaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for ${req.recipientName} to approve. Simulate action:',
                    style: const TextStyle(fontSize: 11, color: PaisaTheme.textGray),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _simulateFriendApprove(req),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: PaisaTheme.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Simulate Friend Approve',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PaisaTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _simulateFriendReject(req),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF4B4B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Simulate Reject',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF4B4B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Resolution message if already resolved
          if (req.isApproved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: PaisaTheme.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isIncoming
                        ? '$currency${req.splitAmount.toStringAsFixed(0)} debited from your account to ${req.senderName}.'
                        : '${req.recipientName} approved! $currency${req.splitAmount.toStringAsFixed(0)} transferred to your account.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PaisaTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (req.isRejected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.cancel_rounded,
                    size: 14, color: Color(0xFFFF4B4B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isIncoming
                        ? 'You rejected this split request.'
                        : '${req.recipientName} declined this split request.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF4B4B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SplitStatus status) {
    switch (status) {
      case SplitStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.4)),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD166),
            ),
          ),
        );
      case SplitStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: PaisaTheme.primaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PaisaTheme.primaryGreen.withOpacity(0.4)),
          ),
          child: const Text(
            'Approved',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PaisaTheme.primaryGreen,
            ),
          ),
        );
      case SplitStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4B4B).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF4B4B).withOpacity(0.4)),
          ),
          child: const Text(
            'Rejected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF4B4B),
            ),
          ),
        );
    }
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final tag = alert['tag'] as String;
    final color = alert['color'] as Color;
    final title = alert['title'] as String;
    final message = alert['message'] as String;
    final time = alert['time'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaisaTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: PaisaTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: PaisaTheme.textLightGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCard({
    required String tag,
    required String time,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaisaTheme.card,
        borderRadius: BorderRadius.circular(24),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: PaisaTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: PaisaTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: PaisaTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
