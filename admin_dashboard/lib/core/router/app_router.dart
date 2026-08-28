import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/products/products_page.dart';
import '../../features/products/product_detail_page.dart';
import '../../features/categories/categories_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/inventory/inventory_detail_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/orders/order_detail_page.dart';
import '../../features/sales/sales_page.dart';
import '../../features/customers/customers_page.dart';
import '../../features/customers/customer_profile_page.dart';
import '../../features/payments/payments_page.dart';
import '../../features/suppliers/suppliers_page.dart';
import '../../features/suppliers/supplier_detail_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/promotions/promotions_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/employees/employees_page.dart';
import '../../features/employees/employee_profile_page.dart';
import '../../features/help_center/help_center_page.dart';
import '../widgets/main_layout.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return ProductsPage(initialCategory: category);
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ProductDetailPage(
                  id: state.pathParameters['id']!,
                ),

              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return InventoryPage(initialFilter: filter);
            },
            routes: [
              GoRoute(
                path: ':productId',
                builder: (context, state) => InventoryDetailPage(
                  productId: state.pathParameters['productId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => OrderDetailPage(
                  orderId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesPage(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CustomerProfilePage(
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsPage(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SuppliersPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => SupplierDetailPage(
                  id: state.pathParameters['id']!,
                ),

              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/promotions',
            builder: (context, state) => const PromotionsPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeesPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => EmployeeProfilePage(
                  id: state.pathParameters['id']!,
                ),

              ),
            ],
          ),
          GoRoute(
            path: '/help-center',
            builder: (context, state) => const HelpCenterPage(),
          ),
        ],
      ),
    ],
  );
});
