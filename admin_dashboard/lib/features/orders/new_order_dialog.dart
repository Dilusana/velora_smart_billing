import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';

import '../../core/data/models.dart';
import '../../core/theme/app_theme.dart';
import '../customers/customer_providers.dart';
import '../products/product_providers.dart';
import 'order_providers.dart';

class NewOrderDialog extends ConsumerStatefulWidget {
  const NewOrderDialog({super.key});

  @override
  ConsumerState<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends ConsumerState<NewOrderDialog> {
  CustomerModel? _selectedCustomer;
  final Map<String, int> _selectedQuantities = {};
  String _paymentMethod = 'Cash';
  String _branch = 'Main Branch';
  bool _isLoading = false;

  final _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersAsync = ref.watch(firestoreCustomersProvider);
    final productsAsync = ref.watch(firestoreProductsProvider);

    final List<CustomerModel> customers = customersAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final List<ProductModel> products = productsAsync.maybeWhen(
      data: (list) => list.where((p) => !p.isExpired).toList(),
      orElse: () => [],
    );

    // Calculate subtotal
    double totalAmount = 0.0;
    _selectedQuantities.forEach((productId, qty) {
      final p = products.where((item) => item.id == productId).firstOrNull;
      if (p != null) {
        totalAmount += (p.price * qty);
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
      child: Container(
        width: 750,
        height: 650,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Create New Order', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Select Customer
                    const Text('1. Customer Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CustomerModel>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Customer',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value: _selectedCustomer,
                      items: [
                        const DropdownMenuItem<CustomerModel>(
                          value: null,
                          child: Text('Walk-in Customer (Guest)', overflow: TextOverflow.ellipsis),
                        ),
                        ...customers.map((c) => DropdownMenuItem<CustomerModel>(
                              value: c,
                              child: Text('${c.name} (${c.phone.isNotEmpty ? c.phone : c.email})', overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedCustomer = val),
                    ),
                    const SizedBox(height: 20),

                    // 2. Select Items
                    const Text('2. Select Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (products.isEmpty)
                      const Text('No products available. Please add products first.', style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (ctx, idx) {
                          final p = products[idx];
                          final qty = _selectedQuantities[p.id] ?? 0;

                          return Card(
                            elevation: 0,
                            color: isDark ? AppColors.bgDarkSurface : AppColors.bgPrimary,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Price: ${_currFmt.format(p.price)} | Stock: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: qty > 0
                                            ? () {
                                                setState(() {
                                                  if (qty == 1) {
                                                    _selectedQuantities.remove(p.id);
                                                  } else {
                                                    _selectedQuantities[p.id] = qty - 1;
                                                  }
                                                });
                                              }
                                            : null,
                                      ),
                                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedQuantities[p.id] = qty + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // 3. Payment Method & Branch
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _paymentMethod,
                            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), isDense: true),
                            items: ['Cash', 'Card', 'QR / Online', 'Pending']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMethod = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _branch,
                            decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder(), isDense: true),
                            items: ['Main Branch', 'Downtown Branch', 'Kiosk #1']
                                .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _branch = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // Footer Total & Actions
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(_currFmt.format(totalAmount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
                  label: const Text('Create Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: (_isLoading || _selectedQuantities.isEmpty)
                      ? null
                      : () async {
                          setState(() => _isLoading = true);

                          final items = <OrderItem>[];
                          _selectedQuantities.forEach((productId, qty) {
                            final p = products.firstWhere((item) => item.id == productId);
                            items.add(OrderItem(
                              productId: p.id,
                              productName: p.name,
                              quantity: qty,
                              unitPrice: p.price,
                              total: p.price * qty,
                            ));
                          });

                          final order = OrderModel(
                            id: '',
                            customerId: _selectedCustomer?.id ?? 'cust-guest',
                            customerName: _selectedCustomer?.name ?? 'Walk-in Customer',
                            items: items,
                            total: totalAmount,
                            paymentMethod: _paymentMethod,
                            paymentStatus: _paymentMethod == 'Pending' ? 'pending' : 'paid',
                            status: 'pending',
                            branch: _branch,
                            createdAt: DateTime.now(),
                          );

                          try {
                            final repo = ref.read(orderRepositoryProvider);
                            final orderId = await repo.createOrder(order);

                            if (mounted) {
                              Navigator.pop(context);
                              toastification.show(
                                context: context,
                                title: const Text('Order Created'),
                                description: Text('Order Ref: $orderId created in Cloud Firestore.'),
                                type: ToastificationType.success,
                                autoCloseDuration: const Duration(seconds: 4),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              toastification.show(
                                context: context,
                                title: const Text('Error Creating Order'),
                                description: Text(e.toString()),
                                type: ToastificationType.error,
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
