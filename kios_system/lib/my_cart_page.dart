import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'cart_database.dart';
import 'cart_item.dart';
import 'payment_method_page.dart';
import 'order_repository.dart';
import 'promotion_model.dart';
import 'promotion_repository.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  late Future<List<CartItem>> _cartFuture;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isRegisteredCustomer = false;
  bool _isSearchingCustomer = false;
  bool _customerFound = false;
  String _searchCustomerMessage = '';

  bool _promoApplied = false;
  bool _isApplyingPromo = false;
  String _promoMessage = '';
  double _appliedDiscount = 0.0;
  PromotionModel? _activePromotion;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = CartDatabase.instance.getItems().then((items) {
        if (_promoApplied && _activePromotion != null) {
          _recalcPromo(items);
        }
        return items;
      });
    });
  }

  void _recalcPromo(List<CartItem> items) {
    final sub = _subtotal(items);
    if (_activePromotion != null) {
      if (_activePromotion!.minimumPurchaseAmount > 0 &&
          sub < _activePromotion!.minimumPurchaseAmount) {
        _promoApplied = false;
        _appliedDiscount = 0.0;
        _promoMessage =
            'Cart subtotal dropped below Rs.${_activePromotion!.minimumPurchaseAmount.toStringAsFixed(0)} minimum spend for this promo.';
        return;
      }
      double disc = 0.0;
      final type = _activePromotion!.type.toLowerCase();
      if (type.contains('percent') || type.contains('%') || type == 'discount %') {
        disc = sub * (_activePromotion!.value / 100.0);
      } else if (type.contains('flat') || type == 'flat off') {
        disc = _activePromotion!.value;
      } else if (type.contains('bogo')) {
        disc = sub * 0.5;
      } else {
        disc = _activePromotion!.value <= 100
            ? sub * (_activePromotion!.value / 100.0)
            : _activePromotion!.value;
      }

      if (_activePromotion!.maximumDiscount > 0 &&
          disc > _activePromotion!.maximumDiscount) {
        disc = _activePromotion!.maximumDiscount;
      }
      _appliedDiscount = disc.clamp(0.0, sub);
    }
  }

  Future<void> _incrementQuantity(CartItem item) async {
    final updated = item.copyWith(quantity: item.quantity + 1);
    await CartDatabase.instance.updateItem(updated);
    _refreshCart();
  }

  Future<void> _decrementQuantity(CartItem item) async {
    if (item.quantity > 1) {
      final updated = item.copyWith(quantity: item.quantity - 1);
      await CartDatabase.instance.updateItem(updated);
    } else if (item.id != null) {
      await CartDatabase.instance.deleteItem(item.id!);
    }
    _refreshCart();
  }

  Future<void> _removeItem(CartItem item) async {
    if (item.id != null) {
      await CartDatabase.instance.deleteItem(item.id!);
      _refreshCart();
    }
  }

  Future<void> _searchCustomerByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSearchingCustomer = true;
      _searchCustomerMessage = '';
    });

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Search by phone in Firestore customers collection
      var querySnap = await firestore
          .collection('customers')
          .where('phone', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty && !cleanPhone.startsWith('+')) {
        querySnap = await firestore
            .collection('customers')
            .where('phone', isEqualTo: '+94$cleanPhone')
            .limit(1)
            .get();
      }

      Map<String, dynamic>? data;
      if (querySnap.docs.isNotEmpty) {
        data = querySnap.docs.first.data();
      } else {
        // 2. Search by document id
        final docSnap =
            await firestore.collection('customers').doc('cust_$cleanPhone').get();
        if (docSnap.exists) {
          data = docSnap.data();
        }
      }

      if (data != null) {
        final name = (data['fullName'] ??
                data['name'] ??
                data['customerName'] ??
                data['first_name'] ??
                '')
            .toString();
        final email = (data['email'] ?? data['gmail'] ?? '').toString();
        final address = (data['address'] ?? '').toString();

        setState(() {
          _isSearchingCustomer = false;
          _customerFound = true;
          if (name.isNotEmpty) _nameController.text = name;
          if (email.isNotEmpty) _emailController.text = email;
          if (address.isNotEmpty) _addressController.text = address;
          _searchCustomerMessage = '✓ Registered Customer Found: $name';
        });
        return;
      }
    } catch (_) {
      // Fallback for offline or testing mode
    }

    // Pre-registered sample customers for instant testing
    final mockData = {
      '0771234567': {
        'name': 'John Doe',
        'email': 'johndoe@gmail.com',
        'address': 'No 45, Galle Road, Colombo 03',
      },
      '+94771234567': {
        'name': 'John Doe',
        'email': 'johndoe@gmail.com',
        'address': 'No 45, Galle Road, Colombo 03',
      },
      '0778889999': {
        'name': 'Sarah Perera',
        'email': 'sarah.perera@gmail.com',
        'address': 'No 12, Kandy Road, Kiribathgoda',
      },
    };

    final mockMatch = mockData[cleanPhone];
    if (mockMatch != null) {
      setState(() {
        _isSearchingCustomer = false;
        _customerFound = true;
        _nameController.text = mockMatch['name']!;
        _emailController.text = mockMatch['email']!;
        _addressController.text = mockMatch['address']!;
        _searchCustomerMessage =
            '✓ Registered Customer Found: ${mockMatch['name']}';
      });
    } else {
      setState(() {
        _isSearchingCustomer = false;
        _customerFound = false;
        _searchCustomerMessage = 'No customer record found for this phone number.';
      });
    }
  }

  Future<void> _applyPromo([String? explicitCode]) async {
    final code = explicitCode ?? _promoController.text.trim();
    if (code.isEmpty) return;

    if (explicitCode != null) {
      _promoController.text = explicitCode;
    }

    setState(() {
      _isApplyingPromo = true;
      _promoMessage = '';
    });

    final items = await CartDatabase.instance.getItems();
    final subtotal = _subtotal(items);

    final result = await KioskPromotionRepository.instance
        .validateCouponCode(code, subtotal);

    if (!mounted) return;
    setState(() {
      _isApplyingPromo = false;
      if (result.isValid) {
        _promoApplied = true;
        _appliedDiscount = result.discount;
        _activePromotion = result.promotion;
        _promoMessage = result.message;
      } else {
        _promoApplied = false;
        _appliedDiscount = 0.0;
        _activePromotion = null;
        _promoMessage = result.message;
      }
    });
  }

  double _priceForTitle(String title) {
    switch (title) {
      case 'Bananas':
        return 1.20;
      case 'Roma Tomatoes':
        return 2.50;
      case 'Fresh Spinach':
        return 3.40;
      case 'Red Apples':
        return 1.80;
      case 'Whole Wheat Bread':
        return 2.90;
      case 'Cooking Oil':
        return 5.30;
      case 'Rice 5kg':
        return 12.50;
      default:
        return 2.50;
    }
  }

  double _itemPrice(CartItem item) {
    final double unitPrice =
        item.price > 0 ? item.price : _priceForTitle(item.title);
    return unitPrice * item.quantity;
  }

  double _subtotal(List<CartItem> items) {
    return items.fold(0.0, (totalSum, item) => totalSum + _itemPrice(item));
  }

  double _discount(double subtotal) {
    return _promoApplied ? _appliedDiscount : 0.0;
  }

  String _formattedPrice(double value) {
    return 'Rs.${value.toStringAsFixed(0)}';
  }

  IconData _iconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'bananas':
      case 'fresh spinach':
      case 'red apples':
      case 'tomoeto':
      case 'tomato':
      case 'vegetable mix':
        return Icons.eco_rounded;
      case 'whole wheat bread':
      case 'bread':
        return Icons.bakery_dining_rounded;
      case 'rice 5kg':
      case 'frozen pizza':
        return Icons.rice_bowl_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Widget _buildHeader(int productCount) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1B8A3D), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHECKOUT',
                  style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Color(0xFF9AA1AA))),
              SizedBox(height: 6),
              Text('Your Order',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText)),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 18,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              const Center(
                  child: Icon(Icons.shopping_cart_outlined,
                      color: AppColors.brand, size: 24)),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$productCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredCustomerQuestion() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FCF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3EED8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_rounded,
                  color: AppColors.brand, size: 24),
              SizedBox(width: 10),
              Text(
                'Are you a registered Customer?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Yes',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  )),
                  selected: _isRegisteredCustomer,
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(
                      color: _isRegisteredCustomer
                          ? Colors.white
                          : AppColors.primaryText),
                  onSelected: (val) {
                    setState(() {
                      _isRegisteredCustomer = true;
                      _searchCustomerMessage = '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('No',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  )),
                  selected: !_isRegisteredCustomer,
                  selectedColor: AppColors.brand,
                  labelStyle: TextStyle(
                      color: !_isRegisteredCustomer
                          ? Colors.white
                          : AppColors.primaryText),
                  onSelected: (val) {
                    setState(() {
                      _isRegisteredCustomer = false;
                      _searchCustomerMessage = '';
                      _customerFound = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer_rounded,
                color: Color(0xFF1B8A3D), size: 20),
            SizedBox(width: 8),
            Text('Promotion / Coupon Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code (e.g. WEEKEND20)',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isApplyingPromo ? null : () => _applyPromo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: _isApplyingPromo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Apply',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white)),
            ),
          ],
        ),
        if (_promoMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _promoApplied
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _promoApplied
                      ? const Color(0xFFA5D6A7)
                      : const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                Icon(
                  _promoApplied
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 16,
                  color: _promoApplied ? AppColors.brand : AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _promoMessage,
                    style: TextStyle(
                      color: _promoApplied ? AppColors.brand : AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Active Available Coupons Chips
        StreamBuilder<List<PromotionModel>>(
          stream: KioskPromotionRepository.instance.getPromotionsStream(),
          builder: (context, snapshot) {
            final promos =
                snapshot.data ?? PromotionModel.fallbackPromotions;
            final promoWithCodes =
                promos.where((p) => p.couponCode.isNotEmpty).toList();

            if (promoWithCodes.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Offers (Tap to apply):',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: promoWithCodes.map((p) {
                    final isCurrent = _promoApplied &&
                        _promoController.text.trim().toUpperCase() ==
                            p.couponCode.toUpperCase();

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _applyPromo(p.couponCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFE8F5E9)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF1B8A3D)
                                : const Color(0xFFCBD5E1),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent
                                  ? Icons.check_circle_rounded
                                  : Icons.confirmation_number_outlined,
                              size: 14,
                              color: isCurrent
                                  ? const Color(0xFF1B8A3D)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              p.couponCode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrent
                                    ? const Color(0xFF1B8A3D)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9A825),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.discountDisplay,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderSummary(List<CartItem> items) {
    final subtotal = _subtotal(items);
    final discount = _discount(subtotal);
    final total = (subtotal - discount).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 28,
              offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Center(
              child: Text(
                'No items in cart.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            )
          else
            ...items.map((item) {
              final double unitPrice =
                  item.price > 0 ? item.price : _priceForTitle(item.title);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_iconForTitle(item.title),
                          color: AppColors.brand, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${_formattedPrice(unitPrice)} each',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 20, color: AppColors.brand),
                          onPressed: () => _decrementQuantity(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 20, color: AppColors.brand),
                          onPressed: () => _incrementQuantity(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.redAccent),
                          onPressed: () => _removeItem(item),
                          padding: const EdgeInsets.only(left: 6),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(_formattedPrice(_itemPrice(item)),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
          const Divider(height: 32, thickness: 1.1),
          _buildSummaryRow('Subtotal', _formattedPrice(subtotal)),
          const SizedBox(height: 12),
          _buildSummaryRow(
            _promoApplied
                ? 'Promo Discount (${_activePromotion?.name ?? "Applied"})'
                : 'Discount',
            discount > 0 ? '- ${_formattedPrice(discount)}' : 'Rs.0',
            color: discount > 0 ? AppColors.accent : Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Total', _formattedPrice(total),
              weight: FontWeight.w800),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? color, FontWeight weight = FontWeight.w600}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: weight),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                color: color ?? Colors.grey.shade800, fontWeight: weight)),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 28,
              offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegisteredCustomerQuestion(),
          const SizedBox(height: 24),
          const Text('Customer Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          _buildInputField(
            controller: _nameController,
            label: 'Enter your Name',
            hint: 'Mr.john doe',
            onChanged: (val) {
              final phone = _phoneController.text.trim();
              if (phone.isNotEmpty) {
                KioskOrderRepository.instance.saveOrUpdateCustomerProfile(
                  phone: phone,
                  name: val.trim(),
                  email: _emailController.text.trim(),
                  address: _addressController.text.trim(),
                );
              }
            },
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _phoneController,
                  label: 'Enter your Phone Number',
                  hint: '7xx xxx xxx',
                  keyboardType: TextInputType.phone,
                  onChanged: (val) {
                    final clean = val.replaceAll(RegExp(r'[^0-9+]'), '');
                    if (_isRegisteredCustomer && clean.length >= 9) {
                      _searchCustomerByPhone();
                    } else if (clean.length >= 9) {
                      KioskOrderRepository.instance.saveOrUpdateCustomerProfile(
                        phone: clean,
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        address: _addressController.text.trim(),
                      );
                    }
                  },
                ),
              ),
              if (_isRegisteredCustomer) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      _isSearchingCustomer ? null : _searchCustomerByPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  child: _isSearchingCustomer
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Find',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white)),
                ),
              ],
            ],
          ),
          if (_searchCustomerMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _searchCustomerMessage,
              style: TextStyle(
                color: _customerFound ? AppColors.brand : Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildInputField(
            controller: _addressController,
            label: 'Enter your Address here',
            hint: 'No. 123, Main Street, Colombo',
            onChanged: (val) {
              final phone = _phoneController.text.trim();
              if (phone.isNotEmpty) {
                KioskOrderRepository.instance.saveOrUpdateCustomerProfile(
                  phone: phone,
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  address: val.trim(),
                );
              }
            },
          ),
          const SizedBox(height: 18),
          _buildInputField(
            controller: _emailController,
            label: 'Enter your Gmail Address here',
            hint: '@gmail.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              final phone = _phoneController.text.trim();
              if (phone.isNotEmpty) {
                KioskOrderRepository.instance.saveOrUpdateCustomerProfile(
                  phone: phone,
                  name: _nameController.text.trim(),
                  email: val.trim(),
                  address: _addressController.text.trim(),
                );
              }
            },
          ),
          const SizedBox(height: 28),
          _buildPromotions(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: FutureBuilder<List<CartItem>>(
            future: _cartFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data ?? [];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(items.length),
                      const SizedBox(height: 22),
                      Expanded(
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: _buildLeftPanel(),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  SizedBox(
                                    width: 440,
                                    child: SingleChildScrollView(
                                      child: _buildOrderSummary(items),
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildLeftPanel(),
                                    const SizedBox(height: 20),
                                    _buildOrderSummary(items),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: items.isEmpty
                              ? null
                              : () {
                                  final sub = _subtotal(items);
                                  final disc = _discount(sub);
                                  const tx = 0.0;
                                  final nameInput =
                                      _nameController.text.trim();
                                  final phoneInput =
                                      _phoneController.text.trim();
                                  final addressInput =
                                      _addressController.text.trim();
                                  final emailInput =
                                      _emailController.text.trim();

                                  final cleanPhone = phoneInput.replaceAll(RegExp(r'[^0-9+]'), '');
                                  String custId = 'cust_kiosk';
                                  String custName = 'Kiosk Customer';

                                  if (cleanPhone.isNotEmpty) {
                                    custId = cleanPhone.startsWith('cust_')
                                        ? cleanPhone
                                        : 'cust_$cleanPhone';
                                    custName = nameInput.isNotEmpty
                                        ? nameInput
                                        : 'Customer ($cleanPhone)';

                                    // Save / update customer in Firestore `customers` collection
                                    KioskOrderRepository.instance.saveOrUpdateCustomerProfile(
                                      phone: cleanPhone,
                                      name: nameInput.isNotEmpty ? nameInput : custName,
                                      email: emailInput,
                                      address: addressInput,
                                    );
                                  } else if (nameInput.isNotEmpty) {
                                    custName = nameInput;
                                  }

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentMethodPage(
                                        items: items,
                                        subtotal: sub,
                                        discount: disc,
                                        tax: tx,
                                        itemCount: items.length,
                                        customerId: custId,
                                        customerName: custName,
                                        customerPhone: phoneInput,
                                        customerEmail: emailInput,
                                        customerAddress: addressInput,
                                        userName: 'Kiosk User',
                                      ),
                                    ),
                                  ).then((_) => _refreshCart());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Continue to Payment',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
