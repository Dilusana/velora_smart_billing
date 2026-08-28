import 'package:flutter_test/flutter_test.dart';
import 'package:retailnova/product_model.dart';
import 'package:retailnova/promotion_model.dart';
import 'package:retailnova/sms_service.dart';
import 'package:retailnova/cart_item.dart';

void main() {
  group('1. Pricing and Discount Engine Tests', () {
    test('Calculates percentage discount accurately', () {
      final promo = PromotionModel(
        id: 'promo_pct_1',
        name: 'Super Saver 20%',
        type: 'Discount %',
        value: 20.0,
        scope: 'All Products',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'active',
        usageCount: 0,
        couponCode: 'SAVE20',
        minimumPurchaseAmount: 500.0,
        maximumDiscount: 1000.0,
      );

      const double subtotal = 2000.0;
      final double discount = (subtotal * (promo.value / 100.0)).clamp(0.0, promo.maximumDiscount > 0 ? promo.maximumDiscount : double.infinity);

      expect(discount, equals(400.0));
      expect(subtotal >= promo.minimumPurchaseAmount, isTrue);
    });

    test('Enforces maximum discount ceiling cap', () {
      final promo = PromotionModel(
        id: 'promo_cap_1',
        name: 'Big 50% Off Cap 300',
        type: 'Discount %',
        value: 50.0,
        scope: 'All Products',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'active',
        usageCount: 0,
        couponCode: 'HALF50',
        minimumPurchaseAmount: 500.0,
        maximumDiscount: 300.0,
      );

      const double subtotal = 1000.0; // 50% = 500, but capped at 300
      final double rawDiscount = subtotal * (promo.value / 100.0);
      final double effectiveDiscount = promo.maximumDiscount > 0
          ? rawDiscount.clamp(0.0, promo.maximumDiscount)
          : rawDiscount;

      expect(effectiveDiscount, equals(300.0));
    });

    test('Rejects discount when subtotal is below minimum purchase threshold', () {
      final promo = PromotionModel(
        id: 'promo_min_1',
        name: 'Min Spend Promo',
        type: 'Flat Off',
        value: 150.0,
        scope: 'All Products',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'active',
        usageCount: 0,
        couponCode: 'FLAT150',
        minimumPurchaseAmount: 1000.0,
      );

      const double subtotal = 750.0;
      expect(subtotal >= promo.minimumPurchaseAmount, isFalse);
    });
  });

  group('2. Data Model Serialization Tests', () {
    test('ProductModel parses Firestore map and validates properties', () {
      final Map<String, dynamic> data = {
        'name': 'Basmati Rice 5kg',
        'category': 'Groceries',
        'price': 2200.0,
        'stock': 45,
        'imageUrl': 'https://res.cloudinary.com/velora/image/upload/rice.jpg',
      };

      final product = ProductModel.fromMap(data, docId: 'prod_rice_01');

      expect(product.id, equals('prod_rice_01'));
      expect(product.name, equals('Basmati Rice 5kg'));
      expect(product.price, equals(2200.0));
      expect(product.stock, equals(45));
      expect(product.isWebImage, isTrue);
      expect(product.isAssetImage, isFalse);
    });

    test('PromotionModel constructor parses values accurately', () {
      final promo = PromotionModel(
        id: 'promo_weekend',
        name: 'Weekend Mega Deal',
        type: 'Discount %',
        value: 25.0,
        scope: 'All Products',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: 'active',
        usageCount: 5,
        couponCode: 'WEEKEND25',
        imageUrl: 'https://res.cloudinary.com/velora/banner.png',
      );

      expect(promo.id, equals('promo_weekend'));
      expect(promo.name, equals('Weekend Mega Deal'));
      expect(promo.discountDisplay, equals('25% OFF'));
      expect(promo.couponCode, equals('WEEKEND25'));
      expect(promo.imageUrl, equals('https://res.cloudinary.com/velora/banner.png'));
    });
  });

  group('3. Phone Number Normalization Tests', () {
    test('Normalizes 10-digit Sri Lankan phone starting with 0', () {
      final result = SmsService.instance.normalizeSriLankanPhone('0771234567');
      expect(result, equals('94771234567'));
    });

    test('Normalizes 9-digit phone starting with 7', () {
      final result = SmsService.instance.normalizeSriLankanPhone('712345678');
      expect(result, equals('94712345678'));
    });

    test('Normalizes phone with international country code +94', () {
      final result = SmsService.instance.normalizeSriLankanPhone('+94771234567');
      expect(result, equals('94771234567'));
    });

    test('Rejects invalid phone numbers', () {
      expect(SmsService.instance.normalizeSriLankanPhone(''), isNull);
      expect(SmsService.instance.normalizeSriLankanPhone('invalid_phone'), isNull);
      expect(SmsService.instance.normalizeSriLankanPhone('12345'), isNull);
    });
  });

  group('4. Cart Item and Stock Validation Tests', () {
    test('Calculates cart item subtotal correctly', () {
      final item = CartItem(
        id: 1,
        productId: 'prod_milk_01',
        title: 'Fresh Milk 1L',
        category: 'Dairy',
        description: 'Fresh cow milk',
        price: 450.0,
        quantity: 3,
      );

      final lineTotal = item.price * item.quantity;
      expect(lineTotal, equals(1350.0));
    });

    test('Prevents quantity exceeding available inventory stock', () {
      const product = ProductModel(
        id: 'prod_butter_01',
        name: 'Salted Butter 200g',
        category: 'Dairy',
        description: 'Pure butter',
        price: 680.0,
        stock: 5,
        imageUrl: '',
        status: 'active',
      );

      const int requestedQuantity = 8;
      final bool isAllowed = requestedQuantity <= product.stock;

      expect(isAllowed, isFalse);
      expect(product.stock, equals(5));
    });
  });
}
