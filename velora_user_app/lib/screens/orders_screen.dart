import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import '../models/order_model.dart';
import 'order_receipt_screen.dart';
import 'order_tracker_screen.dart';


// ─── Order Model ──────────────────────────────────────────────────────────────

enum OrderStatus { processing, completed, cancelled }

class OrderLineItem {
  final String name;
  final String unit;
  final double price;
  final int qty;
  final String? imagePath;
  final IconData fallbackIcon;

  const OrderLineItem({
    required this.name,
    required this.unit,
    required this.price,
    this.qty = 1,
    this.imagePath,
    required this.fallbackIcon,
  });
}

class Order {
  final String id;
  final String date;
  final OrderStatus status;
  final List<OrderLineItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final String paymentMethod;
  final String deliveryAddress;

  const Order({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.paymentMethod,
    required this.deliveryAddress,
  });

  double get total => subtotal + tax - discount;
  int get itemCount => items.fold(0, (s, i) => s + i.qty);
}

// ─── Demo Orders ──────────────────────────────────────────────────────────────

final List<Order> demoOrders = [
  Order(
    id: 'ORD-8825',
    date: 'Oct 26, 2023',
    status: OrderStatus.completed,
    subtotal: 16.20,
    tax: 1.30,
    discount: 1.00,
    paymentMethod: 'Visa ending in 4542',
    deliveryAddress: '123 Green Lane, Freshville',
    items: const [
      OrderLineItem(
        name: 'Organic Hass Avocados',
        unit: '2 units • \$2.25/u',
        price: 4.50,
        qty: 2,
        imagePath: 'assests/veg_fruits.png',
        fallbackIcon: Icons.eco_rounded,
      ),
      OrderLineItem(
        name: 'Artisanal Sourdough',
        unit: '1 unit',
        price: 6.20,
        imagePath: 'assests/sourdough_product.jpg',
        fallbackIcon: Icons.breakfast_dining_rounded,
      ),
      OrderLineItem(
        name: 'Cold-Pressed Almond Milk',
        unit: '1 unit',
        price: 6.00,
        imagePath: 'assests/milk_product.jpg',
        fallbackIcon: Icons.local_drink_rounded,
      ),
    ],
  ),
  Order(
    id: 'ORD-3012',
    date: 'Nov 3, 2023',
    status: OrderStatus.processing,
    subtotal: 18.90,
    tax: 0.00,
    discount: 0.00,
    paymentMethod: 'Mastercard ending in 7781',
    deliveryAddress: '45 Market Street, Greentown',
    items: const [
      OrderLineItem(
        name: 'Baby Spinach',
        unit: '250g bag',
        price: 3.25,
        imagePath: 'assests/spinach_product.jpg',
        fallbackIcon: Icons.eco_rounded,
      ),
      OrderLineItem(
        name: 'Greek Yogurt',
        unit: '400g pot',
        price: 3.80,
        imagePath: 'assests/yogurt_product.jpg',
        fallbackIcon: Icons.icecream_rounded,
      ),
      OrderLineItem(
        name: 'Farm Eggs',
        unit: 'Dozen',
        price: 5.99,
        imagePath: 'assests/eggs_product.jpg',
        fallbackIcon: Icons.egg_rounded,
      ),
      OrderLineItem(
        name: 'Cherry Tomatoes',
        unit: '500g punnet',
        price: 2.75,
        qty: 2,
        imagePath: 'assests/tomatoes_product.jpg',
        fallbackIcon: Icons.eco_rounded,
      ),
    ],
  ),
  Order(
    id: 'ORD-7741',
    date: 'Oct 15, 2023',
    status: OrderStatus.cancelled,
    subtotal: 7.25,
    paymentMethod: 'Visa ending in 4542',
    deliveryAddress: '123 Green Lane, Freshville',
    items: const [
      OrderLineItem(
        name: 'Wildflower Honey',
        unit: '500ml jar',
        price: 7.25,
        imagePath: 'assests/honey_product.jpg',
        fallbackIcon: Icons.local_drink_rounded,
      ),
    ],
  ),
];

