import 'package:flutter_test/flutter_test.dart';
import 'package:employee_user_app/models/order_model.dart';

void main() {
  group('OrderModel Driver Workflow Tests', () {
    test('isAssignedToDriver checks assigned driver correctly', () {
      final order1 = OrderModel(
        id: 'ord_1',
        branch: 'Main Branch',
        createdAt: DateTime.now(),
        customerId: 'cust_1',
        customerName: 'Alice',
        customerPhone: '1234567890',
        deliveryAddress: '123 Main St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Assigned',
        subtotal: 1000,
        total: 1150,
        users: 'Alice',
        assignedDriverId: 'EMP-1005',
      );

      expect(order1.isAssignedToDriver('EMP-1005'), isTrue);
      expect(order1.isAssignedToDriver('emp-1005'), isTrue); // case-insensitive
      expect(order1.isAssignedToDriver('EMP-9042'), isFalse);
    });

    test('isAssignedOnDate filters for today', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final todayOrder = OrderModel(
        id: 'ord_today',
        branch: 'Main Branch',
        createdAt: today,
        customerId: 'cust_1',
        customerName: 'Alice',
        customerPhone: '1234567890',
        deliveryAddress: '123 Main St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Assigned',
        subtotal: 1000,
        total: 1150,
        users: 'Alice',
        assignedDriverId: 'EMP-1005',
      );

      final yesterdayOrder = OrderModel(
        id: 'ord_yesterday',
        branch: 'Main Branch',
        createdAt: yesterday,
        customerId: 'cust_2',
        customerName: 'Bob',
        customerPhone: '9876543210',
        deliveryAddress: '456 Side St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Assigned',
        subtotal: 500,
        total: 650,
        users: 'Bob',
        assignedDriverId: 'EMP-1005',
      );

      expect(todayOrder.isAssignedOnDate(today), isTrue);
      expect(yesterdayOrder.isAssignedOnDate(today), isFalse);
      expect(todayOrder.isAssignedOnDate(tomorrow), isFalse);
    });

    test('isDelivered returns true only for DELIVERED status (Completed orders remain in queue)', () {
      final assignedOrder = OrderModel(
        id: 'ord_assigned',
        branch: 'Main Branch',
        createdAt: DateTime.now(),
        customerId: 'cust_1',
        customerName: 'Alice',
        customerPhone: '1234567890',
        deliveryAddress: '123 Main St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Assigned',
        subtotal: 1000,
        total: 1150,
        users: 'Alice',
      );

      final completedPrepOrder = OrderModel(
        id: 'ord_completed',
        branch: 'Main Branch',
        createdAt: DateTime.now(),
        customerId: 'cust_2',
        customerName: 'Bob',
        customerPhone: '9876543210',
        deliveryAddress: '456 Side St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Completed',
        subtotal: 500,
        total: 650,
        users: 'Bob',
      );

      final deliveredOrder = OrderModel(
        id: 'ord_delivered',
        branch: 'Main Branch',
        createdAt: DateTime.now(),
        customerId: 'cust_3',
        customerName: 'Charlie',
        customerPhone: '1122334455',
        deliveryAddress: '789 Elm St',
        deliveryFee: 150,
        discount: 0,
        items: [],
        orderSource: 'UserApp',
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: 'Delivered',
        subtotal: 750,
        total: 900,
        users: 'Charlie',
      );

      expect(assignedOrder.isDelivered, isFalse);
      // Completed orders (prepared in store ops) must remain in delivery queue until delivered!
      expect(completedPrepOrder.isDelivered, isFalse);
      // Only delivered orders are considered delivered
      expect(deliveredOrder.isDelivered, isTrue);
    });
  });
}
