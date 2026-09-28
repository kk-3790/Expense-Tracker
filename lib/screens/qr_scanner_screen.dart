import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/qr_scanner_service.dart';
import '../services/settings_service.dart';
import 'add_transaction_screen.dart';

class QrScannerScreen extends StatefulWidget {
  /// If [returnResultOnly] is true, pops the screen with [ParsedMerchantQr]
  /// instead of pushing [AddTransactionScreen].
  final bool returnResultOnly;

  const QrScannerScreen({
    super.key,
    this.returnResultOnly = false,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _animation;

  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) return;

    _handleScannedData(rawValue);
  }

  void _handleScannedData(String rawValue) {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.heavyImpact();
    _controller.stop();

    final result = QrScannerService.parse(rawValue);

    if (!mounted) return;

    if (widget.returnResultOnly) {
      Navigator.pop(context, result);
      return;
    }

    _showResultBottomSheet(result);
  }

  void _showResultBottomSheet(ParsedMerchantQr result) {
    final currency = SettingsService.currency.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? const Color(0xFF16201E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Top Badge: Auto Categorized
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7F23D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(result.category),
                            size: 16,
                            color: const Color(0xFF172015),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            result.category,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF172015),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        result.mcc != null
                            ? 'MCC: ${result.mcc}'
                            : 'Smart Match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Merchant Name
                Text(
                  result.merchantName ?? result.merchantId ?? 'Unknown Merchant',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (result.merchantId != null &&
                    result.merchantId != result.merchantName) ...[
                  const SizedBox(height: 4),
                  Text(
                    'UPI ID: ${result.merchantId}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],

                if (result.mccDescription != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    result.mccDescription!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF7FA835),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Amount Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF22302D)
                        : const Color(0xFFEFF3E6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Amount:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        result.amount != null
                            ? '$currency${result.amount!.toStringAsFixed(2)}'
                            : 'Enter manually',
                        style: TextStyle(
                          fontSize: result.amount != null ? 20 : 14,
                          fontWeight: FontWeight.w700,
                          color: result.amount != null
                              ? const Color(0xFFB7F23D)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _isProcessing = false;
                          });
                          _controller.start();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Scan Again'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext); // Close sheet
                          Navigator.pop(context); // Close scanner screen

                          // Open Add Transaction Screen pre-filled
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(
                                initialTitle: result.displayTitle,
                                initialAmount: result.amount,
                                initialCategory: result.category,
                                initialNote: result.merchantId != null
                                    ? 'Paid to: ${result.merchantId}'
                                    : (result.mccDescription ?? ''),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFB7F23D),
                          foregroundColor: const Color(0xFF172015),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Fill Expense',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualOrTestModal() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter or Test QR Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste a UPI link, 4-digit MCC code, or tap a sample below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'e.g. upi://pay?pa=... or 5411',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.pop(sheetContext);
                        _handleScannedData(text);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Test Merchant Categories:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _testChip(
                    sheetContext,
                    label: '🛒 Grocery (5411)',
                    sample:
                        'upi://pay?pa=supermarket@upi&pn=D-Mart%20Supermarket&mc=5411&am=350.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '☕ Restaurant (5812)',
                    sample:
                        'upi://pay?pa=starbucks@icici&pn=Starbucks%20Cafe&mc=5812&am=280.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '⛽ Petrol Pump (5541)',
                    sample:
                        'upi://pay?pa=indianoil@sbi&pn=Indian%20Oil%20Station&mc=5541&am=500.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '💊 Pharmacy (5912)',
                    sample:
                        'upi://pay?pa=apollo@hdfcbank&pn=Apollo%20Pharmacy&mc=5912&am=180.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '🛍️ Shopping (5311)',
                    sample:
                        'upi://pay?pa=zara@axisbank&pn=Zara%20Fashion&mc=5311&am=1499.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '⚡ Utility Bill (4900)',
                    sample:
                        'upi://pay?pa=electricity@gov&pn=Electricity%20Board&mc=4900&am=1200.00',
                  ),
                  _testChip(
                    sheetContext,
                    label: '🎬 Cinema (7832)',
                    sample:
                        'upi://pay?pa=pvrcinemas@icici&pn=PVR%20Cinemas&mc=7832&am=420.00',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _testChip(
    BuildContext sheetContext, {
    required String label,
    required String sample,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(sheetContext);
        _handleScannedData(sample);
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Health':
        return Icons.favorite_rounded;
      case 'Education':
        return Icons.school_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera unavailable: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showManualOrTestModal,
                        child: const Text('Enter Code Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Viewfinder Reticle Overlay
          LayoutBuilder(
            builder: (context, constraints) {
              final scanSize = constraints.maxWidth * 0.72;
              final topOffset = (constraints.maxHeight - scanSize) / 2.3;
              final leftOffset = (constraints.maxWidth - scanSize) / 2;

              return Stack(
                children: [
                  // Translucent dark surround
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withAlpha(160),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            backgroundBlendMode: BlendMode.dstOut,
                          ),
                        ),
                        Positioned(
                          top: topOffset,
                          left: leftOffset,
                          width: scanSize,
                          height: scanSize,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reticle Border & Accents
                  Positioned(
                    top: topOffset,
                    left: leftOffset,
                    width: scanSize,
                    height: scanSize,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFB7F23D),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _LaserLinePainter(
                                progress: _animation.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Hint Text below reticle
                  Positioned(
                    top: topOffset + scanSize + 28,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        const Text(
                          'Point camera at Merchant QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black87),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '⚡ Auto-categorizes Food, Travel, Shopping & more',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFB7F23D),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Top Control Bar (Back, Flash, Camera Switch)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? const Color(0xFFB7F23D) : Colors.white,
                      ),
                      onPressed: () async {
                        await _controller.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                      onPressed: () => _controller.switchCamera(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Test / Manual Input Button
          Positioned(
            bottom: 34,
            left: 24,
            right: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _showManualOrTestModal,
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Enter Code / Test Presets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFB7F23D), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaserLinePainter extends CustomPainter {
  final double progress;

  _LaserLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFB7F23D),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _LaserLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
