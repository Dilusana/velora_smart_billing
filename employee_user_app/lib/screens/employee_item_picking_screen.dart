import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class EmployeeItemPickingScreen extends StatefulWidget {
  final String orderId;

  const EmployeeItemPickingScreen({
    super.key,
    this.orderId = 'order_1787462193108',
  });

  @override
  State<EmployeeItemPickingScreen> createState() => _EmployeeItemPickingScreenState();
}

class _EmployeeItemPickingScreenState extends State<EmployeeItemPickingScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: OrderService.getOrderByIdStream(widget.orderId),
      builder: (context, snapshot) {
        final order = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting && order == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F5EE),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1A2D5A)),
            ),
          );
        }

        final itemsList = order?.items ?? [];

        final totalCount = itemsList.fold(0, (sum, i) => sum + i.quantity);
        final checkedCount = itemsList.fold(0, (sum, i) => sum + (i.isPicked ? i.quantity : 0));
        final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
        final displayTitle = order != null ? order.displayId : widget.orderId;

        // Group items by Category
        final categoriesMap = <String, List<MapEntry<int, OrderItemModel>>>{};
        for (int i = 0; i < itemsList.length; i++) {
          final cat = itemsList[i].category;
          categoriesMap.putIfAbsent(cat, () => []).add(MapEntry(i, itemsList[i]));
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F5EE),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F5EE),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2D5A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Picking: $displayTitle',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'LIVE TIME ',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '12:35',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A2D5A), size: 18),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Progress Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Progress',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                            Text(
                              '$checkedCount of $totalCount items',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE0E7FF),
                            color: const Color(0xFFC8E635),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categorized Items List or Empty State
                  if (itemsList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF9CA3AF)),
                          const SizedBox(height: 10),
                          Text(
                            'No items found in this order',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A2D5A),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...categoriesMap.entries.map((catEntry) {
                      final categoryName = catEntry.key;
                      final entries = catEntry.value;
                      final firstAisle = entries.first.value.aisle;
                      final categoryIcon = _getCategoryIcon(categoryName);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(categoryName, categoryIcon, firstAisle),
                          const SizedBox(height: 10),
                          ...entries.map((e) => _buildItemTile(order?.id, e.key, e.value)),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                  // Order Complete Button - only shows when all items are picked
                  if (checkedCount == totalCount && totalCount > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (order?.id != null) {
                            await OrderService.updateOrderStatus(order!.id, 'Completed');
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Order ${order?.displayId ?? ''} marked as completed!',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8E635),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF1A2D5A), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Order Complete',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    if (cat.contains('Veg') || cat.contains('Fruit')) return Icons.eco_outlined;
    if (cat.contains('Electronics') || cat.contains('Tech')) return Icons.devices_rounded;
    if (cat.contains('Grocery')) return Icons.shopping_cart_outlined;
    return Icons.inventory_2_outlined;
  }

  Widget _buildCategoryHeader(String title, IconData icon, String aisle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A2D5A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2D5A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FEE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            aisle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF65A30D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(String? docId, int index, OrderItemModel item) {
    final isChecked = item.isPicked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          if (docId != null) {
            await OrderService.toggleOrderItemPicked(docId, index, !isChecked);
          } else {
            setState(() {
              // Local fallback if no docId
            });
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Custom Circle Checkbox
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFFC8E635) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChecked ? const Color(0xFFC8E635) : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1A2D5A))
                    : null,
              ),
              const SizedBox(width: 14),

              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF)),
                      ),
              ),
              const SizedBox(width: 12),

              // Title & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sku,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity & Sub tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'x${item.quantity}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A2D5A),
                    ),
                  ),
                  if (item.hasSub) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SUB?',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF84CC16),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
