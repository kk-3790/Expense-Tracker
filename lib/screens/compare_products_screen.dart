import 'package:flutter/material.dart';
import '../theme/paisa_theme.dart';

class CompareProductsScreen extends StatefulWidget {
  const CompareProductsScreen({super.key});

  @override
  State<CompareProductsScreen> createState() => _CompareProductsScreenState();
}

class _CompareProductsScreenState extends State<CompareProductsScreen> {
  final List<Map<String, dynamic>> products = [
    {
      'name': 'iPhone 14 Pro',
      'price': '₹ 1,19,900',
      'color': const Color(0xFF6C5CE7),
      'icon': Icons.phone_iphone_rounded,
      'specs': [
        {
          'title': 'Display',
          'value':
              '15.54cm (6.1") Super Retina XDR display\nProMotion technology\nAlways-On display'
        },
        {
          'title': 'Build',
          'value':
              'Stainless steel with textured matt glass back\nRing/Silent switch'
        },
        {
          'title': 'Dynamic Island',
          'value':
              'Dynamic Island A magical way to interact with iPhone'
        },
        {
          'title': 'Chip',
          'value':
              'A16 Bionic chip\n6-core CPU\n5-core GPU\n16-core Neural Engine'
        },
      ],
    },
    {
      'name': 'iPhone 15 Pro',
      'price': '₹ 1,34,900',
      'color': const Color(0xFFD4AF37),
      'icon': Icons.phone_iphone_rounded,
      'specs': [
        {
          'title': 'Display',
          'value':
              '15.54cm (6.1") Super Retina XDR display\nProMotion technology\nAlways-On display'
        },
        {
          'title': 'Build',
          'value':
              'Titanium with textured matt glass back\nAction button'
        },
        {
          'title': 'Dynamic Island',
          'value':
              'Dynamic Island A magical way to interact with iPhone'
        },
        {
          'title': 'Chip',
          'value':
              'A17 Pro chip\n6-core CPU\n6-core GPU\n16-core Neural Engine'
        },
      ],
    },
  ];

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PaisaTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final options = [
          'MacBook Pro 14" M3',
          'iPad Pro 11" M4',
          'Apple Watch Ultra 2',
          'AirPods Max (USB-C)',
        ];
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
                  'Select Product to Compare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PaisaTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PaisaTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.devices_rounded,
                            color: PaisaTheme.primaryGreen, size: 20),
                      ),
                      title: Text(
                        opt,
                        style: const TextStyle(
                          color: PaisaTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded,
                          color: PaisaTheme.primaryGreen),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$opt added to comparison'),
                            backgroundColor: PaisaTheme.card,
                          ),
                        );
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Compare Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              children: [
                // Top phone mockups row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProductColumn(
                        product: products[0],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 580,
                      color: PaisaTheme.surfaceBorder,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ProductColumn(
                        product: products[1],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _showAddProductModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Add more items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _ProductColumn extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductColumn({required this.product});

  @override
  Widget build(BuildContext context) {
    final specs = product['specs'] as List<Map<String, String>>;
    final color = product['color'] as Color;

    return Column(
      children: [
        // Realistic phone mockup visual
        Container(
          width: 110,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFF14171D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(100), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 18),
              Icon(
                product['icon'] as IconData,
                size: 54,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                product['price'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: PaisaTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          product['name'] as String,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: PaisaTheme.textWhite,
          ),
        ),
        const SizedBox(height: 20),
        ...specs.map((spec) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                children: [
                  Text(
                    spec['value']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: PaisaTheme.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
