import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is Timestamp) return val.toDate();
  return DateTime.tryParse(val.toString());
}

double _parsePrice(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}

int _parseStock(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? 0;
  }
  return 0;
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String categoryId;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String sku;
  final double cost;
  final String unit;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId = '',
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.sku = '',
    this.cost = 0.0,
    this.unit = '',
  });

  bool get isActive => status.isEmpty || status.toLowerCase() == 'active';
  bool get isWebImage => imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
  bool get isAssetImage => imageUrl.isNotEmpty && imageUrl.startsWith('assets/');

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromMap(data, docId: doc.id);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final catName = (map['category'] ??
            map['categoryName'] ??
            map['category_name'] ??
            map['categoryTitle'] ??
            map['category_title'] ??
            '')
        .toString();
    final catId = (map['categoryId'] ??
            map['category_id'] ??
            map['parent_category_id'] ??
            '')
        .toString();

    return ProductModel(
      id: docId ?? (map['id']?.toString() ?? ''),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      description: (map['description'] ?? map['subtitle'] ?? '').toString(),
      category: catName.isNotEmpty ? catName : catId,
      categoryId: catId,
      price: _parsePrice(map['price'] ?? map['sellingPrice'] ?? map['retail_price'] ?? map['unit_price']),
      stock: _parseStock(map['stock'] ?? map['quantity'] ?? map['stock_quantity']),
      imageUrl: (map['imageUrl'] ?? map['image'] ?? map['imageAsset'] ?? map['image_url'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['updated_at']),
      sku: (map['sku'] ?? '').toString(),
      cost: _parsePrice(map['cost']),
      unit: (map['unit'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'sku': sku,
      'cost': cost,
      'unit': unit,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? categoryId,
    double? price,
    int? stock,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sku,
    double? cost,
    String? unit,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sku: sku ?? this.sku,
      cost: cost ?? this.cost,
      unit: unit ?? this.unit,
    );
  }
}
