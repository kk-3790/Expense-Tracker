import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../theme/paisa_theme.dart';

class CreateGoalModal extends StatefulWidget {
  const CreateGoalModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PaisaTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => const CreateGoalModal(),
    );
  }

  @override
  State<CreateGoalModal> createState() => _CreateGoalModalState();
}

class _CreateGoalModalState extends State<CreateGoalModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90));
  String _selectedCategory = 'Transportation';

  final List<String> _categories = [
    'Housing',
    'Utilities',
    'Food',
    'Transportation',
    'Savings',
    'Vacation',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PaisaTheme.primaryGreen,
              onPrimary: Colors.black,
              surface: PaisaTheme.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid goal amount')),
      );
      return;
    }

    final newGoal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: amount,
      currentAmount: 0.0,
      targetDate: _selectedDate,
      category: _selectedCategory,
    );

    await GoalService.addGoal(newGoal);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal "$name" created successfully!'),
        backgroundColor: PaisaTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: PaisaTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Goal Name Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: PaisaTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PaisaTheme.surfaceBorder),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Goal Name',
                hintStyle: TextStyle(color: PaisaTheme.textMuted, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Goal Amount Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: PaisaTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PaisaTheme.surfaceBorder),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Goal Amount (₹)',
                hintStyle: TextStyle(color: PaisaTheme.textMuted, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Target Date Input
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: PaisaTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: PaisaTheme.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target Date: ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: PaisaTheme.textGray,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PaisaTheme.primaryGreen
                            : PaisaTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? PaisaTheme.primaryGreen
                              : PaisaTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.black : PaisaTheme.textGray,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),
          // Create Goal Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Create Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
