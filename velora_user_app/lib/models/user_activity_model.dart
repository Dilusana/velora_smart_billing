import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  productView,
  addToCart,
  removeFromCart,
  purchase,
  search,
  categoryView,
}

class UserActivity {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String categoryId;
  final String categoryName;
  final ActivityType activityType;
  final DateTime timestamp;

  const UserActivity({
    required this.id,
    required this.userId,
    this.productId = '',
    this.productName = '',
    this.categoryId = '',
    this.categoryName = '',
    required this.activityType,
    required this.timestamp,
  });

  static ActivityType parseActivityType(String value) {
    final v = value.trim().toUpperCase();
    switch (v) {
      case 'PRODUCT_VIEW':
      case 'PRODUCTVIEW':
        return ActivityType.productView;
      case 'ADD_TO_CART':
      case 'ADDTOCART':
        return ActivityType.addToCart;
      case 'REMOVE_FROM_CART':
      case 'REMOVEFROMCART':
        return ActivityType.removeFromCart;
      case 'PURCHASE':
        return ActivityType.purchase;
      case 'SEARCH':
        return ActivityType.search;
      case 'CATEGORY_VIEW':
      case 'CATEGORYVIEW':
        return ActivityType.categoryView;
      default:
        return ActivityType.productView;
    }
  }

  static String activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.productView:
        return 'PRODUCT_VIEW';
      case ActivityType.addToCart:
        return 'ADD_TO_CART';
      case ActivityType.removeFromCart:
        return 'REMOVE_FROM_CART';
      case ActivityType.purchase:
        return 'PURCHASE';
      case ActivityType.search:
        return 'SEARCH';
      case ActivityType.categoryView:
        return 'CATEGORY_VIEW';
    }
  }

  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime ts = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    } else if (data['createdAt'] is Timestamp) {
      ts = (data['createdAt'] as Timestamp).toDate();
    }

    return UserActivity(
      id: doc.id,
      userId: (data['userId'] ?? data['customerId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      categoryId: (data['categoryId'] ?? '').toString(),
      categoryName: (data['categoryName'] ?? data['category'] ?? '').toString(),
      activityType: parseActivityType((data['activityType'] ?? data['type'] ?? 'PRODUCT_VIEW').toString()),
      timestamp: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'activityType': activityTypeToString(activityType),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
