import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/driver_auth_service.dart';
import 'employee_main_navigation.dart';
import 'driver/driver_main_navigation.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _employeeIdCtrl = TextEditingController(text: 'EMP-9042');
  final _pinCtrl = TextEditingController(text: '123456');
  bool _isLoading = false;
  bool _isDriverRole = false;

  void _handleSignIn() {
    setState(() => _isLoading = true);
    final enteredId = _employeeIdCtrl.text.trim();
    if (_isDriverRole && enteredId.isNotEmpty) {
      DriverAuthService.instance.setDriverSession(driverId: enteredId);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _isDriverRole
                ? DriverMainNavigation(driverId: enteredId)
                : const EmployeeMainNavigation(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Brand Name
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF1A2D5A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF1A2D5A)).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'V',
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFCEE847),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Velora',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2D5A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Role Segment Switcher (Store Ops vs Delivery Driver)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isDriverRole = false;
                            _employeeIdCtrl.text = 'EMP-9042';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isDriverRole ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_isDriverRole
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront_rounded, size: 16, color: !_isDriverRole ? const Color(0xFF1A2D5A) : const Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Text(
                                  'Store Ops',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: !_isDriverRole ? const Color(0xFF1A2D5A) : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isDriverRole = true;
                            _employeeIdCtrl.text = 'CR-8942';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDriverRole ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isDriverRole
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_shipping_rounded, size: 16, color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF6B7280)),
                                const SizedBox(width: 6),
                                Text(
                                  'Driver Mode',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Login Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _isDriverRole ? 'Courier Driver Portal' : 'Employee Portal',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF1A2D5A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isDriverRole ? 'Sign in to access your delivery hub' : 'Sign in to access your dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Employee ID Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isDriverRole ? 'Courier Driver ID' : 'Employee ID',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _employeeIdCtrl,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: 'Enter your ID',
                          prefixIcon: Icon(_isDriverRole ? Icons.badge_rounded : Icons.badge_outlined, color: const Color(0xFF9CA3AF), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF1A2D5A), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Secure PIN Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Secure PIN',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2D5A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pinCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText: '6-digit PIN',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: _isDriverRole ? const Color(0xFF1B3E19) : const Color(0xFF1A2D5A), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8E635),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1A2D5A),
                                  ),
                                )
                              : Text(
                                  _isDriverRole ? 'Sign In as Driver' : 'Sign In',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A2D5A),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const SizedBox(height: 20),

                      // Help Footer Text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF6B7280)),
                          children: [
                            const TextSpan(text: 'Trouble signing in? '),
                            TextSpan(
                              text: 'Contact your supervisor',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A2D5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Bottom Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCEE847),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
