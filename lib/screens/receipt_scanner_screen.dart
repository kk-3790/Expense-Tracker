import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../theme/paisa_theme.dart';

class ScannedItem {
  final String name;
  int quantity;
  final double unitPrice;

  ScannedItem({
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  bool _isReviewMode = false;
  final MobileScannerController _cameraController = MobileScannerController();

  final List<ScannedItem> _detectedItems = [
    ScannedItem(name: 'Oranges (kg)', quantity: 1, unitPrice: 60),
    ScannedItem(name: 'Bananas (dozen)', quantity: 1, unitPrice: 70),
    ScannedItem(name: 'Apples (kg)', quantity: 1, unitPrice: 90),
  ];

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PaisaTheme.card,
        title: const Text('Add Item', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Item name',
                hintStyle: TextStyle(color: PaisaTheme.textMuted),
              ),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Price (₹)',
                hintStyle: TextStyle(color: PaisaTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PaisaTheme.textGray)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              if (name.isNotEmpty && price > 0) {
                setState(() {
                  _detectedItems.add(ScannedItem(name: name, unitPrice: price));
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: PaisaTheme.primaryGreen),
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _saveAllItems() async {
    final total = _detectedItems.fold(0.0, (sum, i) => sum + i.totalPrice);
    final itemNames = _detectedItems.map((i) => '${i.name} (x${i.quantity})').join(', ');

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Grocery Store Receipt',
      note: itemNames,
      date: DateTime.now(),
      amount: total,
      category: 'Groceries',
      type: 'Expense',
    );

    await TransactionService.add(newTx);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ₹${total.toStringAsFixed(0)} grocery expense!'),
        backgroundColor: PaisaTheme.primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isReviewMode) {
      return _buildReviewScreen();
    }
    return _buildCameraScreen();
  }

  // ==========================================================
  // CAMERA SCANNER VIEW (Behance media_1790622685669.png)
  // ==========================================================
  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Viewfinder
          Positioned.fill(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) {
                // Mock smart detection triggers automatically
              },
            ),
          ),

          // Gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(220),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0x66000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Expense tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Center Viewfinder Target Reticle
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                          left: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                          right: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                          left: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                          right: BorderSide(color: PaisaTheme.primaryGreen, width: 4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detected Items Floating Pills
          Positioned(
            left: 20,
            right: 20,
            bottom: 110,
            child: Column(
              children: [
                const Text(
                  'Detected Items',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DetectedPill(label: 'oranges', onRemove: () {}),
                    const SizedBox(width: 8),
                    _DetectedPill(label: 'apples', onRemove: () {}),
                    const SizedBox(width: 8),
                    _DetectedPill(label: 'bananas', onRemove: () {}),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Button
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => setState(() => _isReviewMode = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F242D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: const BorderSide(color: PaisaTheme.surfaceBorder),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to add expense',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REVIEW DETECTED ITEMS SCREEN (Behance media_1790622685655.png)
  // ==========================================================
  Widget _buildReviewScreen() {
    final total = _detectedItems.fold(0.0, (sum, i) => sum + i.totalPrice);

    return Scaffold(
      backgroundColor: PaisaTheme.background,
      appBar: AppBar(
        backgroundColor: PaisaTheme.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => setState(() => _isReviewMode = false),
            child: Container(
              decoration: const BoxDecoration(
                color: PaisaTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                const Text(
                  'Detected Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PaisaTheme.textLightGray,
                  ),
                ),
                const SizedBox(height: 16),
                ..._detectedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: PaisaTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: PaisaTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Stepper: - 1 +
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: PaisaTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: PaisaTheme.surfaceBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (item.quantity > 1) {
                                      setState(() => item.quantity--);
                                    }
                                  },
                                  child: const Text(' - ',
                                      style: TextStyle(
                                          color: PaisaTheme.textGray,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => item.quantity++);
                                  },
                                  child: const Text(' + ',
                                      style: TextStyle(
                                          color: PaisaTheme.textGray,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '₹ ${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                // Scan again + Add more buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isReviewMode = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaisaTheme.card,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: PaisaTheme.surfaceBorder),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Scan again',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _showAddItemDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PaisaTheme.card,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: PaisaTheme.surfaceBorder),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Add more',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total & Primary ADD Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: PaisaTheme.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Calculated',
                      style: TextStyle(color: PaisaTheme.textGray, fontSize: 14),
                    ),
                    Text(
                      '₹ ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PaisaTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveAllItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ADD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
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

class _DetectedPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _DetectedPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, size: 14, color: Colors.black),
        ],
      ),
    );
  }
}
