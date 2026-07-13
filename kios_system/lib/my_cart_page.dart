import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';

class MyCartPage extends StatefulWidget {
  const MyCartPage({super.key});

  @override
  State<MyCartPage> createState() => _MyCartPageState();
}

class _MyCartPageState extends State<MyCartPage> {
  late Future<List<CartItem>> _cartFuture;
  final TextEditingController _promoController = TextEditingController();
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
    return '\$${value.toStringAsFixed(2)}';
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
              Text('Your Order', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1B1B1B))),
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
              const Center(child: Icon(Icons.shopping_cart_outlined, color: Color(0xFF1B8A3D), size: 24)),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0FA861),
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
              child: Icon(_iconForTitle(item.title), color: const Color(0xFF1B8A3D), size: 36),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B8A3D)),
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

  Widget _buildSummaryPanel(List<CartItem> items) {
    final subtotal = _subtotal(items);
    final discount = _discount(subtotal);
    final total = _total(subtotal);

    return Container(
      margin: const EdgeInsets.only(top: 16),
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
          const Row(
            children: [
              Icon(Icons.local_offer_outlined, color: Color(0xFF1B8A3D), size: 20),
              SizedBox(width: 10),
              Text('Add promo code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A3D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(_promoMessage, style: TextStyle(color: _promoApplied ? const Color(0xFF0FA861) : Colors.red.shade400)),
          const Divider(height: 32, thickness: 1.1),
          _buildSummaryLine('Subtotal', _formattedPrice(subtotal)),
          const SizedBox(height: 12),
          _buildSummaryLine('Discount', '- ${_formattedPrice(discount)}', color: const Color(0xFF0FA861)),
          const SizedBox(height: 12),
          _buildSummaryLine('Delivery', 'Free', color: const Color(0xFF1B8A3D)),
          const Divider(height: 32, thickness: 1.1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(_formattedPrice(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FA861),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: TextStyle(color: color ?? Colors.grey.shade800, fontWeight: FontWeight.w600)),
      ],
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
                                  Expanded(child: _buildItemsSection(items)),
                                  const SizedBox(width: 24),
                                  SizedBox(width: 380, child: _buildSummaryPanel(items)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildItemsSection(items),
                                  _buildSummaryPanel(items),
                                ],
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
