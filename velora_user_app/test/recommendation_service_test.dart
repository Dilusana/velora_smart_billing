import 'package:flutter_test/flutter_test.dart';
import 'package:velora_user_app/models/product_model.dart';
import 'package:velora_user_app/models/cart_item.dart';
import 'package:velora_user_app/models/user_activity_model.dart';
import 'package:velora_user_app/services/recommendation_service.dart';
import 'package:velora_user_app/services/user_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recommendation Engine Unit Tests', () {
    final testProducts = [
      const ProductModel(
        id: 'prod_1',
        name: 'Fresh Whole Milk 1L',
        description: 'Fresh dairy milk',
        category: 'Chilled Foods',
        price: 350.0,
        stock: 50,
        imageUrl: '',
        status: 'active',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'prod_2',
        name: 'Cheddar Cheese 250g',
        description: 'Rich cheddar cheese block',
        category: 'Chilled Foods',
        price: 750.0,
        stock: 20,
        imageUrl: '',
        status: 'active',
        isFeatured: false,
      ),
      const ProductModel(
        id: 'prod_3',
        name: 'Salted Butter 200g',
        description: 'Pure creamy butter',
        category: 'Chilled Foods',
        price: 600.0,
        stock: 30,
        imageUrl: '',
        status: 'active',
        isFeatured: false,
      ),
      const ProductModel(
        id: 'prod_4',
        name: 'White Sandwich Bread',
        description: 'Soft white sliced bread',
        category: 'Grocery',
        price: 180.0,
        stock: 40,
        imageUrl: '',
        status: 'active',
        isFeatured: true,
      ),
      const ProductModel(
        id: 'prod_5',
        name: 'Strawberry Jam 300g',
        description: 'Sweet fruit jam',
        category: 'Grocery',
        price: 450.0,
        stock: 25,
        imageUrl: '',
        status: 'active',
        isFeatured: false,
      ),
      const ProductModel(
        id: 'prod_6',
        name: 'Out of Stock Soda',
        description: 'Unavailable beverage',
        category: 'Beverages',
        price: 200.0,
        stock: 0, // Out of stock
        imageUrl: '',
        status: 'active',
        isFeatured: false,
      ),
      const ProductModel(
        id: 'prod_7',
        name: 'Inactive Cookie Pack',
        description: 'Inactive product',
        category: 'Grocery',
        price: 150.0,
        stock: 50,
        imageUrl: '',
        status: 'inactive', // Inactive
        isFeatured: false,
      ),
    ];

    test('Popular Products returns active in-stock products with featured first', () async {
      final popular = await RecommendationService.instance.getPopularProducts(
        limit: 4,
        availablePool: testProducts,
      );

      expect(popular.isNotEmpty, isTrue);
      // Inactive & out of stock must not appear
      expect(popular.any((p) => p.id == 'prod_6'), isFalse);
      expect(popular.any((p) => p.id == 'prod_7'), isFalse);
      // Featured products ranked top
      expect(popular.first.isFeatured, isTrue);
    });

    test('Similar Products matches category and related items', () async {
      final milk = testProducts[0];
      final similar = await RecommendationService.instance.getSimilarProducts(
        targetProduct: milk,
        limit: 3,
        availablePool: testProducts,
      );

      expect(similar.isNotEmpty, isTrue);
      // Must not recommend the same milk product
      expect(similar.any((p) => p.id == milk.id), isFalse);
      // Should favor other chilled dairy products like Cheese & Butter
      expect(similar.any((p) => p.category == 'Chilled Foods'), isTrue);
    });

    test('Cart Cross-Sell recommends complementary items and excludes items in cart', () async {
      final cart = [
        const CartItem(
          productId: 'prod_4',
          category: 'Grocery',
          title: 'White Sandwich Bread',
          description: 'Bread',
          price: 180.0,
          quantity: 1,
        ),
      ];

      final recommendations = await RecommendationService.instance.getCartRecommendations(
        cartItems: cart,
        limit: 3,
        availablePool: testProducts,
      );

      expect(recommendations.isNotEmpty, isTrue);
      // Must not recommend bread again
      expect(recommendations.any((p) => p.name.contains('Bread')), isFalse);
    });

    test('UserActivityService buffers activities in memory and logs correctly', () {
      UserActivityService.instance.logProductView(
        productId: 'prod_1',
        productName: 'Fresh Whole Milk 1L',
        categoryName: 'Chilled Foods',
      );

      final buffer = UserActivityService.instance.localActivities;
      expect(buffer.isNotEmpty, isTrue);
      expect(buffer.first.activityType, equals(ActivityType.productView));
      expect(buffer.first.productName, equals('Fresh Whole Milk 1L'));
    });
  });
}
