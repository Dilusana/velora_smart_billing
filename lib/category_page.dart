import 'package:flutter/material.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';

/// Product-style detail view for items in a category.
class CategoryPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final List<CartItem> _items;
  late CartItem _selected;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _items = _itemsForCategory(widget.category);
    _selected = _items.first;
  }

  Future<void> _addToCart() async {
    final toAdd = _selected.copyWith(quantity: _quantity);
    await CartDatabase.instance.addOrIncrementItem(toAdd);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${toAdd.title} added — ${toAdd.quantity}')),
    );
  }

  static List<CartItem> _itemsForCategory(CategoryItem category) {
    // Small sample catalog per category; replace with real data later.
    switch (category.title) {
      case 'Vegetables & Fruits':
        return [
          CartItem(category: category.title, title: 'Bananas', description: '1 bunch', quantity: 1),
          CartItem(category: category.title, title: 'Red Apples', description: '4 pieces', quantity: 1),
          CartItem(category: category.title, title: 'Fresh Spinach', description: '250g bag', quantity: 1),
        ];
      case 'Grocery':
        return [
          CartItem(category: category.title, title: 'Whole Wheat Bread', description: '1 loaf', quantity: 1),
          CartItem(category: category.title, title: 'Rice 5kg', description: 'Long grain rice', quantity: 1),
          CartItem(category: category.title, title: 'Salt & Spices', description: 'Assorted pack', quantity: 1),
        ];
      default:
        return [
          CartItem(category: category.title, title: '${category.title} Item', description: 'Popular item', quantity: 1),
        ];
    }
  }

  Widget _buildGallery() {
    return Column(
      children: [
        // Large image area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFF4F7FA),
            ),
            child: Center(
              child: Icon(Icons.image, size: 160, color: Colors.grey.shade400),
            ),
          ),
        ),
        // Thumbnails
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final it = _items[index];
              final selected = it.title == _selected.title;
              return GestureDetector(
                onTap: () => setState(() => _selected = it),
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? const Color(0xFFEFF7F4) : Colors.white,
                    border: Border.all(color: selected ? const Color(0xFF1B8A3D) : const Color(0xFFF0F0F0)),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, color: Color(0xFF1B8A3D), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        it.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B8A3D), size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(widget.category.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: IconButton(
                      onPressed: () => {},
                      icon: const Icon(Icons.search_rounded, color: Color(0xFF1B8A3D)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Left: Gallery
                    Expanded(flex: 6, child: _buildGallery()),

                    const SizedBox(width: 18),

                    // Right: Details
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('\$27.00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0FA861))),
                              const SizedBox(width: 10),
                              Text('\u0336\$30.00\u0336', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(8)),
                                child: const Text('10% OFF', style: TextStyle(color: Color(0xFFB00020), fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF0FA861), size: 18),
                              const SizedBox(width: 8),
                              Text('In Stock', style: TextStyle(color: Colors.green.shade700)),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Quantity + subtotal
                          Row(
                            children: [
                              const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color.fromRGBO(0,0,0,0.04), blurRadius: 6, offset: Offset(0,4))]),
                                child: Row(
                                  children: [
                                    IconButton(onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99)), icon: const Icon(Icons.remove_rounded)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    ),
                                    IconButton(onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99)), icon: const Icon(Icons.add_rounded)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text('\$${(27.00 * _quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0FA861))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Add to cart / Buy now
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF1B8A3D)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Buy Now', style: TextStyle(color: Color(0xFF1B8A3D), fontWeight: FontWeight.w800)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _addToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0FA861),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: Text('Add to Cart | \$${(27.00 * _quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Text('About this product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(_selected.description, style: TextStyle(color: Colors.grey.shade700)),

                          const SizedBox(height: 18),
                          // Details row: nutrition / product details / expiry
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text('Nutritional Information', style: TextStyle(fontWeight: FontWeight.w800)),
                                          SizedBox(height: 8),
                                          Text('Energy 61 kcal'),
                                          Text('Protein 3.1 g'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text('Product Details', style: TextStyle(fontWeight: FontWeight.w800)),
                                          SizedBox(height: 8),
                                          Text('Net Quantity: 500 ml'),
                                          Text('Processing: Homogenised'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text('Storage', style: TextStyle(fontWeight: FontWeight.w800)),
                                          SizedBox(height: 8),
                                          Text('Keep refrigerated at 4°C or below'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
