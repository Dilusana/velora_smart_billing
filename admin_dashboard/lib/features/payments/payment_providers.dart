import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

final firestorePaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchPayments();
});