// ─── Order History Screen ─────────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedFilter = 0; // 0=All, 1=Processing, 2=Complete, 3=Cancelled
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  static const _filters = ['All', 'Processing', 'Complete', 'Cancelled'];

  List<Order> _getFilteredOrders(List<Order> sourceList) {
    var list = sourceList;
    if (_selectedFilter == 1) list = list.where((o) => o.status == OrderStatus.processing).toList();
    if (_selectedFilter == 2) list = list.where((o) => o.status == OrderStatus.completed).toList();
    if (_selectedFilter == 3) list = list.where((o) => o.status == OrderStatus.cancelled).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) => o.id.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Order _mapUserOrder(UserOrderModel firestoreOrder) {
    OrderStatus status = OrderStatus.processing;
    final st = firestoreOrder.status.toLowerCase();
    if (st.contains('completed') || st.contains('delivered')) {
      status = OrderStatus.completed;
    } else if (st.contains('cancel')) {
      status = OrderStatus.cancelled;
    }

    String formattedDate = 'Just Now';
    if (firestoreOrder.createdAt != null) {
      final d = firestoreOrder.createdAt!;
      formattedDate = '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }

    final items = firestoreOrder.items.map((i) => OrderLineItem(
      name: i.productName,
      unit: '${i.quantity} x Rs ${i.price.toStringAsFixed(2)}',
      price: i.price,
      qty: i.quantity,
      fallbackIcon: Icons.shopping_basket_rounded,
    )).toList();

    return Order(
      id: firestoreOrder.id,
      date: formattedDate,
      status: status,
      subtotal: firestoreOrder.subtotal,
      tax: 0.0,
      discount: firestoreOrder.discount,
      paymentMethod: firestoreOrder.paymentMethod,
      deliveryAddress: firestoreOrder.deliveryAddress,
      items: items,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserOrderModel>>(
      stream: OrderRepository.instance.getCustomerOrdersStream(UserRepository.defaultUserId),
      builder: (context, snapshot) {
        List<Order> allOrders = [];
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          allOrders = snapshot.data!.map(_mapUserOrder).toList();
        } else {
          allOrders = demoOrders;
        }

        final filtered = _getFilteredOrders(allOrders);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F3EB),
          body: SafeArea(
            child: CustomScrollView(

          slivers: [
            // ── App Bar ─────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: const Color(0xFFF5F3EB),
              elevation: 0,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 60,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.search_rounded, color: Color(0xFF3A5A2A), size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('SmartMarket', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF3A5A2A))),
                    const Spacer(),
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFCEE847), Color(0xFF8DC63F)]),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF1A2D5A), size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text('Order History',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
              ),
            ),

            // ── Search ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF374151)),
                    decoration: InputDecoration(
                      hintText: 'Search by order ID or product…',
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Chips ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final isSelected = _selectedFilter == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3A5A2A) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Text(_filters[i],
                            style: GoogleFonts.outfit(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF374151),
                            )),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // ── Order Cards ───────────────────────────────────────────────
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 60, color: const Color(0xFF3A5A2A).withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No orders found', style: GoogleFonts.outfit(fontSize: 16, color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _OrderCard(order: filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  },
);
  }

}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color get _statusBg => switch (order.status) {
    OrderStatus.completed => const Color(0xFFDCFCE7),
    OrderStatus.processing => const Color(0xFFFEF9C3),
    OrderStatus.cancelled => const Color(0xFFFEE2E2),
  };

  Color get _statusColor => switch (order.status) {
    OrderStatus.completed => const Color(0xFF16A34A),
    OrderStatus.processing => const Color(0xFFA16207),
    OrderStatus.cancelled => const Color(0xFFDC2626),
  };

  String get _statusLabel => switch (order.status) {
    OrderStatus.completed => 'Completed',
    OrderStatus.processing => 'Processing',
    OrderStatus.cancelled => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: order ID + status badge ──────────────────────────
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.date,
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w400)),
                  const SizedBox(height: 2),
                  Text('#${order.id}',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel,
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Thumbnails + item count + price ───────────────────────────
          Row(
            children: [
              // Overlapping thumbnails
              SizedBox(
                height: 38,
                width: (order.items.length.clamp(1, 3) * 28.0) + 10,
                child: Stack(
                  children: order.items.take(3).toList().asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return Positioned(
                      left: idx * 22.0,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: const Color(0xFFF0F5D8),
                        ),
                        child: ClipOval(
                          child: item.imagePath != null
                              ? Image.asset(item.imagePath!, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(item.fallbackIcon, size: 18, color: const Color(0xFF3A5A2A)))
                              : Icon(item.fallbackIcon, size: 18, color: const Color(0xFF3A5A2A)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${order.itemCount} Item${order.itemCount == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                  Text('Rs ${order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: const Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 12),

          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              if (order.status == OrderStatus.completed)
                Expanded(
                  child: _OutlineBtn(
                    label: 'View Receipt',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => Navigator.of(context).push(
                      _slideRoute(OrderReceiptScreen(order: order)),
                    ),
                  ),
                ),
              if (order.status == OrderStatus.processing)
                Expanded(
                  child: _OutlineBtn(
                    label: 'Track Order',
                    icon: Icons.location_on_rounded,
                    onTap: () => Navigator.of(context).push(
                      _slideRoute(OrderTrackerScreen(order: order)),
                    ),
                  ),
                ),
              if (order.status != OrderStatus.cancelled)
                const SizedBox(width: 10),
              Expanded(
                child: _FilledBtn(
                  label: 'Reorder',
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Items from #${order.id} added to cart!',
                          style: GoogleFonts.outfit(color: Colors.white)),
                        backgroundColor: const Color(0xFF3A5A2A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => page,
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );
}

// ─── Shared Button Widgets ────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A5A2A), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF3A5A2A)),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF3A5A2A))),
          ],
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFCEE847),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFFCEE847).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF1A2D5A)),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
          ],
        ),
      ),
    );
  }
}
