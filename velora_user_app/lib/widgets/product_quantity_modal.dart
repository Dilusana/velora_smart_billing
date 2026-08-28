import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cart_service.dart';
import '../services/user_activity_service.dart';

class WeightOption {
  final String label;
  final double kgFactor;

  const WeightOption(this.label, this.kgFactor);
}

const List<WeightOption> kWeightOptions = [
  WeightOption('100g', 0.1),
  WeightOption('200g', 0.2),
  WeightOption('250g', 0.25),
  WeightOption('300g', 0.3),
  WeightOption('400g', 0.4),
  WeightOption('500g', 0.5),
  WeightOption('600g', 0.6),
  WeightOption('750g', 0.75),
  WeightOption('800g', 0.8),
  WeightOption('900g', 0.9),
  WeightOption('1 kg', 1.0),
  WeightOption('1.1kg', 1.1),
  WeightOption('1.2kg', 1.2),
  WeightOption('1.3kg', 1.3),
  WeightOption('1.4kg', 1.4),
  WeightOption('1.5kg', 1.5),
  WeightOption('1.6kg', 1.6),
  WeightOption('1.7kg', 1.7),
  WeightOption('1.8kg', 1.8),
  WeightOption('1.9kg', 1.9),
  WeightOption('2 kg', 2.0),
  WeightOption('2.2kg', 2.2),
  WeightOption('2.5 kg', 2.5),
  WeightOption('2.8kg', 2.8),
  WeightOption('3 kg', 3.0),
  WeightOption('3.2kg', 3.2),
  WeightOption('3.5kg', 3.5),
  WeightOption('3.8kg', 3.8),
  WeightOption('4 kg', 4.0),
  WeightOption('4.5kg', 4.5),
  WeightOption('5 kg', 5.0),
  WeightOption('5.5kg', 5.5),
  WeightOption('6 kg', 6.0),
  WeightOption('6.5kg', 6.5),
  WeightOption('7 kg', 7.0),
  WeightOption('7.5 kg', 7.5),
  WeightOption('8 kg', 8.0),
  WeightOption('8.5 kg', 8.5),
  WeightOption('9 kg', 9.0),
  WeightOption('9.5 kg', 9.5),
  WeightOption('10 kg', 10.0),
  WeightOption('12 kg', 12.0),
  WeightOption('15 kg', 15.0),
  WeightOption('20 kg', 20.0),
  WeightOption('25 kg', 25.0),
  WeightOption('30 kg', 30.0),
  WeightOption('40 kg', 40.0),
  WeightOption('50 kg', 50.0),
  WeightOption('75 kg', 75.0),
  WeightOption('100 kg', 100.0),
];

class ProductQuantityModal extends StatefulWidget {
  final String productId;
  final String productName;
  final String category;
  final String unit;
  final double basePrice;
  final String imageUrl;
  final IconData fallbackIcon;

  const ProductQuantityModal({
    super.key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.unit,
    required this.basePrice,
    this.imageUrl = '',
    this.fallbackIcon = Icons.shopping_basket_rounded,
  });

  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productName,
    required String category,
    required String unit,
    required double basePrice,
    String imageUrl = '',
    IconData fallbackIcon = Icons.shopping_basket_rounded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductQuantityModal(
        productId: productId,
        productName: productName,
        category: category,
        unit: unit,
        basePrice: basePrice,
        imageUrl: imageUrl,
        fallbackIcon: fallbackIcon,
      ),
    );
  }

  @override
  State<ProductQuantityModal> createState() => _ProductQuantityModalState();
}

class _ProductQuantityModalState extends State<ProductQuantityModal> {
  late bool _isKgProduct;
  late WeightOption _selectedWeight;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _isKgProduct = _checkIsKgProduct(widget.unit);
    _selectedWeight = kWeightOptions.firstWhere(
      (opt) => opt.kgFactor == 1.0,
      orElse: () => kWeightOptions[10],
    );
  }

  bool _checkIsKgProduct(String unitStr) {
    final s = unitStr.toLowerCase().trim();
    if (s == 'kg' ||
        s == '1kg' ||
        s == '1 kg' ||
        s == 'per kg' ||
        s.contains('kg') ||
        s.contains('kilogram') ||
        s.contains('gram') ||
        s.contains('100g') ||
        s.contains('500g') ||
        s.contains('250g')) {
      return true;
    }
    return false;
  }

  double get _calculatedPrice {
    if (_isKgProduct) {
      return widget.basePrice * _selectedWeight.kgFactor * _quantity;
    } else {
      return widget.basePrice * _quantity;
    }
  }

  void _handleAddToCart() {
    final String description = _isKgProduct
        ? '${_selectedWeight.label} pack'
        : (widget.unit.isNotEmpty ? widget.unit : '1 piece');

    CartService.instance.addItem(
      productId: widget.productId,
      category: widget.category,
      title: widget.productName,
      description: description,
      price: _isKgProduct ? (widget.basePrice * _selectedWeight.kgFactor) : widget.basePrice,
      quantity: _quantity,
      imageUrl: widget.imageUrl,
    );

    UserActivityService.instance.logAddToCart(
      productId: widget.productId,
      productName: widget.productName,
      categoryName: widget.category,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFCEE847), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added ${widget.productName} (${_isKgProduct ? _selectedWeight.label : '$_quantity ${widget.unit.isNotEmpty ? widget.unit : 'pieces'}'}) to cart!',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A2D5A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedImg = widget.imageUrl;
    if (formattedImg.startsWith('assets/')) {
      formattedImg = formattedImg.replaceFirst('assets/', 'assests/');
    }
    final bool isNetworkImage =
        formattedImg.startsWith('http://') || formattedImg.startsWith('https://');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header with Close Button
          Row(
            children: [
              Text(
                'Select Quantity & Weight',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Product Summary Card inside Popup
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: formattedImg.isNotEmpty
                        ? (isNetworkImage
                            ? Image.network(
                                formattedImg,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildFallbackIcon(),
                              )
                            : Image.asset(
                                formattedImg,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildFallbackIcon(),
                              ))
                        : _buildFallbackIcon(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isKgProduct
                                  ? const Color(0xFFEEF5E3)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isKgProduct ? 'kg' : (widget.unit.isNotEmpty ? widget.unit : 'piece'),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _isKgProduct
                                    ? const Color(0xFF4F6F0B)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.productName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Base Price: Rs ${widget.basePrice.toStringAsFixed(2)} / ${_isKgProduct ? 'kg' : (widget.unit.isNotEmpty ? widget.unit : 'piece')}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Drag Down Option for KG Products ───────────────────────────────
          if (_isKgProduct) ...[
            Text(
              'Select Weight (100g to 100kg):',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4F6F0B), width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F6F0B).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<WeightOption>(
                  value: _selectedWeight,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF4F6F0B), size: 24),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 320,
                  items: kWeightOptions.map((opt) {
                    final double optPrice = widget.basePrice * opt.kgFactor;
                    return DropdownMenuItem<WeightOption>(
                      value: opt,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt.label,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Rs ${optPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F6F0B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWeight = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Quantity Stepper Section ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity (Packs / Units):',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5E3),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF263A12)),
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF263A12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF263A12)),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Total Price & Add Button ───────────────────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Rs ${_calculatedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF263A12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6F0B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add to Cart',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: const Color(0xFFEEF5E3),
      child: Center(
        child: Icon(widget.fallbackIcon, size: 30, color: const Color(0xFF4F6F0B)),
      ),
    );
  }
}
