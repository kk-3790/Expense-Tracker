import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/qr_scanner_service.dart';
import '../services/settings_service.dart';
import '../services/transaction_service.dart';
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
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController =
  TextEditingController();

  final TextEditingController noteController =
  TextEditingController();

  bool isExpense = true;

  String selectedCategory = 'Food';

  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
    },
    {
      'name': 'Health',
      'icon': Icons.favorite_rounded,
    },
    {
      'name': 'Education',
      'icon': Icons.school_rounded,
    },
    {
      'name': 'Other',
      'icon': Icons.more_horiz_rounded,
    },
  ];

  String? customTitle;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      isExpense = transaction.isExpense;
      selectedCategory = transaction.category;
      selectedDate = transaction.date;

      amountController.text =
          transaction.amount.abs().toStringAsFixed(2);

      noteController.text = transaction.note;
      customTitle = transaction.title;
    } else {
      customTitle = widget.initialTitle;
      if (widget.initialCategory != null &&
          categories.any((c) => c['name'] == widget.initialCategory)) {
        selectedCategory = widget.initialCategory!;
      }
      if (widget.initialAmount != null) {
        amountController.text =
            widget.initialAmount!.toStringAsFixed(2);
      }
      if (widget.initialNote != null) {
        noteController.text = widget.initialNote!;
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || !mounted) return;

    setState(() {
      selectedDate = picked;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
    double.parse(amountController.text.trim());

    final transaction =
    TransactionModel(
      id: widget.transaction?.id ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      title: customTitle?.trim().isNotEmpty == true
          ? customTitle!.trim()
          : selectedCategory,

      note: noteController.text.trim(),

      date: selectedDate,

      amount: amount,

      category: selectedCategory,

      type: isExpense
          ? 'Expense'
          : 'Income',
    );

    if (widget.isEditing) {
      await TransactionService.update(
        transaction,
      );
    } else {
      await TransactionService.add(
        transaction,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Transaction updated'
              : 'Transaction added',
        ),
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
      customTitle = result.displayTitle;
      if (categories.any((c) => c['name'] == result.category)) {
        selectedCategory = result.category;
      }
      if (result.amount != null) {
        amountController.text = result.amount!.toStringAsFixed(2);
      }
      final parts = <String>[];
      if (result.merchantName != null && result.merchantName!.isNotEmpty) {
        parts.add(result.merchantName!);
      }
      if (result.merchantId != null && result.merchantId!.isNotEmpty) {
        parts.add('ID: ${result.merchantId}');
      }
      if (result.mccDescription != null) {
        parts.add('(${result.mccDescription})');
      }
      if (parts.isNotEmpty) {
        noteController.text = parts.join(' - ');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto-categorized as ${result.category} (${result.matchMethod})',
        ),
        backgroundColor: const Color(0xFF172015),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currency =
        SettingsService.currency.value;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF1E222A)
        : const Color(0xFFEFF2F6);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: Text(
          widget.isEditing
              ? 'Edit Transaction'
              : 'Add Transaction',
        ),
        actions: [
          IconButton(
            tooltip: 'Scan Merchant QR',
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
            ),
            onPressed: _scanQrCode,
          ),
        ],
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ======================================================
              // EXPENSE / INCOME
              // ======================================================

              Container(
                padding: const EdgeInsets.all(5),

                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                  BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        title: 'Expense',
                        selected: isExpense,
                        onTap: () {
                          setState(() {
                            isExpense = true;
                          });
                        },
                      ),
                    ),

                    Expanded(
                      child: _TypeButton(
                        title: 'Income',
                        selected: !isExpense,
                        onTap: () {
                          setState(() {
                            isExpense = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (customTitle != null && customTitle!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7F23D).withAlpha(50),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFB7F23D),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 18,
                        color: Color(0xFFB7F23D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Merchant: $customTitle',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF172015),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            customTitle = null;
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : const Color(0xFF172015),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ======================================================
              // AMOUNT
              // ======================================================

              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: TextFormField(
                  controller: amountController,

                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Enter an amount';
                    }

                    final amount =
                    double.tryParse(
                      value.trim(),
                    );

                    if (amount == null ||
                        amount <= 0) {
                      return 'Enter a valid amount';
                    }

                    return null;
                  },

                  decoration:
                  InputDecoration(
                    border: InputBorder.none,

                    prefixText:
                    '$currency ',

                    prefixStyle:
                    const TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w700,
                    ),

                    hintText: '0.00',

                    hintStyle:
                    const TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF9AA394),
                    ),
                  ),

                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ======================================================
              // CATEGORY
              // ======================================================

              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                itemCount: categories.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),

                itemBuilder: (context, index) {
                  final category =
                  categories[index];

                  final String name =
                  category['name'] as String;

                  final IconData icon =
                  category['icon']
                  as IconData;

                  return _CategoryItem(
                    name: name,
                    icon: icon,
                    selected:
                    selectedCategory ==
                        name,
                    onTap: () {
                      setState(() {
                        selectedCategory =
                            name;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 28),

              // ======================================================
              // DATE
              // ======================================================

              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _selectDate,

                child: Container(
                  width: double.infinity,

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),

                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_rounded,
                        size: 20,
                      ),

                      const SizedBox(width: 12),

                      Text(
                        '${selectedDate.day}/'
                            '${selectedDate.month}/'
                            '${selectedDate.year}',

                        style:
                        const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                      const Spacer(),

                      const Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ======================================================
              // NOTE
              // ======================================================

              const Text(
                'Note',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius:
                  BorderRadius.circular(18),
                ),

                child: TextField(
                  controller: noteController,

                  maxLines: 3,

                  decoration:
                  const InputDecoration(
                    border: InputBorder.none,
                    hintText:
                    'Add a note...',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ======================================================
              // SAVE
              // ======================================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : const Color(0xFF121417),
                    foregroundColor: isDark ? const Color(0xFF121417) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    widget.isEditing
                        ? 'Update Transaction'
                        : 'Confirm Transaction',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// TYPE BUTTON
// ======================================================================

class _TypeButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white : const Color(0xFF121417))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? (isDark ? const Color(0xFF121417) : Colors.white)
                  : (isDark ? Colors.white70 : const Color(0xFF555B63)),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// CATEGORY ITEM
// ======================================================================

class _CategoryItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white : const Color(0xFF121417))
              : (isDark ? const Color(0xFF1E222A) : const Color(0xFFEFF2F6)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? (isDark ? const Color(0xFF121417) : Colors.white)
                  : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (isDark ? const Color(0xFF121417) : Colors.white)
                    : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}