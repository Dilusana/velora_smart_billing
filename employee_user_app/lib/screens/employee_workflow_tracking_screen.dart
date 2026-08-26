import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeWorkflowTrackingScreen extends StatefulWidget {
  final String orderId;

  const EmployeeWorkflowTrackingScreen({
    super.key,
    this.orderId = 'ORD-3012',
  });

  @override
  State<EmployeeWorkflowTrackingScreen> createState() => _EmployeeWorkflowTrackingScreenState();
}

class _EmployeeWorkflowTrackingScreenState extends State<EmployeeWorkflowTrackingScreen> {
  bool _isActivityLogExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2D5A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2D5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.orderId,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC8E635),
                ),
              ),
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
              // Customer Detail Card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF1A2D5A)),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Detail',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Name', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Text(
                          'Robert Sterling',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FEE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Authorized (VISA)',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF65A30D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Assignment Card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF1A2D5A)),
                        const SizedBox(width: 8),
                        Text(
                          'Assignment',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Employee', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Text(
                          'Sarah Jenkins',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Est. Time', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7280))),
                        Text(
                          '14:45 (Today)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Workflow Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workflow Progress',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A2D5A),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step 1: Received
                    _buildWorkflowStep(
                      title: 'Received',
                      subtitle: '09:12 AM – System auto-logged',
                      isCompleted: true,
                      isLast: false,
                    ),
                    // Step 2: Assigned
                    _buildWorkflowStep(
                      title: 'Assigned',
                      subtitle: '10:05 AM – Assigned to Zone 4',
                      isCompleted: true,
                      isLast: false,
                    ),
                    // Step 3: Picking (Active)
                    _buildWorkflowStep(
                      title: 'Picking',
                      subtitle: 'In Progress (4/12 items)',
                      isActive: true,
                      isLast: false,
                    ),
                    // Step 4: Packing
                    _buildWorkflowStep(
                      title: 'Packing',
                      subtitle: 'Pending picking completion',
                      isPending: true,
                      isLast: false,
                    ),
                    // Step 5: Quality Checked
                    _buildWorkflowStep(
                      title: 'Quality Checked',
                      subtitle: 'Awaiting inspector',
                      isPending: true,
                      isLast: false,
                    ),
                    // Step 6: Ready
                    _buildWorkflowStep(
                      title: 'Ready',
                      subtitle: 'Final staging area',
                      isPending: true,
                      isLast: false,
                    ),
                    // Step 7: Completed
                    _buildWorkflowStep(
                      title: 'Completed',
                      subtitle: 'Handover confirmation',
                      isPending: true,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Employee Activity Log Expandable Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isActivityLogExpanded = !_isActivityLogExpanded),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 18, color: Color(0xFF1E40AF)),
                            const SizedBox(width: 8),
                            Text(
                              'Employee Activity Log',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _isActivityLogExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF1E40AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isActivityLogExpanded) ...[
                      const Divider(height: 1, color: Color(0xFFDBEAFE)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildLogItem('Items collected (Milk, Eggs, Flour)', '10:45 AM – Zone A3'),
                            const SizedBox(height: 12),
                            _buildLogItem('Picking Started', '10:30 AM – Terminal B-02'),
                            const SizedBox(height: 12),
                            _buildLogItem('Accepted by Sarah Jenkins', '10:05 AM – Dispatch Console'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Bar (3 Buttons)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2D5A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Update Status',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 14),
                        label: Text(
                          'Flag Issue',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8E635),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Mark Ready',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowStep({
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isActive = false,
    bool isPending = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (isCompleted)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2D5A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              )
            else if (isActive)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FEE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF65A30D), width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF65A30D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? const Color(0xFF1A2D5A) : const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isActive || isCompleted ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? const Color(0xFF65A30D)
                    : (isCompleted ? const Color(0xFF1A2D5A) : const Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? const Color(0xFF65A30D) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E40AF),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
