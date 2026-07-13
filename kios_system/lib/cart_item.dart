class CartItem {
  final int? id;
  final String category;
  final String title;
  final String description;
  final int quantity;

  CartItem({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.quantity = 1,
  });

  CartItem copyWith({
    int? id,
    String? category,
    String? title,
    String? description,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'title': title,
      'description': description,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      category: map['category'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      quantity: map['quantity'] as int,
    );
  }
}
