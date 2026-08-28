import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class CustomerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _customers => _db.collection('customers');

  /// Watch real-time stream of all customers
  Stream<List<CustomerModel>> watchCustomers() {
    return _customers.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CustomerModel.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  /// Get single customer by ID
  Future<CustomerModel?> getCustomer(String id) async {
    final doc = await _customers.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel.fromMap(data, docId: doc.id);
  }

  /// Add new customer
  Future<String> addCustomer(CustomerModel customer) async {
    final ref = _customers.doc();
    await ref.set(_toFirestore(customer));
    return ref.id;
  }

  /// Update existing customer
  Future<void> updateCustomer(CustomerModel customer) async {
    await _customers.doc(customer.id).update(_toFirestore(customer));
  }

  Map<String, dynamic> _toFirestore(CustomerModel customer) {
    return {
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
      'status': customer.status,
      'loyaltyPoints': customer.loyaltyPoints,
      'loyaltyTier': customer.loyaltyTier,
      'totalOrders': customer.totalOrders,
      'totalSpend': customer.totalSpend,
      'lastOrderDate': Timestamp.fromDate(customer.lastOrderDate),
      'joinDate': Timestamp.fromDate(customer.joinDate),
    };
  }
}
