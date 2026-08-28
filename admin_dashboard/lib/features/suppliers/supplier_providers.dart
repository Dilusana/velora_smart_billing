import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'supplier_repository.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

final firestoreSuppliersProvider = StreamProvider<List<SupplierModel>>((ref) {
  return ref.watch(supplierRepositoryProvider).watchSuppliers();
});
