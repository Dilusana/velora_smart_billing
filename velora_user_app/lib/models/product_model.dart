import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String categoryId;
  final double price;
  final double? originalPrice;
  final int stock;
  final String imageUrl;
  final String unit;
  final String status;
  final bool isFeatured;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.categoryId = '',
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.imageUrl,
    this.unit = '1 kg',
    required this.status,
    this.isFeatured = false,
  });

  bool get isActive {
    final s = status.trim().toLowerCase();
    if (s == 'inactive' || s == 'disabled' || s == 'false' || s == '0' || s == 'out_of_stock' || s == 'unavailable') {
      return false;
    }
    return true;
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 100;
      return 100;
    }

    final dynamic rawPrice = data['price'] ??
        data['unitPrice'] ??
        data['sellingPrice'] ??
        data['mrp'] ??
        data['rate'] ??
        data['amount'] ??
        data['cost'];
    final double priceVal = parseDouble(rawPrice);

    final dynamic rawOrigPrice = data['originalPrice'] ?? data['oldPrice'] ?? data['regularPrice'];
    final double? origPriceVal = rawOrigPrice != null ? parseDouble(rawOrigPrice) : null;

    final dynamic rawStatus = data['status'] ?? data['active'] ?? data['isAvailable'] ?? data['available'];
    String statusStr = 'active';
    if (rawStatus != null) {
      if (rawStatus is bool) {
        statusStr = rawStatus ? 'active' : 'inactive';
      } else {
        statusStr = rawStatus.toString();
      }
    }

    final dynamic rawStock = data['stock'] ??
        data['quantity'] ??
        data['qty'] ??
        data['count'] ??
        data['stockCount'] ??
        data['inStock'] ??
        data['availableQuantity'];

    final dynamic rawImage = data['imageUrl'] ??
        data['image'] ??
        data['image_url'] ??
        data['img'] ??
        data['photo'] ??
        data['photoUrl'] ??
        data['picture'];

    final String rawCat = (data['category'] ?? data['categoryName'] ?? data['category_name'] ?? data['cat'] ?? data['type'] ?? 'General').toString();
    final String rawCatId = (data['categoryId'] ?? data['category_id'] ?? data['category'] ?? '').toString();

    return ProductModel(
      id: doc.id,
      name: (data['name'] ?? data['title'] ?? data['productName'] ?? data['item_name'] ?? data['label'] ?? 'Unnamed Product').toString(),
      description: (data['description'] ?? data['details'] ?? data['desc'] ?? data['info'] ?? '').toString(),
      category: rawCat,
      categoryId: rawCatId,
      price: priceVal,
      originalPrice: (origPriceVal != null && origPriceVal > priceVal) ? origPriceVal : null,
      stock: parseInt(rawStock),
      imageUrl: (rawImage ?? '').toString(),
      unit: (data['unit'] ?? data['weight'] ?? data['size'] ?? data['pack'] ?? '1 unit').toString(),
      status: statusStr,
      isFeatured: data['isFeatured'] == true || data['featured'] == true || data['is_featured'] == true || data['isRecommended'] == true,
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
      'originalPrice': originalPrice,
      'stock': stock,
      'imageUrl': imageUrl,
      'unit': unit,
      'status': status,
      'isFeatured': isFeatured,
    };
  }
}
