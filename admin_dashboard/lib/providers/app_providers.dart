import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/data/models.dart';
import '../core/data/mock_data.dart';

// Authentication
class AuthState {
  final bool isLoggedIn;
  final EmployeeModel? currentUser;

  AuthState({this.isLoggedIn = false, this.currentUser});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoggedIn: true, currentUser: MockData.employees.first));

  void login(String email, String password) {
    // Mock login
    state = AuthState(isLoggedIn: true, currentUser: MockData.employees.first);
  }

  void logout() {
    state = AuthState(isLoggedIn: false, currentUser: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// Theme
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false);
  void toggleTheme() => state = !state;
}

// Products
class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  ProductsNotifier() : super(MockData.products);

  void add(ProductModel item) => state = [...state, item];
  void update(ProductModel item) => state = [for (final p in state) if (p.id == item.id) item else p];
  void delete(String id) => state = state.where((p) => p.id != id).toList();
}
final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) => ProductsNotifier());

// Categories
class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  CategoriesNotifier() : super(MockData.categories);

  void add(CategoryModel item) => state = [...state, item];
  void update(CategoryModel item) => state = [for (final c in state) if (c.id == item.id) item else c];
  void delete(String id) => state = state.where((c) => c.id != id).toList();
}
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>((ref) => CategoriesNotifier());

// Orders
class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  OrdersNotifier() : super(MockData.orders);

  void add(OrderModel item) => state = [...state, item];
  void updateStatus(String id, String status) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(status: status) else o
    ];
  }
}
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) => OrdersNotifier());

// Customers
class CustomersNotifier extends StateNotifier<List<CustomerModel>> {
  CustomersNotifier() : super(MockData.customers);
  
  void add(CustomerModel item) => state = [...state, item];
  void update(CustomerModel item) => state = [for (final c in state) if (c.id == item.id) item else c];
}
final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerModel>>((ref) => CustomersNotifier());

// Inventory
class InventoryNotifier extends StateNotifier<List<InventoryItemModel>> {
  InventoryNotifier() : super(MockData.inventory);

  void adjustStock(String productId, int newStock) {
    state = [
      for (final i in state)
        if (i.productId == productId) i.copyWith(currentStock: newStock) else i
    ];
  }
}
final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryItemModel>>((ref) => InventoryNotifier());

// Payments
class PaymentsNotifier extends StateNotifier<List<PaymentModel>> {
  PaymentsNotifier() : super(MockData.payments);

  void refund(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: 'refunded') else p
    ];
  }
}
final paymentsProvider = StateNotifierProvider<PaymentsNotifier, List<PaymentModel>>((ref) => PaymentsNotifier());

// Suppliers
class SuppliersNotifier extends StateNotifier<List<SupplierModel>> {
  SuppliersNotifier() : super(MockData.suppliers);
}
final suppliersProvider = StateNotifierProvider<SuppliersNotifier, List<SupplierModel>>((ref) => SuppliersNotifier());

// Promotions
class PromotionsNotifier extends StateNotifier<List<PromotionModel>> {
  PromotionsNotifier() : super(MockData.promotions);

  void toggleStatus(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(status: p.status == 'active' ? 'inactive' : 'active') else p
    ];
  }
}
final promotionsProvider = StateNotifierProvider<PromotionsNotifier, List<PromotionModel>>((ref) => PromotionsNotifier());

// Employees
class EmployeesNotifier extends StateNotifier<List<EmployeeModel>> {
  EmployeesNotifier() : super(MockData.employees);
}
final employeesProvider = StateNotifierProvider<EmployeesNotifier, List<EmployeeModel>>((ref) => EmployeesNotifier());

// Notifications
class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super(MockData.notifications);

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }
}
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>((ref) => NotificationsNotifier());

// Global Search
final searchProvider = StateNotifierProvider<SearchNotifier, String>((ref) => SearchNotifier());
class SearchNotifier extends StateNotifier<String> {
  SearchNotifier() : super('');
  void updateQuery(String q) => state = q;
}

// Sidebar state
final sidebarProvider = StateNotifierProvider<SidebarNotifier, bool>((ref) => SidebarNotifier());
class SidebarNotifier extends StateNotifier<bool> {
  SidebarNotifier() : super(false);
  void toggle() => state = !state;
}
