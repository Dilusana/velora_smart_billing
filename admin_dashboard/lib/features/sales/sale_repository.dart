import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class SaleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _salesRef => _db.collection('sales');
  CollectionReference get _ordersRef => _db.collection('orders');

  /// Watch real-time stream of sales from Firestore 'sales' collection (or orders fallback)
  Stream<List<SaleModel>> watchSales() {
    return _salesRef.snapshots().asyncMap((snap) async {
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return SaleModel.fromMap(data, docId: doc.id);
        }).toList();
        list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        return list;
      }

      // Fallback: derive sales list from orders collection
      final ordersSnap = await _ordersRef.get();
      final list = ordersSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final order = OrderModel.fromMap(data, docId: doc.id);
        final bLower = order.branch.toLowerCase();
        final delLower = order.deliveryType.toLowerCase();
        final isKiosk = bLower.contains('kiosk') || 
                        bLower.contains('pos') || 
                        bLower.contains('counter') || 
                        delLower.contains('kiosk') || 
                        delLower.contains('pos') || 
                        delLower.contains('dine');
        return SaleModel(
          id: doc.id,
          orderId: order.id,
          invoiceNumber: order.id,
          customerId: order.customerId,
          customerName: order.customerName,
          orderSource: isKiosk ? 'Kiosk' : 'App',
          orderStatus: order.status,
          paymentStatus: order.paymentStatus.isNotEmpty ? order.paymentStatus : 'paid',
          totalAmount: order.total,
          orderDate: order.createdAt,
        );
      }).toList();
      list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return list;
    });
  }

  /// Create new sale in Cloud Firestore
  Future<String> createSale(SaleModel sale) async {
    final ref = _salesRef.doc();
    await ref.set(sale.toMap());
    return ref.id;
  }
}
