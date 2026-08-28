import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final firestoreCustomersProvider = StreamProvider<List<CustomerModel>>((ref) {
  return ref.watch(customerRepositoryProvider).watchCustomers();
});
