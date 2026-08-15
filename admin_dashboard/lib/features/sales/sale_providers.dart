import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'sale_repository.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

final firestoreSalesProvider = StreamProvider<List<SaleModel>>((ref) {
  return ref.watch(saleRepositoryProvider).watchSales();
});
