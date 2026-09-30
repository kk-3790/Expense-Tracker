import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import '../services/qr_scanner_service.dart';
import '../services/split_service.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';
import 'qr_scanner_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  final String? initialNote;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialNote,
  });

  bool get isEditing => transaction != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _amountStr = '';
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  bool _splitExpense = false;
  int _splitPeopleCount = 3;
  bool _recordOnlyUserShare = true;
  List<PaisaUser> _selectedRegisteredUsers = [];
  bool _showOtherDetails = false;
  DateTime _selectedDate = DateTime.now();

  String _selectedPaymentMethod = 'UPI';
  bool _sendInAppSplitRequest = true;

  int get _effectivePeopleCount => _selectedRegisteredUsers.isEmpty
      ? _splitPeopleCount
      : (1 + _selectedRegisteredUsers.length);

  List<String> get _currentFriendNames => _selectedRegisteredUsers.isNotEmpty
      ? _selectedRegisteredUsers.map((u) => u.name).toList()
      : ['Alex Rivera', 'Priya Sharma'];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<String> _expenseCategories = [
    'Food',
    'Transportation',
    'Housing',
    'Utilities',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Bonus',
    'Rental',
    'Other',
  ];

  List<String> get _currentCategories =>
      _isExpense ? _expenseCategories : _incomeCategories;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _isExpense = tx.isExpense;
      _selectedCategory = tx.category;
      _selectedDate = tx.date;
      _selectedPaymentMethod = tx.paymentMethod;
      _titleController.text = tx.title;
      _noteController.text = tx.cleanNote;
      _splitExpense = tx.isSplitTransaction;

      if (_splitExpense) {
        _amountStr = tx.displayTotalAmount.abs().toStringAsFixed(0);
        _splitPeopleCount = tx.displayPeopleCount;
        _recordOnlyUserShare = (tx.amount != tx.displayTotalAmount);

        final friends = tx.splitFriendsList;
        if (friends.isNotEmpty) {
          final registered = SplitService.registeredUsers.value;
          _selectedRegisteredUsers = friends.map((name) {
            return registered.firstWhere(
              (u) => u.name.toLowerCase() == name.toLowerCase(),
              orElse: () => PaisaUser(
                id: 'usr_${name.toLowerCase().replaceAll(' ', '_')}',
                name: name,
                email: '${name.toLowerCase().replaceAll(' ', '')}@paisa.app',
                phone: '',
                upiId: '${name.toLowerCase().replaceAll(' ', '')}@paisa',
                isRegistered: true,
              ),
            );
          }).toList();
        } else if (SplitService.registeredUsers.value.isNotEmpty) {
          _selectedRegisteredUsers = [
            SplitService.registeredUsers.value[0],
            if (SplitService.registeredUsers.value.length > 1)
              SplitService.registeredUsers.value[1],
          ];
        }
      } else {
        _amountStr = tx.amount.abs().toStringAsFixed(0);
        _selectedRegisteredUsers = [];
      }
    } else {
      _splitExpense = false;
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialAmount != null) {
        _amountStr = widget.initialAmount!.toStringAsFixed(0);
      }
      if (widget.initialCategory != null &&
          (_expenseCategories.contains(widget.initialCategory) ||
              _incomeCategories.contains(widget.initialCategory))) {
        _selectedCategory = widget.initialCategory!;
      } else {
        _selectedCategory = _isExpense ? 'Food' : 'Salary';
      }
      if (widget.initialNote != null) {
        _noteController.text = widget.initialNote!;
      }

      // Pre-populate default friends list in memory for when split toggle is turned on
      if (SplitService.registeredUsers.value.isNotEmpty) {
        _selectedRegisteredUsers = [
          SplitService.registeredUsers.value[0],
          if (SplitService.registeredUsers.value.length > 1)
            SplitService.registeredUsers.value[1],
        ];
        _splitPeopleCount = 1 + _selectedRegisteredUsers.length;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String val) {
    setState(() {
      if (val == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (val == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else if (val == '+*#') {
        // Toggle decimal
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0' || _amountStr.isEmpty) {
          _amountStr = val;
        } else {
          _amountStr += val;
        }
      }
    });
  }

  void _saveTransaction() async {
    final amount = double.tryParse(_amountStr.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    double effectiveAmount = amount;
    String effectiveNote = _noteController.text.trim();
    final peopleCount = _effectivePeopleCount;
    final friendNames = _currentFriendNames;

    final txId = widget.transaction?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();
    List<SplitRequest> createdSplitRequests = [];

    if (_splitExpense && _isExpense && amount > 0) {
      final split = SplitService.calculateEqualSplit(
        totalAmount: amount,
        peopleCount: peopleCount,
        friendNames: friendNames,
      );
      if (_recordOnlyUserShare) {
        effectiveAmount = split.yourShare;
      }
      effectiveNote = SplitService.formatSplitNote(
        totalAmount: amount,
        peopleCount: peopleCount,
        yourShare: split.yourShare,
        members: split.members,
        originalNote: _noteController.text.trim(),
      );

      if (_sendInAppSplitRequest) {
        final recipients = _selectedRegisteredUsers.isNotEmpty
            ? _selectedRegisteredUsers
            : [SplitService.registeredUsers.value.first];

        final authUser = FirebaseAuth.instance.currentUser;
        final senderName = (authUser?.displayName != null && authUser!.displayName!.isNotEmpty)
            ? authUser.displayName!
            : (authUser?.email != null && authUser!.email!.isNotEmpty
                ? authUser.email!.split('@').first
                : 'You');
        final senderEmail = (authUser?.email != null && authUser!.email!.isNotEmpty)
            ? authUser.email!
            : 'krishpatel@paisa.app';

        createdSplitRequests = await SplitService.createSplitRequestsForMultiple(
          senderName: senderName,
          senderEmail: senderEmail,
          senderId: authUser?.uid ?? 'guest',
          transactionId: txId,
          recipients: recipients,
          expenseTitle: _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : _selectedCategory,
          totalAmount: amount,
          splitAmountPerPerson: split.sharePerPerson,
        );
      }
    }

    final tx = TransactionModel(
      id: txId,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _selectedCategory,
      note: effectiveNote,
      date: _selectedDate,
      amount: effectiveAmount,
      category: _selectedCategory,
      type: _isExpense ? 'Expense' : 'Income',
      paymentMethod: _selectedPaymentMethod,
      isSplit: _splitExpense && _isExpense,
      splitTotalAmount: (_splitExpense && _isExpense) ? amount : null,
      splitShare: (_splitExpense && _isExpense) ? effectiveAmount : null,
      splitPeopleCount: (_splitExpense && _isExpense) ? peopleCount : null,
      splitWith: (_splitExpense && _isExpense) ? friendNames : null,
      splitRequestIds: createdSplitRequests.isNotEmpty
          ? createdSplitRequests.map((r) => r.id).toList()
          : widget.transaction?.splitRequestIds,
    );

    if (widget.isEditing) {
      await TransactionService.update(tx);
    } else {
      await TransactionService.add(tx);
    }

    if (!mounted) return;
    final recipientNames = _selectedRegisteredUsers.isNotEmpty
        ? _selectedRegisteredUsers.map((u) => u.name).join(', ')
        : 'friends';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_splitExpense && _sendInAppSplitRequest
            ? 'Expense saved & split request sent to $recipientNames'
            : (widget.isEditing ? 'Expense updated' : 'Expense recorded')),
        backgroundColor: PaisaTheme.primaryGreen,
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.push<ParsedMerchantQr>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(returnResultOnly: true),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _titleController.text = result.displayTitle;
      if (_expenseCategories.contains(result.category)) {
        _selectedCategory = result.category;
      }
      if (result.amount != null) {
        _amountStr = result.amount!.toStringAsFixed(0);
      }
      if (result.merchantName != null) {
        _noteController.text = 'Scanned from ${result.merchantName}';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-categorized as ${result.category}'),
        backgroundColor: PaisaTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaisaTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back Button + Add New [ Expense ▾ ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Text(
                    widget.isEditing
                        ? 'Edit ${_isExpense ? 'Expense' : 'Income'}'
                        : 'Add New ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Type dropdown pill
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpense = !_isExpense;
                        if (_isExpense) {
                          if (!_expenseCategories.contains(_selectedCategory)) {
                            _selectedCategory = _expenseCategories.first;
                          }
                        } else {
                          if (!_incomeCategories.contains(_selectedCategory)) {
                            _selectedCategory = _incomeCategories.first;
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF381E3B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpense ? 'Expense' : 'Income',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF472B6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Color(0xFFF472B6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _saveTransaction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: PaisaTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form inputs area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Card with Currency & QR Scanner Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: PaisaTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: PaisaTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _amountStr.isEmpty ? '0' : _amountStr,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _amountStr.isEmpty
                                    ? PaisaTheme.textMuted
                                    : Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _scanQrCode,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PaisaTheme.surface,
                                borderRadius: BorderRadius.circular(12),
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
                    ),

                    const SizedBox(height: 12),

                    // Title Field
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: PaisaTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. Pizza, Coffee, Uber, Groceries',
                          hintStyle: TextStyle(
                            color: PaisaTheme.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Payment Method Selection (Card, Cash, UPI, Transfer)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: PaisaTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: PaisaTheme.textLightGray,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              {'name': 'UPI', 'icon': Icons.qr_code_2_rounded},
                              {'name': 'Card', 'icon': Icons.credit_card_rounded},
                              {'name': 'Cash', 'icon': Icons.payments_outlined},
                              {'name': 'Transfer', 'icon': Icons.account_balance_rounded},
                            ].map((pm) {
                              final isSelected =
                                  _selectedPaymentMethod == pm['name'];
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: InkWell(
                                    onTap: () => setState(() =>
                                        _selectedPaymentMethod =
                                            pm['name'] as String),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? PaisaTheme.primaryGreen
                                            : PaisaTheme.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? PaisaTheme.primaryGreen
                                              : PaisaTheme.surfaceBorder,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            pm['icon'] as IconData,
                                            size: 18,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white70,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pm['name'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    if (_isExpense) ...[
                      const SizedBox(height: 12),

                      // Split Expense Row with Friend Avatars
                      Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: PaisaTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Split Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Overlapping friend avatar circles
                          SizedBox(
                            width: 60,
                            height: 28,
                            child: Stack(
                              children: [
                                _avatarCircle(
                                    0, const Color(0xFF9333EA), 'A'),
                                _avatarCircle(
                                    16, const Color(0xFFE11D48), 'B'),
                                _avatarCircle(
                                    32, const Color(0xFF2563EB), 'K'),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _splitExpense,
                            activeThumbColor: PaisaTheme.primaryGreen,
                            activeTrackColor: PaisaTheme.surface,
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: PaisaTheme.surface,
                            onChanged: (val) {
                              setState(() => _splitExpense = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_splitExpense) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PaisaTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: PaisaTheme.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Title & Participant Count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Split with Friends',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: PaisaTheme.card,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_effectivePeopleCount People (You + ${_selectedRegisteredUsers.length})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: PaisaTheme.primaryGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: _showAddPersonModal,
                                  icon: const Icon(Icons.person_add_alt_1_rounded,
                                      size: 15, color: PaisaTheme.primaryGreen),
                                  label: const Text(
                                    '+ Add Person',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: PaisaTheme.primaryGreen,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Friends Chips: Organizer + Added Registered Friends + Add Button
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // You (Organizer)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: PaisaTheme.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: PaisaTheme.primaryGreen.withOpacity(0.5)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 9,
                                          backgroundColor: PaisaTheme.primaryGreen,
                                          child: Text('Y',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black)),
                                        ),
                                        SizedBox(width: 6),
                                        Text('You',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                        SizedBox(width: 4),
                                        Text('(Payer)',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: PaisaTheme.textLightGray)),
                                      ],
                                    ),
                                  ),
                                  // Selected Registered Friends
                                  ..._selectedRegisteredUsers.map((user) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: PaisaTheme.card,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                              color: PaisaTheme.surfaceBorder),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 9,
                                              backgroundColor: const Color(0xFF6366F1),
                                              child: Text(
                                                user.name.isNotEmpty ? user.name[0] : 'F',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified_rounded,
                                                size: 13,
                                                color: PaisaTheme.primaryGreen),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedRegisteredUsers
                                                      .removeWhere((u) => u.email == user.email);
                                                  _splitPeopleCount =
                                                      1 + _selectedRegisteredUsers.length;
                                                });
                                              },
                                              child: const Icon(Icons.close_rounded,
                                                  size: 14,
                                                  color: PaisaTheme.textGray),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  // Quick + button
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: _showAddPersonModal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: PaisaTheme.primaryGreen.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                              color: PaisaTheme.primaryGreen.withOpacity(0.4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded,
                                                size: 14, color: PaisaTheme.primaryGreen),
                                            SizedBox(width: 4),
                                            Text(
                                              'Add Friend',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: PaisaTheme.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            Builder(
                              builder: (context) {
                                final rawAmt = double.tryParse(_amountStr) ?? 0.0;
                                final split = SplitService.calculateEqualSplit(
                                  totalAmount: rawAmt,
                                  peopleCount: _effectivePeopleCount,
                                  friendNames: _currentFriendNames,
                                );
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: PaisaTheme.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: PaisaTheme.surfaceBorder),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Your Share',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: PaisaTheme.textGray)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₹${split.yourShare.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: PaisaTheme.primaryGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                              width: 1,
                                              height: 32,
                                              color: PaisaTheme.surfaceBorder),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              const Text('Each Friend',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: PaisaTheme.textGray)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₹${split.sharePerPerson.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                              width: 1,
                                              height: 32,
                                              color: PaisaTheme.surfaceBorder),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Friends Owe You',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: PaisaTheme.textGray)),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₹${split.friendsTotalOwed.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Record only my share in expenses',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: PaisaTheme.textLightGray),
                                          ),
                                        ),
                                        Switch(
                                          value: _recordOnlyUserShare,
                                          activeThumbColor: PaisaTheme.primaryGreen,
                                          activeTrackColor: PaisaTheme.card,
                                          inactiveThumbColor: Colors.white54,
                                          inactiveTrackColor: PaisaTheme.card,
                                          onChanged: (v) =>
                                              setState(() => _recordOnlyUserShare = v),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: PaisaTheme.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _sendInAppSplitRequest
                                              ? PaisaTheme.primaryGreen.withOpacity(0.3)
                                              : PaisaTheme.surfaceBorder,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.mark_email_unread_rounded,
                                                    size: 16,
                                                    color: _sendInAppSplitRequest
                                                        ? PaisaTheme.primaryGreen
                                                        : PaisaTheme.textLightGray,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'In-App Split Notification',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Switch(
                                                value: _sendInAppSplitRequest,
                                                activeThumbColor:
                                                    PaisaTheme.primaryGreen,
                                                activeTrackColor: PaisaTheme.card,
                                                inactiveThumbColor: Colors.white54,
                                                inactiveTrackColor: PaisaTheme.card,
                                                onChanged: (v) => setState(
                                                    () => _sendInAppSplitRequest = v),
                                              ),
                                            ],
                                          ),
                                          if (_sendInAppSplitRequest) ...[
                                            const SizedBox(height: 6),
                                            if (_selectedRegisteredUsers.isNotEmpty) ...[
                                              Text(
                                                'Split requests for ₹${split.sharePerPerson.toStringAsFixed(0)} will be notified to ${_selectedRegisteredUsers.map((u) => u.name).join(", ")}. Each friend can Approve & Pay or Reject in-app.',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: PaisaTheme.primaryGreen,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ] else ...[
                                              const Text(
                                                'No registered friends added. Tap "+ Add Person" above to add registered Paisa users.',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFFFD166),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        onPressed: rawAmt > 0
                                            ? () {
                                                final upiUri =
                                                    SplitService.generateSplitUpiLink(
                                                  payeeUpiId: 'krishpatel@paisa',
                                                  payeeName: 'Krish Patel',
                                                  amount: split.sharePerPerson,
                                                  note: 'Split bill share',
                                                );
                                                Clipboard.setData(
                                                    ClipboardData(text: upiUri));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Split payment UPI link copied to clipboard!'),
                                                    backgroundColor:
                                                        PaisaTheme.primaryGreen,
                                                  ),
                                                );
                                              }
                                            : null,
                                        icon: const Icon(Icons.link_rounded,
                                            size: 16,
                                            color: PaisaTheme.primaryGreen),
                                        label: const Text(
                                          'Copy Split UPI Request Link',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: PaisaTheme.primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: PaisaTheme.primaryGreen),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                    const SizedBox(height: 12),

                    // Other details accordion
                    GestureDetector(
                      onTap: () {
                        setState(() => _showOtherDetails = !_showOtherDetails);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: PaisaTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: PaisaTheme.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Other details',
                              style: TextStyle(
                                fontSize: 14,
                                color: PaisaTheme.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              _showOtherDetails
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: PaisaTheme.textGray,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showOtherDetails) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PaisaTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: PaisaTheme.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _noteController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add extra note...',
                                hintStyle:
                                    TextStyle(color: PaisaTheme.textMuted),
                              ),
                            ),
                            const Divider(color: PaisaTheme.surfaceBorder),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today_rounded,
                                      size: 18, color: PaisaTheme.primaryGreen),
                                  onPressed: () async {
                                    final p = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (p != null) {
                                      setState(() => _selectedDate = p);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Category Pills Horizontal Scrolling
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _currentCategories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.transparent
                                      : PaisaTheme.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? PaisaTheme.primaryGreen
                                        : PaisaTheme.surfaceBorder,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? PaisaTheme.primaryGreen
                                        : PaisaTheme.textGray,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Custom Sleek Dial Pad (NumPad)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: PaisaTheme.background,
              ),
              child: Column(
                children: [
                  _numPadRow(['1', '2\nABC', '3\nDEF']),
                  const SizedBox(height: 10),
                  _numPadRow(['4\nGHI', '5\nJKL', '6\nMNO']),
                  const SizedBox(height: 10),
                  _numPadRow(['7\nPQRS', '8\nTUV', '9\nWXYZ']),
                  const SizedBox(height: 10),
                  _numPadRow(['+*#', '0', '⌫']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPersonModal() {
    final searchController = TextEditingController();
    bool isSearchingFirebase = false;
    PaisaUser? firebaseFoundUser;
    String lastSearch = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchController.text.trim();
            final registeredList = SplitService.registeredUsers.value;
            final filteredList = query.isEmpty
                ? registeredList
                : registeredList.where((u) {
                    final q = query.toLowerCase();
                    return u.name.toLowerCase().contains(q) ||
                        u.email.toLowerCase().contains(q) ||
                        u.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
                        u.upiId.toLowerCase().contains(q);
                  }).toList();

            // Trigger async Firebase verification if local search has no matches
            if (query.isNotEmpty &&
                filteredList.isEmpty &&
                query != lastSearch &&
                !isSearchingFirebase) {
              lastSearch = query;
              isSearchingFirebase = true;
              SplitService.verifyUserInFirebase(query).then((found) {
                isSearchingFirebase = false;
                firebaseFoundUser = found;
                setModalState(() {});
              }).catchError((_) {
                isSearchingFirebase = false;
                setModalState(() {});
              });
            }

            final isUnregisteredQuery = query.isNotEmpty &&
                filteredList.isEmpty &&
                firebaseFoundUser == null &&
                !isSearchingFirebase;

            final displayList = [...filteredList];
            if (firebaseFoundUser != null &&
                !displayList.any((u) => u.email == firebaseFoundUser!.email)) {
              displayList.add(firebaseFoundUser!);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Person to Split',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: PaisaTheme.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done_rounded,
                                    size: 13, color: PaisaTheme.primaryGreen),
                                SizedBox(width: 4),
                                Text(
                                  'Firebase Verified',
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
                      const SizedBox(height: 6),
                      const Text(
                        'Checking users in Firebase. Only verified Firebase users are eligible for in-app split.',
                        style: TextStyle(fontSize: 12, color: PaisaTheme.textGray),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: PaisaTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PaisaTheme.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: PaisaTheme.textLightGray, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                autofocus: false,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText:
                                      'Search Firebase user (name, email, or phone)...',
                                  hintStyle:
                                      TextStyle(color: PaisaTheme.textMuted),
                                ),
                                onChanged: (val) {
                                  if (val.trim() != lastSearch) {
                                    firebaseFoundUser = null;
                                  }
                                  setModalState(() {});
                                },
                              ),
                            ),
                            if (searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  firebaseFoundUser = null;
                                  lastSearch = '';
                                  setModalState(() {});
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: PaisaTheme.textGray, size: 18),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (isSearchingFirebase) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: PaisaTheme.primaryGreen,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Checking user availability in Firebase...',
                                  style: TextStyle(
                                    color: PaisaTheme.textLightGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // User list or Ineligible warning
                      if (!isSearchingFirebase)
                        Expanded(
                          child: isUnregisteredQuery
                              ? _buildUnregisteredNotice(ctx, query, setModalState)
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: displayList.length,
                                  itemBuilder: (ctx, i) {
                                    final user = displayList[i];
                                    final isSelected = _selectedRegisteredUsers
                                        .any((u) => u.email == user.email);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: PaisaTheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? PaisaTheme.primaryGreen
                                              : PaisaTheme.surfaceBorder,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: isSelected
                                                ? PaisaTheme.primaryGreen
                                                : PaisaTheme.card,
                                            child: Text(
                                              user.name.isNotEmpty
                                                  ? user.name[0]
                                                  : 'U',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      user.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Icon(
                                                      Icons.verified_rounded,
                                                      size: 14,
                                                      color:
                                                          PaisaTheme.primaryGreen,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  user.email,
                                                  style: const TextStyle(
                                                    color: PaisaTheme.textGray,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: PaisaTheme.primaryGreen
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    '✓ Registered in Firebase • Eligible for Split',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w600,
                                                      color:
                                                          PaisaTheme.primaryGreen,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedRegisteredUsers
                                                      .removeWhere((u) =>
                                                          u.email == user.email);
                                                } else {
                                                  _selectedRegisteredUsers
                                                      .add(user);
                                                }
                                                _splitPeopleCount = 1 +
                                                    _selectedRegisteredUsers.length;
                                              });
                                              setModalState(() {});
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isSelected
                                                  ? PaisaTheme.card
                                                  : PaisaTheme.primaryGreen,
                                              foregroundColor: isSelected
                                                  ? Colors.white70
                                                  : Colors.black,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? PaisaTheme.surfaceBorder
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              isSelected ? 'Remove' : '+ Add',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaisaTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Done (${_selectedRegisteredUsers.length} Friends Selected)',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUnregisteredNotice(
      BuildContext context, String query, StateSetter setModalState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B4B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: Color(0xFFFF4B4B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'User Not Available in Firebase',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No active Firebase account found for "$query".\nIn-App Split is only available for users registered in Firebase.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PaisaTheme.textGray,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaisaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: PaisaTheme.textLightGray),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automated in-app balance transfer & split requests require a verified Firebase account.',
                      style: TextStyle(
                          fontSize: 11, color: PaisaTheme.textLightGray),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final cleanName = query.contains('@')
                    ? query.split('@').first
                    : query;
                final cleanEmail = query.contains('@')
                    ? query.trim()
                    : '${query.trim()}@paisa.app';
                final newUser = PaisaUser(
                  id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                  name: cleanName.isNotEmpty
                      ? cleanName[0].toUpperCase() + cleanName.substring(1)
                      : 'Friend',
                  email: cleanEmail,
                  phone: '',
                  upiId: '${cleanName.toLowerCase()}@paisa',
                  isRegistered: true,
                );
                await SplitService.registerUser(newUser);
                await SplitService.syncUserToFirebase(newUser);
                setState(() {
                  _selectedRegisteredUsers.add(newUser);
                  _splitPeopleCount = 1 + _selectedRegisteredUsers.length;
                });
                setModalState(() {});
              },
              icon: const Icon(Icons.cloud_upload_rounded,
                  size: 16, color: PaisaTheme.primaryGreen),
              label: const Text(
                'Register & Sync to Firebase',
                style: TextStyle(
                  color: PaisaTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: PaisaTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarCircle(double left, Color bg, String label) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: PaisaTheme.card, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _numPadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isBackspace = key == '⌫';
        final parts = key.split('\n');
        final primary = parts[0];
        final sub = parts.length > 1 ? parts[1] : '';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () => _onKeypadTap(primary),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: PaisaTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PaisaTheme.surfaceBorder),
                ),
                child: Center(
                  child: isBackspace
                      ? const Icon(Icons.backspace_outlined,
                          size: 20, color: Colors.white)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              primary,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (sub.isNotEmpty)
                              Text(
                                sub,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: PaisaTheme.textMuted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}