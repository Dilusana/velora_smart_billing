import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'cart_database.dart';
import 'cart_item.dart';
import 'payment_method_page.dart';

enum DeliveryType { selfCheckout, storePickup }

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  late Future<List<CartItem>> _cartFuture;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _membershipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DeliveryType _deliveryType = DeliveryType.selfCheckout;
  bool _promoApplied = false;
  String _promoMessage = '';

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _membershipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _refreshCart() {
    setState(() {
      _cartFuture = CartDatabase.instance.getItems();
    });
  }

  Future<void> _removeItem(int id) async {
    await CartDatabase.instance.deleteItem(id);
    _refreshCart();
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    final clamped = quantity.clamp(1, 99);
    final updated = item.copyWith(quantity: clamped);
    await CartDatabase.instance.updateItem(updated);
    _refreshCart();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'SAVE5' || code == 'KIOSK5') {
      setState(() {
        _promoApplied = true;
        _promoMessage = 'Promo code applied successfully';
      });
    } else {
      setState(() {
        _promoApplied = false;
        _promoMessage = 'Invalid promo code';
      });
    }
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
      case 'Salt & Spices':
        return 4.10;
      case 'Sparkling Water':
        return 1.90;
      case 'Cold Brew Coffee':
        return 3.80;
      case 'Orange Juice':
        return 2.20;
      case 'Herbal Tea':
        return 2.80;
      case 'Laundry Detergent':
        return 9.50;
      case 'Dish Soap':
        return 2.40;
      case 'Floor Cleaner':
        return 3.90;
      case 'Paper Towels':
        return 4.75;
      case 'Greek Yogurt':
        return 3.20;
      case 'Cheddar Cheese':
        return 4.90;
      case 'Fresh Cream':
        return 3.60;
      case 'Ready Meal Bowl':
        return 6.50;
      case 'Frozen Peas':
        return 2.70;
      case 'Ice Cream Tub':
        return 5.20;
      case 'Vegetable Mix':
        return 3.30;
      case 'Frozen Pizza':
        return 7.80;
      default:
        return 2.50;
    }
  }

  double _itemPrice(CartItem item) {
    return _priceForTitle(item.title) * item.quantity;
  }

  double _subtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + _itemPrice(item));
  }

  double _promoDiscount() {
    return _promoApplied ? 2.50 : 0.0;
  }

  double _discount(double subtotal) {
    return subtotal * 0.08 + _promoDiscount();
  }

  double _deliveryFee() {
    return 0.0;
  }

  double _total(double subtotal) {
    final total = subtotal - _discount(subtotal) + _deliveryFee();
    return total.clamp(0.0, double.infinity);
  }

  String _formattedPrice(double value) {
    return 'Rs.${value.toStringAsFixed(0)}';
  }

  IconData _iconForTitle(String title) {
    switch (title) {
      case 'Bananas':
      case 'Fresh Spinach':
      case 'Red Apples':
      case 'Vegetable Mix':
        return Icons.eco_rounded;
      case 'Whole Wheat Bread':
      case 'Bread':
        return Icons.bakery_dining_rounded;
      case 'Rice 5kg':
      case 'Frozen Pizza':
        return Icons.rice_bowl_rounded;
      case 'Orange Juice':
      case 'Sparkling Water':
      case 'Cold Brew Coffee':
      case 'Herbal Tea':
      case 'Greek Yogurt':
      case 'Fresh Cream':
        return Icons.local_drink_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Widget _buildQuantityControl(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _updateQuantity(item, item.quantity - 1),
            icon: const Icon(Icons.remove_rounded, size: 18),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => _updateQuantity(item, item.quantity + 1),
            icon: const Icon(Icons.add_rounded, size: 18),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
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
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B8A3D), size: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('CHECKOUT', style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Color(0xFF9AA1AA))),
              SizedBox(height: 6),
              Text('Your Order', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
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
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              const Center(child: Icon(Icons.shopping_cart_outlined, color: AppColors.brand, size: 24)),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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

  Widget _buildProductCard(CartItem item) {
    return Dismissible(
      key: ValueKey(item.id ?? item.title),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        if (item.id != null) {
          _removeItem(item.id!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF7F4), Color(0xFFD9F0E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(_iconForTitle(item.title), color: AppColors.brand, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _productSubtitle(item.title),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formattedPrice(_priceForTitle(item.title)),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brand),
                      ),
                      const Spacer(),
                      _buildQuantityControl(item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _productSubtitle(String title) {
    switch (title) {
      case 'Bananas':
      case 'Fresh Spinach':
      case 'Red Apples':
      case 'Vegetable Mix':
        return 'Fresh produce';
      case 'Whole Wheat Bread':
        return 'Bakery';
      case 'Rice 5kg':
      case 'Frozen Pizza':
        return 'Grains';
      case 'Orange Juice':
      case 'Sparkling Water':
      case 'Cold Brew Coffee':
      case 'Herbal Tea':
        return 'Beverages';
      case 'Greek Yogurt':
      case 'Fresh Cream':
        return 'Dairy';
      default:
        return 'Grocery item';
    }
  }

  Widget _buildDeliveryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF7F4) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accent : const Color(0xFFE8EFE6), width: 1.2),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent.withOpacity(0.12) : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: selected ? AppColors.accent : AppColors.brand, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: selected ? AppColors.brand : AppColors.primaryText)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.accent : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Promo Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  hintText: 'Enter code',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _applyPromo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _promoMessage,
          style: TextStyle(
            color: _promoApplied ? AppColors.accent : AppColors.error,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(List<CartItem> items) {
    final subtotal = _subtotal(items);
    final discount = _discount(subtotal);
    final tax = subtotal * 0.08;
    final total = subtotal - discount + tax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 28, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Center(
              child: Text(
                'No items in cart.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            )
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(_iconForTitle(item.title), color: AppColors.brand, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('x${item.quantity} unit', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(_formattedPrice(_itemPrice(item)), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
          const Divider(height: 32, thickness: 1.1),
          _buildSummaryRow('Subtotal', _formattedPrice(subtotal)),
          const SizedBox(height: 12),
          _buildSummaryRow('Discount (Member)', '- ${_formattedPrice(discount)}', color: AppColors.accent),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax', _formattedPrice(tax), color: AppColors.brand),
          const SizedBox(height: 12),
          _buildSummaryRow('Total', _formattedPrice(total), weight: FontWeight.w800),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, FontWeight weight = FontWeight.w600}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: weight)),
        Text(value, style: TextStyle(color: color ?? Colors.grey.shade800, fontWeight: weight)),
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
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 28, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildDeliveryOption(
                icon: Icons.shopping_bag_rounded,
                title: 'Self Checkout',
                subtitle: 'Bag your items at the station',
                selected: _deliveryType == DeliveryType.selfCheckout,
                onTap: () => setState(() => _deliveryType = DeliveryType.selfCheckout),
              ),
              const SizedBox(width: 16),
              _buildDeliveryOption(
                icon: Icons.storefront_rounded,
                title: 'Store Pickup',
                subtitle: 'Ready in 15 minutes',
                selected: _deliveryType == DeliveryType.storePickup,
                onTap: () => setState(() => _deliveryType = DeliveryType.storePickup),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Customer Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          _buildInputField(controller: _membershipController, label: 'Membership Number (Optional)', hint: 'Membership Number (Optional)'),
          const SizedBox(height: 18),
          _buildInputField(controller: _phoneController, label: 'Phone Number (Optional)', hint: 'Phone Number (Optional)', keyboardType: TextInputType.phone),
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
                                    width: 420,
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
                                  final tx = sub * 0.08;
                                  final phone = _phoneController.text.trim();
                                  final membership = _membershipController.text.trim();

                                  String? custId;
                                  String? custName;
                                  if (membership.isNotEmpty) {
                                    custId = 'cust_$membership';
                                    custName = 'Member $membership';
                                  } else if (phone.isNotEmpty) {
                                    custId = 'cust_$phone';
                                    custName = 'Customer ($phone)';
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
                                        userName: 'Kiosk User',
                                      ),
                                    ),
                                  ).then((_) => _refreshCart());
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Continue to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _buildItemsSection(List<CartItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Your cart is empty.',
          style: TextStyle(fontSize: 18, color: Color(0xFF5A5F6B)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 28, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${items.length} products', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => _buildProductCard(items[index]),
            ),
          ),
        ],
      ),
    );
  }
}
