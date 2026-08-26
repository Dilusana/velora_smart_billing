import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_screen.dart';

// ─── Order Receipt Screen ─────────────────────────────────────────────────────

class OrderReceiptScreen extends StatelessWidget {
  final Order order;
  const OrderReceiptScreen({super.key, required this.order});

  Color get _statusBg => switch (order.status) {
    OrderStatus.completed => const Color(0xFFDCFCE7),
    OrderStatus.processing => const Color(0xFFFEF9C3),
    OrderStatus.cancelled => const Color(0xFFFEE2E2),
  };

  Color get _statusColor => switch (order.status) {
    OrderStatus.completed => const Color(0xFF16A34A),
    OrderStatus.processing => const Color(0xFFA16207),
    OrderStatus.cancelled => const Color(0xFFDC2626),
  };

  String get _statusLabel => switch (order.status) {
    OrderStatus.completed => '✓ COMPLETED',
    OrderStatus.processing => '⟳ PROCESSING',
    OrderStatus.cancelled => '✕ CANCELLED',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EB),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: const Color(0xFFF5F3EB),
                  elevation: 0,
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 56,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF3A5A2A)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Order Receipt',
                          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                      ],
                    ),
                  ),
                ),

                // ── Order Header Card ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('ORDER NUMBER',
                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF), letterSpacing: 0.8)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                                child: Text(_statusLabel,
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('#${order.id}',
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoPill(icon: Icons.calendar_today_rounded, label: order.date),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('TOTAL PAID',
                                    style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                                  Text('Rs ${order.total.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF3A5A1E))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Purchased Items ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                            child: Text('Purchased Items',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                          ),
                          const SizedBox(height: 10),
                          ...order.items.asMap().entries.map((e) {
                            final isLast = e.key == order.items.length - 1;
                            return _ReceiptItemRow(item: e.value, isLast: isLast);
                          }),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Payment + Address ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.credit_card_rounded,
                            iconBg: const Color(0xFFEEF5C8),
                            iconColor: const Color(0xFF3A5A2A),
                            label: 'PAYMENT METHOD',
                            value: order.paymentMethod,
                          ),
                          Divider(color: const Color(0xFFE5E7EB), height: 24),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            label: 'DELIVERY ADDRESS',
                            value: order.deliveryAddress,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Order Summary ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Subtotal', value: 'Rs ${order.subtotal.toStringAsFixed(2)}'),
                          if (order.tax > 0) ...[
                            const SizedBox(height: 8),
                            _SummaryRow(label: 'Tax', value: 'Rs ${order.tax.toStringAsFixed(2)}'),
                          ],
                          if (order.discount > 0) ...[
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Discount',
                              value: '-\$${order.discount.toStringAsFixed(2)}',
                              valueColor: const Color(0xFFEF4444),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(color: const Color(0xFFE5E7EB), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                              Text('Rs ${order.total.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // ── Bottom Action Buttons ──────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EB),
                  border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
                ),
                child: Row(
                  children: [
                    // Download PDF
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PDF downloaded!', style: GoogleFonts.outfit(color: Colors.white)),
                            backgroundColor: const Color(0xFF3A5A2A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        ),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF3A5A2A), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.download_rounded, size: 16, color: Color(0xFF3A5A2A)),
                              const SizedBox(width: 6),
                              Text('Download PDF',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3A5A2A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Reorder
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Items re-added to cart!', style: GoogleFonts.outfit(color: Colors.white)),
                              backgroundColor: const Color(0xFF3A5A2A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCEE847),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color(0xFFCEE847).withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1A2D5A)),
                              const SizedBox(width: 6),
                              Text('Reorder',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A2D5A))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Receipt Item Row ─────────────────────────────────────────────────────────

class _ReceiptItemRow extends StatelessWidget {
  final OrderLineItem item;
  final bool isLast;
  const _ReceiptItemRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52, height: 52,
                  child: item.imagePath != null
                      ? Image.asset(item.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFF0F5D8),
                            child: Icon(item.fallbackIcon, size: 24, color: const Color(0xFF3A5A2A)),
                          ))
                      : Container(
                          color: const Color(0xFFF0F5D8),
                          child: Icon(item.fallbackIcon, size: 24, color: const Color(0xFF3A5A2A))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    Text(item.unit,
                      style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Text('Rs ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: const Color(0xFFF3F4F6), height: 1, indent: 18, endIndent: 18),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280))),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF111827))),
      ],
    );
  }
}
