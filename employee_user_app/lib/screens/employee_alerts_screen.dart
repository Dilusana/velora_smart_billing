import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeAlertsScreen extends StatefulWidget {
  final bool showBackButton;
  const EmployeeAlertsScreen({super.key, this.showBackButton = false});

  @override
  State<EmployeeAlertsScreen> createState() => _EmployeeAlertsScreenState();
}

class AlertFilterItem {
  final String label;
  final int? count;
  final bool isUrgent;
  const AlertFilterItem({required this.label, this.count, this.isUrgent = false});
}

class _EmployeeAlertsScreenState extends State<EmployeeAlertsScreen> {
  int _selectedFilterIndex = 0;

  final List<AlertFilterItem> _filters = const [
    AlertFilterItem(label: 'All'),
    AlertFilterItem(label: 'Orders', count: 4),
    AlertFilterItem(label: 'Urgent', count: 1, isUrgent: true),
    AlertFilterItem(label: 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar
              Row(
                children: [
                  if (widget.showBackButton) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2D5A)),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    'Velora',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2D5A),
                    ),
                  ),
                  const Spacer(),
                  Container(
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
              const SizedBox(height: 20),

              // Title & Mark All Read
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stay updated with your latest assignments',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Mark All\nRead',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Chips Row
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, idx) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilterIndex == index;
                    final isUrgentChip = filter.isUrgent;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A2D5A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              filter.label,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF374151),
                              ),
                            ),
                            if (filter.count != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isUrgentChip
                                      ? const Color(0xFFDC2626)
                                      : (isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF3F4F6)),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${filter.count}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isUrgentChip
                                        ? Colors.white
                                        : (isSelected ? Colors.white : const Color(0xFF374151)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // TODAY Section Header
              Text(
                'TODAY',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Alert 1 - URGENT ACTION
              _buildNotificationCard(
                icon: Icons.warning_rounded,
                iconColor: const Color(0xFFB91C1C),
                iconBgColor: const Color(0xFFFEE2E2),
                tagText: 'URGENT ACTION',
                tagColor: const Color(0xFFB91C1C),
                timeText: '2m ago',
                subtitle: 'Hazardous Spill Reported',
                description: 'Spill detected in Aisle 4. Immediate containment required. Please report to Zone C.',
                hasActionButtons: true,
                leftAccentColor: const Color(0xFFC8E635),
              ),
              const SizedBox(height: 12),

              // Alert 2 - NEW ASSIGNMENT
              _buildNotificationCard(
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                tagText: 'NEW ASSIGNMENT',
                tagColor: const Color(0xFF1E40AF),
                timeText: '1h ago',
                subtitle: 'Order Batch #8892',
                description: 'New high-priority pickup assigned for the South Distribution Center.',
                leftAccentColor: const Color(0xFFC8E635),
              ),
              const SizedBox(height: 12),

              // Alert 3 - STATUS UPDATE
              _buildNotificationCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                tagText: 'STATUS UPDATE',
                tagColor: const Color(0xFF15803D),
                timeText: '4h ago',
                subtitle: 'Delivery Confirmed',
                description: 'Batch #8812 has been successfully received at Global Logistics Hub.',
              ),
              const SizedBox(height: 24),

              // YESTERDAY Section Header
              Text(
                'YESTERDAY',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Alert 4 - MESSAGE
              _buildNotificationCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBgColor: const Color(0xFFF3E8FF),
                tagText: 'MESSAGE • Supervisor Sarah',
                tagColor: const Color(0xFF7E22CE),
                timeText: 'Yesterday',
                subtitle: 'Performance Review',
                description: '"Great work on the last shift! Your scan accuracy was 100%."',
              ),
              const SizedBox(height: 12),

              // Alert 5 - INVENTORY ALERT
              _buildNotificationCard(
                icon: Icons.inventory_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                tagText: 'INVENTORY ALERT',
                tagColor: const Color(0xFFB45309),
                timeText: 'Yesterday',
                subtitle: 'Low Stock: SKU-902',
                description: 'Packing supplies in Bay 2 are below 15%. Order replenishment required soon.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String tagText,
    required Color tagColor,
    required String timeText,
    required String subtitle,
    required String description,
    bool hasActionButtons = false,
    Color? leftAccentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leftAccentColor != null) ...[
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: leftAccentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tagText,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: tagColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      timeText,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
                if (hasActionButtons) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Respond Now',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDBEAFE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Dismiss',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
