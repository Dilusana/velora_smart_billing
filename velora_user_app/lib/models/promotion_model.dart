import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String id;
  final String name;
  final String type; // 'Discount %', 'Flat Off', 'BOGO', 'Coupon'
  final double value;
  final String scope; // 'All Products', 'Specific Category', 'Specific Products'
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'inactive', 'expired'
  final int usageCount;
  final String couponCode;
  final String description;
  final double minimumPurchaseAmount;
  final double maximumDiscount;
  final List<String> applicableProducts;
  final List<String> applicableCategories;
  final String imageUrl;

  const PromotionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.scope,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.usageCount,
    required this.couponCode,
    this.description = '',
    this.minimumPurchaseAmount = 0.0,
    this.maximumDiscount = 0.0,
    this.applicableProducts = const [],
    this.applicableCategories = const [],
    this.imageUrl = '',
  });

  bool get isActive {
    final now = DateTime.now();
    final isWithinDate = (now.isAfter(startDate) || now.isAtSameMomentAs(startDate)) &&
        (now.isBefore(endDate) || now.isAtSameMomentAs(endDate));
    return status.toLowerCase() == 'active' && isWithinDate;
  }

  bool get isWebImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawId = doc.id;
    final nameVal = (data['Promotion Name'] ?? data['name'] ?? data['couponCode'] ?? '').toString();
    final typeVal = (data['Promotion_Type'] ?? data['type'] ?? data['Promotion Type'] ?? 'Discount %').toString();

    double val = 0.0;
    final rawVal = data['Discount_Value'] ?? data['value'] ?? data['Discount Value'];
    if (rawVal is num) {
      val = rawVal.toDouble();
    } else if (rawVal != null) {
      val = double.tryParse(rawVal.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    }

    final rawProducts = data['Applicable_Products'] ?? data['applicableProducts'] ?? data['Applicable Products'];
    final List<String> appProducts = [];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item != null) appProducts.add(item.toString());
      }
    }

    final rawCategories = data['applicable_Categories'] ?? data['applicableCategories'] ?? data['Applicable Categories'];
    final List<String> appCategories = [];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        if (item != null) appCategories.add(item.toString());
      }
    }

    String scopeVal = (data['scope'] ?? '').toString();
    if (scopeVal.isEmpty) {
      if (appProducts.isNotEmpty) {
        scopeVal = 'Specific Products';
      } else if (appCategories.isNotEmpty) {
        scopeVal = 'Specific Category';
      } else {
        scopeVal = 'All Products';
      }
    }

    DateTime sDate = DateTime.now();
    final rawStart = data['startDate'] ?? data['start_date'] ?? data['Start Date'] ?? data['createdAt'];
    if (rawStart is Timestamp) {
      sDate = rawStart.toDate();
    } else if (rawStart is String) {
      sDate = DateTime.tryParse(rawStart) ?? DateTime.now();
    }

    DateTime eDate = DateTime.now().add(const Duration(days: 30));
    final rawEnd = data['endDate'] ?? data['end_date'] ?? data['End Date'];
    if (rawEnd is Timestamp) {
      eDate = rawEnd.toDate();
    } else if (rawEnd is String) {
      eDate = DateTime.tryParse(rawEnd) ?? DateTime.now().add(const Duration(days: 30));
    }

    final stat = (data['status'] ?? 'active').toString();
    final usage = (data['usageCount'] as num?)?.toInt() ?? (data['usage'] as num?)?.toInt() ?? 0;
    final code = (data['Promotion ID'] ?? data['couponCode'] ?? data['code'] ?? rawId).toString();
    final desc = (data['Description'] ?? data['description'] ?? '').toString();

    double minPurch = 0.0;
    final rawMin = data['minimumPurchaseAmount'] ?? data['minPurchase'];
    if (rawMin is num) {
      minPurch = rawMin.toDouble();
    } else if (rawMin != null) {
      minPurch = double.tryParse(rawMin.toString()) ?? 0.0;
    }

    double maxDisc = 0.0;
    final rawMax = data['maximumDiscount'] ?? data['maxDiscount'];
    if (rawMax is num) {
      maxDisc = rawMax.toDouble();
    } else if (rawMax != null) {
      maxDisc = double.tryParse(rawMax.toString()) ?? 0.0;
    }

    final img = (data['imageUrl'] ?? data['image'] ?? data['bannerUrl'] ?? data['banner'] ?? '').toString();

    return PromotionModel(
      id: rawId,
      name: nameVal.isEmpty ? 'Promotion' : nameVal,
      type: typeVal.isEmpty ? 'Discount %' : typeVal,
      value: val,
      scope: scopeVal,
      startDate: sDate,
      endDate: eDate,
      status: stat,
      usageCount: usage,
      couponCode: code,
      description: desc,
      minimumPurchaseAmount: minPurch,
      maximumDiscount: maxDisc,
      applicableProducts: appProducts,
      applicableCategories: appCategories,
      imageUrl: img,
    );
  }
}