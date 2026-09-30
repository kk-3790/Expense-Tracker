import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import '../services/split_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionModel _tx;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$weekday, ${dt.day} $month ${dt.year} · $hour:$minute $period';
  }

  void _editTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: _tx),
      ),
    );

    if (result == true && mounted) {
      final updated = TransactionService.transactions.value.firstWhere(
        (t) => t.id == _tx.id,
        orElse: () => _tx,
      );
      setState(() {
        _tx = updated;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaisaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${_tx.title}"? This cannot be undone.',
          style: const TextStyle(color: PaisaTheme.textGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PaisaTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await TransactionService.delete(_tx.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    backgroundColor: Color(0xFFFF4B4B),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnits.reduce((a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionService.transactions,
      builder: (context, allTx, _) {
        final currentTx = allTx.firstWhere((t) => t.id == _tx.id, orElse: () => _tx);
        final isSplit = currentTx.isSplitTransaction;
        final totalAmount = currentTx.displayTotalAmount;
        final yourShare = currentTx.displayYourShare;
        final peopleCount = currentTx.displayPeopleCount;
        final isExpense = currentTx.isExpense;

        return Scaffold(
          backgroundColor: PaisaTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
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
                      const SizedBox(width: 14),
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      // Edit Button
                      IconButton(
                        onPressed: _editTransaction,
                        icon: const Icon(Icons.edit_outlined, color: PaisaTheme.primaryGreen),
                        tooltip: 'Edit Transaction',
                      ),
                      // Delete Button
                      IconButton(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4B4B)),
                        tooltip: 'Delete Transaction',
                      ),
                    ],
                  ),
                ),

                // Content Scroll View
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Amount & Category Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: PaisaTheme.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: PaisaTheme.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Category Circular Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: PaisaTheme.getCategoryColor(currentTx.category)
                                      .withAlpha(45),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PaisaTheme.getCategoryIcon(currentTx.category),
                                  color: PaisaTheme.getCategoryColor(currentTx.category),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Title
                              Text(
                                currentTx.title.isNotEmpty
                                    ? currentTx.title
                                    : currentTx.category,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Amount Display
                              Text(
                                isExpense
                                    ? '- ₹ ${currentTx.amount.toStringAsFixed(0)}'
                                    : '+ ₹ ${currentTx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isExpense
                                      ? Colors.white
                                      : PaisaTheme.primaryGreen,
                                ),
                              ),

                              if (isSplit && totalAmount != currentTx.amount) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Your Share (Total bill: ₹${totalAmount.toStringAsFixed(0)})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PaisaTheme.primaryGreen,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Badges: Category & Payment Method
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _badgePill(
                                    icon: Icons.label_outline_rounded,
                                    label: currentTx.category,
                                    color: PaisaTheme.getCategoryColor(currentTx.category),
                                  ),
                                  _badgePill(
                                    icon: Icons.payment_rounded,
                                    label: currentTx.paymentMethod,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                  if (isSplit)
                                    _badgePill(
                                      icon: Icons.call_split_rounded,
                                      label: 'Split ($peopleCount People)',
                                      color: PaisaTheme.primaryGreen,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(color: PaisaTheme.surfaceBorder),
                              const SizedBox(height: 12),

                              // Date & Time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 15,
                                    color: PaisaTheme.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(currentTx.date),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: PaisaTheme.textGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Split Breakdown Section (if split)
                        if (isSplit)
                          _buildSplitSection(currentTx, totalAmount, yourShare, peopleCount)
                        else
                          _buildUnsplitSplitPromo(currentTx),

                        const SizedBox(height: 20),

                        // Additional Notes & Reference
                        _buildNotesSection(currentTx),

                        const SizedBox(height: 24),

                        // Bottom Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _editTransaction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: PaisaTheme.primaryGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_rounded, color: Colors.black, size: 18),
                                  label: const Text(
                                    'Edit Transaction',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _badgePill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitSection(
    TransactionModel tx,
    double totalAmount,
    double yourShare,
    int peopleCount,
  ) {
    return ValueListenableBuilder<List<SplitRequest>>(
      valueListenable: SplitService.splitRequests,
      builder: (context, requests, child) {
        final matchingRequests = SplitService.getRequestsForTransaction(tx);
        final friendsList = tx.splitFriendsList;
        final perPersonShare = totalAmount / (peopleCount > 0 ? peopleCount : 1);

        // Count approved/settled
        int approvedCount = 0;
        for (final req in matchingRequests) {
          if (req.isApproved) approvedCount++;
        }
        final totalFriends = friendsList.isNotEmpty
            ? friendsList.length
            : (peopleCount > 1 ? peopleCount - 1 : 1);
        final progress = totalFriends > 0 ? (approvedCount / totalFriends).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PaisaTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PaisaTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PaisaTheme.primaryGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          size: 18,
                          color: PaisaTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Split Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PaisaTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$peopleCount People',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: PaisaTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Total & Share Summary Stats Row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PaisaTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Bill',
                            style: TextStyle(fontSize: 11, color: PaisaTheme.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹ ${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: PaisaTheme.surfaceBorder),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share Each',
                            style: TextStyle(fontSize: 11, color: PaisaTheme.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹ ${perPersonShare.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: PaisaTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settlement Progress ($approvedCount / $totalFriends Paid)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PaisaTheme.textGray,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PaisaTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: PaisaTheme.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(PaisaTheme.primaryGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                'Participants',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PaisaTheme.textLightGray,
                ),
              ),
              const SizedBox(height: 10),

              // 1. Organizer (You)
              _buildParticipantTile(
                name: 'You (Organizer)',
                subtext: 'Paid full bill · Self Share',
                shareAmount: yourShare,
                avatarText: 'Y',
                avatarColor: PaisaTheme.primaryGreen,
                status: 'Paid',
                statusColor: PaisaTheme.primaryGreen,
                showActions: false,
                txTitle: tx.title,
              ),

              // 2. Friends
              if (friendsList.isNotEmpty)
                ...friendsList.map((friendName) {
                  final req = matchingRequests.firstWhere(
                    (r) =>
                        r.recipientName.toLowerCase() == friendName.toLowerCase() ||
                        r.recipientName.toLowerCase().contains(friendName.toLowerCase()) ||
                        friendName.toLowerCase().contains(r.recipientName.toLowerCase()),
                    orElse: () => SplitRequest(
                      id: '',
                      senderName: 'You',
                      senderEmail: '',
                      recipientName: friendName,
                      recipientEmail: '${friendName.toLowerCase().replaceAll(' ', '')}@paisa.app',
                      expenseTitle: tx.title,
                      totalAmount: totalAmount,
                      splitAmount: perPersonShare,
                      createdAt: tx.date,
                    ),
                  );

                  String statusText = 'Pending Approval';
                  Color statusColor = const Color(0xFFF59E0B);
                  if (req.isApproved) {
                    statusText = 'Paid & Settled';
                    statusColor = PaisaTheme.primaryGreen;
                  } else if (req.isRejected) {
                    statusText = 'Declined';
                    statusColor = const Color(0xFFFF4B4B);
                  }

                  return _buildParticipantTile(
                    name: friendName,
                    subtext: req.recipientEmail.isNotEmpty ? req.recipientEmail : 'Registered Friend',
                    shareAmount: req.splitAmount > 0 ? req.splitAmount : perPersonShare,
                    avatarText: friendName.isNotEmpty ? friendName[0].toUpperCase() : 'F',
                    avatarColor: _avatarColor(friendName),
                    status: statusText,
                    statusColor: statusColor,
                    showActions: !req.isApproved,
                    txTitle: tx.title,
                  );
                })
              else if (matchingRequests.isNotEmpty)
                ...matchingRequests.map((req) {
                  String statusText = 'Pending Approval';
                  Color statusColor = const Color(0xFFF59E0B);
                  if (req.isApproved) {
                    statusText = 'Paid & Settled';
                    statusColor = PaisaTheme.primaryGreen;
                  } else if (req.isRejected) {
                    statusText = 'Declined';
                    statusColor = const Color(0xFFFF4B4B);
                  }

                  return _buildParticipantTile(
                    name: req.recipientName,
                    subtext: req.recipientEmail,
                    shareAmount: req.splitAmount,
                    avatarText: req.recipientName.isNotEmpty
                        ? req.recipientName[0].toUpperCase()
                        : 'F',
                    avatarColor: _avatarColor(req.recipientName),
                    status: statusText,
                    statusColor: statusColor,
                    showActions: !req.isApproved,
                    txTitle: tx.title,
                  );
                })
              else
                ...List.generate(peopleCount - 1, (i) {
                  final name = 'Friend ${i + 1}';
                  return _buildParticipantTile(
                    name: name,
                    subtext: 'Equal share',
                    shareAmount: perPersonShare,
                    avatarText: '${i + 1}',
                    avatarColor: _avatarColor(name),
                    status: 'Pending',
                    statusColor: const Color(0xFFF59E0B),
                    showActions: true,
                    txTitle: tx.title,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantTile({
    required String name,
    required String subtext,
    required double shareAmount,
    required String avatarText,
    required Color avatarColor,
    required String status,
    required Color statusColor,
    required bool showActions,
    required String txTitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaisaTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaisaTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarColor,
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtext,
                      style: const TextStyle(
                        fontSize: 11,
                        color: PaisaTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹ ${shareAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (showActions) ...[
            const SizedBox(height: 10),
            const Divider(color: PaisaTheme.surfaceBorder, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Send Reminder Action
                GestureDetector(
                  onTap: () {
                    final reminderMsg =
                        'Hey $name! Reminder for your ₹${shareAmount.toStringAsFixed(0)} share for "$txTitle" on Paisa app. Pay via UPI: krishpatel@paisa';
                    Clipboard.setData(ClipboardData(text: reminderMsg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminder message copied for $name!'),
                        backgroundColor: PaisaTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            size: 13, color: PaisaTheme.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Send Reminder',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PaisaTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Copy UPI Link
                GestureDetector(
                  onTap: () {
                    final upiLink = SplitService.generateSplitUpiLink(
                      payeeUpiId: 'krishpatel@paisa',
                      payeeName: 'Krish Patel',
                      amount: shareAmount,
                      note: 'Split bill share for $txTitle',
                    );
                    Clipboard.setData(ClipboardData(text: upiLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('UPI payment link copied for $name!'),
                        backgroundColor: PaisaTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: PaisaTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PaisaTheme.surfaceBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded,
                            size: 13, color: Color(0xFF60A5FA)),
                        SizedBox(width: 4),
                        Text(
                          'Copy UPI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ],
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

  Widget _buildUnsplitSplitPromo(TransactionModel tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaisaTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PaisaTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PaisaTheme.primaryGreen.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.call_split_rounded,
              size: 22,
              color: PaisaTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Want to split this bill?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share cost with friends and track repayments in real time.',
                  style: TextStyle(fontSize: 11.5, color: PaisaTheme.textGray),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _editTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: PaisaTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Split',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(TransactionModel tx) {
    final cleanNote = tx.cleanNote;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaisaTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PaisaTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, size: 16, color: PaisaTheme.textLightGray),
              SizedBox(width: 8),
              Text(
                'Note & Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            cleanNote.isNotEmpty ? cleanNote : 'No extra notes provided for this transaction.',
            style: TextStyle(
              fontSize: 13,
              color: cleanNote.isNotEmpty ? Colors.white70 : PaisaTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: PaisaTheme.surfaceBorder),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction ID',
                style: TextStyle(fontSize: 11, color: PaisaTheme.textMuted),
              ),
              Text(
                '#${tx.id.length > 16 ? tx.id.substring(0, 16) : tx.id}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: PaisaTheme.textLightGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
