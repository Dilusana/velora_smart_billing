class CartItem {
  final int? id;
  final String productId;
  final String category;
  final String title;
  final String description;
  final double price;
  final int quantity;

  CartItem({
    this.id,
    this.productId = '',
    required this.category,
    required this.title,
    required this.description,
    this.price = 0.0,
    this.quantity = 1,
  });

  CartItem copyWith({
    int? id,
    String? productId,
    String? category,
    String? title,
    String? description,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      productId: (map['productId'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
