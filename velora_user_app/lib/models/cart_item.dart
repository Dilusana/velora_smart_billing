class CartItem {
  final int? id;
  final String productId;
  final String category;
  final String title;
  final String description;
  final double price;
  final int quantity;
  final String imageUrl;

  const CartItem({
    this.id,
    required this.productId,
    required this.category,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
  });

  CartItem copyWith({
    int? id,
    String? productId,
    String? category,
    String? title,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'productId': productId,
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] is int ? map['id'] as int : null,
      productId: (map['productId'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      title: (map['title'] ?? map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: map['price'] is num ? (map['price'] as num).toDouble() : 0.0,
      quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 1,
      imageUrl: (map['imageUrl'] ?? map['image'] ?? '').toString(),
    );
  }
}
