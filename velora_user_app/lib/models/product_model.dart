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
  final DateTime? expiryDate;

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
    this.expiryDate,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return target.isBefore(today);
  }

  bool get isActive {
    if (isExpired) return false;
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

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final clean = value.trim();
        if (clean.isEmpty || clean == '—' || clean == '-' || clean.toLowerCase() == 'n/a') return null;
        final iso = DateTime.tryParse(clean);
        if (iso != null) return iso;
        final dmyMatch = RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$').firstMatch(clean);
        if (dmyMatch != null) {
          final p1 = int.tryParse(dmyMatch.group(1)!);
          final p2 = int.tryParse(dmyMatch.group(2)!);
          var yr = int.tryParse(dmyMatch.group(3)!);
          if (yr != null && yr < 100) yr += 2000;
          if (p1 != null && p2 != null && yr != null) {
            if (p2 <= 12 && p1 <= 31) return DateTime(yr, p2, p1);
            if (p1 <= 12 && p2 <= 31) return DateTime(yr, p1, p2);
          }
        }
      }
      return null;
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

    final dynamic rawExpiry = data['expiryDate'] ??
        data['expiry_date'] ??
        data['expiry'] ??
        data['expirationDate'] ??
        data['expDate'];
    final DateTime? expiryDateVal = parseDate(rawExpiry);

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
      expiryDate: expiryDateVal,
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
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }
}
