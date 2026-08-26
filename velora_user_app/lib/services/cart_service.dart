import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import 'cart_database.dart';

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._internal();

  CartService._internal() {
    loadCart();
  }

  List<CartItem> _items = [];
  bool _isLoading = true;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get total {
    return subtotal;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await CartDatabase.instance.getItems();
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String productId,
    required String category,
    required String title,
    required String description,
    required double price,
    int quantity = 1,
    String imageUrl = '',
  }) async {
    final newItem = CartItem(
      productId: productId,
      category: category,
      title: title,
      description: description,
      price: price,
      quantity: quantity,
      imageUrl: imageUrl,
    );

    await CartDatabase.instance.addOrIncrementItem(newItem);
    await loadCart();
  }

  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      if (item.id != null) {
        await CartDatabase.instance.deleteItem(item.id!);
      } else {
        _items.removeWhere((i) => i.title == item.title);
      }
    } else {
      final updated = item.copyWith(quantity: newQuantity);
      await CartDatabase.instance.updateItem(updated);
    }
    await loadCart();
  }

  Future<void> removeItem(CartItem item) async {
    if (item.id != null) {
      await CartDatabase.instance.deleteItem(item.id!);
    } else {
      _items.removeWhere((i) => i.title == item.title);
    }
    await loadCart();
  }

  Future<void> clearCart() async {
    await CartDatabase.instance.clearCart();
    await loadCart();
  }

  int getQuantityForProduct(String title) {
    final idx = _items.indexWhere((i) => i.title.toLowerCase() == title.toLowerCase());
    if (idx != -1) {
      return _items[idx].quantity;
    }
    return 0;
  }
}
