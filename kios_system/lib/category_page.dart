import 'package:flutter/material.dart';
import 'app_theme.dart';

import 'cart_database.dart';
import 'cart_item.dart';
import 'category.dart';
import 'product_model.dart';
import 'product_repository.dart';
import 'my_cart_page.dart';

/// Product-style detail view for items in a category.
class CategoryPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  ProductModel? _selectedProduct;
  int _quantity = 1;

  Future<void> _addToCart() async {
    if (_selectedProduct == null) return;
    final item = CartItem(
      productId: _selectedProduct!.id,
      category: widget.category.title,
      title: _selectedProduct!.name,
      description: _selectedProduct!.description,
      price: _selectedProduct!.price,
      quantity: _quantity,
    );
    await CartDatabase.instance.addOrIncrementItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} added — ${item.quantity}')),
    );
  }

  Widget _buildGallery(List<ProductModel> products) {
    final current = _selectedProduct ?? (products.isNotEmpty ? products.first : null);

    return Column(
      children: [
        // Large image area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.secondaryBackground,
            ),
            child: Center(
              child: current != null && current.isWebImage
                  ? Image.network(
                      current.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image, size: 160, color: Colors.grey.shade400),
                    )
                  : current != null && current.isAssetImage
                      ? Image.asset(
                          current.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 160, color: Colors.grey.shade400),
                        )
                      : Icon(Icons.image, size: 160, color: Colors.grey.shade400),
            ),
          ),
        ),
        // Thumbnails
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final it = products[index];
              final selected = current != null && it.id == current.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedProduct = it;
                  _quantity = 1;
                }),
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? const Color(0xFFEFF7F4) : Colors.white,
                    border: Border.all(color: selected ? AppColors.brand : AppColors.divider),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      it.isWebImage
                          ? Image.network(it.imageUrl, width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_rounded, color: AppColors.brand, size: 28))
                          : const Icon(Icons.shopping_bag_rounded, color: AppColors.brand, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        it.name,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: StreamBuilder<List<ProductModel>>(
            stream: KioskProductRepository.instance.getProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.brand));
              }

              final all = snapshot.data ?? [];
              final products = all.where((p) => KioskProductRepository.instance.productMatchesCategory(p, widget.category.title)).toList();

              if (products.isEmpty) {
                return Column(
                  children: [
                    _buildHeader(context),
                    const Expanded(
                      child: Center(
                        child: Text('No products available in this category.'),
                      ),
                    ),
                  ],
                );
              }

              final selected = _selectedProduct ?? products.first;
              final subtotal = selected.price * _quantity;

              return Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 6, child: _buildGallery(products)),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selected.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Rs.${selected.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: selected.stock > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFF1F1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      selected.stock > 0 ? 'In Stock (${selected.stock})' : 'Out of Stock',
                                      style: TextStyle(
                                        color: selected.stock > 0 ? AppColors.brand : const Color(0xFFB00020),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [BoxShadow(color: Color.fromRGBO(0,0,0,0.04), blurRadius: 6, offset: Offset(0,4))],
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => setState(() => _quantity = (_quantity - 1).clamp(1, selected.stock > 0 ? selected.stock : 99)),
                                          icon: const Icon(Icons.remove_rounded),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                        ),
                                        IconButton(
                                          onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, selected.stock > 0 ? selected.stock : 99)),
                                          icon: const Icon(Icons.add_rounded),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      Text('Rs.${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.accent)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyCartPage())),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.brand),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text('View Cart', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: selected.stock > 0 ? () async {
                                        setState(() {
                                          _selectedProduct = selected;
                                        });
                                        await _addToCart();
                                      } : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: Text('Add to Cart | Rs.${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text('About this product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                selected.description.isNotEmpty ? selected.description : 'No product description.',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.brand, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(widget.category.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
