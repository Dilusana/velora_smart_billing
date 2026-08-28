import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/customer_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_customer_service.dart';
import '../widgets/address_picker_modal.dart';
import 'auth/login_screen.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data ?? FirebaseAuthService.instance.currentUser;

        if (firebaseUser == null) {
          return _buildUnauthenticatedState(context);
        }

        return StreamBuilder<CustomerModel?>(
          stream: FirestoreCustomerService.instance.streamCustomerProfile(firebaseUser.uid),
          builder: (context, customerSnapshot) {
            if (customerSnapshot.connectionState == ConnectionState.waiting && !customerSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFFF5F2E8),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF3A5A2A)),
                ),
              );
            }

            final customer = customerSnapshot.data ??
                CustomerModel(
                  uid: firebaseUser.uid,
                  fullName: firebaseUser.displayName?.isNotEmpty == true
                      ? firebaseUser.displayName!
                      : (firebaseUser.email?.contains('@') == true
                          ? firebaseUser.email!.split('@').first
                          : 'Customer'),
                  email: firebaseUser.email ?? '',
                  phone: firebaseUser.phoneNumber ?? '',
                  address: '',
                  photoUrl: firebaseUser.photoURL ?? '',
                );

            return _buildAuthenticatedProfile(context, customer);
          },
        );
      },
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    _IconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  const Spacer(),
                  Text(
                    'My Profile',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3A5A2A),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF5C8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 44,
                            color: Color(0xFF3A5A2A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Not Logged In',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please log in or register an account to view and manage your profile details.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (ctx, anim, anim2) => const LoginScreen(),
                                  transitionsBuilder: (ctx, anim, anim2, child) => FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A5A2A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Sign In / Register',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
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
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, CustomerModel customer) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2E8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          _IconBtn(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          )
                        else
                          _IconBtn(
                            icon: Icons.menu_rounded,
                            onTap: () {},
                          ),
                        const Spacer(),
                        Text(
                          'My Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3A5A2A),
                          ),
                        ),
                        const Spacer(),
                        _IconBtn(
                          icon: Icons.edit_outlined,
                          onTap: () => _showEditProfileModal(context, customer),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Profile Header ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCEE847),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarImage(customer.photoUrl),
                            ),
                          ),
                          // Edit button
                          GestureDetector(
                            onTap: () => _showEditProfileModal(context, customer),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3A5A2A),
                                border: Border.all(
                                  color: const Color(0xFFF5F2E8),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: Color(0xFFCEE847),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Name
                      Text(
                        customer.fullName.isNotEmpty ? customer.fullName : 'Customer',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Email & Phone
                      Text(
                        customer.email.isNotEmpty ? customer.email : 'No email provided',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      if (customer.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.phone,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A5A2A),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Customer Member Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFDE68A), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 14,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'VERIFIED CUSTOMER',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Stats Row ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF5C8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const _StatTile(value: 'Active', label: 'STATUS'),
                          _StatDivider(),
                          const _StatTile(value: 'Verified', label: 'ACCOUNT'),
                          _StatDivider(),
                          _StatTile(value: customer.role.toUpperCase(), label: 'ROLE'),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Personal Information ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MenuSection(
                      label: 'PERSONAL INFORMATION',
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Full Name',
                          trailingLabel: customer.fullName.isNotEmpty ? customer.fullName : 'Add Name',
                          onTap: () => _showEditProfileModal(context, customer),
                        ),
                        _MenuItem(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          trailingLabel: customer.phone.isNotEmpty ? customer.phone : 'Add Phone',
                          onTap: () => _showEditProfileModal(context, customer),
                        ),
                        _MenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          trailingLabel: customer.address.isNotEmpty ? customer.address : 'Add Address',
                          onTap: () => _showEditAddressModal(context, customer),
                        ),
                        _MenuItem(
                          icon: Icons.map_rounded,
                          title: 'Navigate on Google Maps',
                          trailingLabel: customer.latitude != 0.0 ? 'Lat: ${customer.latitude.toStringAsFixed(2)}, Lng: ${customer.longitude.toStringAsFixed(2)}' : 'Open Google Maps',
                          onTap: () => _openGoogleMapsAddress(customer),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // ── Account & Security ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MenuSection(
                      label: 'ACCOUNT & SECURITY',
                      items: [
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          onTap: () => _showChangePasswordModal(context, customer.email),
                        ),
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          isDestructive: true,
                          showChevron: false,
                          onTap: () => _showLogoutDialog(context),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Clean bottom margin without bottom nav bar overlap
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String photoUrl) {
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
      );
    } else if (photoUrl.isNotEmpty) {
      return Image.asset(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFEEF5C8),
      child: const Icon(
        Icons.person_rounded,
        size: 52,
        color: Color(0xFF3A5A2A),
      ),
    );
  }

  Future<void> _openGoogleMapsAddress(CustomerModel customer) async {
    final Uri url;
    if (customer.latitude != 0.0 && customer.longitude != 0.0) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${customer.latitude},${customer.longitude}');
    } else {
      final query = customer.address.isNotEmpty ? customer.address : 'Main Street, Springfield';
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Google Maps launch error: $e');
    }
  }

  void _showEditAddressModal(BuildContext context, CustomerModel customer) async {
    final result = await AddressPickerModal.show(
      context,
      initialAddress: customer.address,
      initialLatitude: customer.latitude,
      initialLongitude: customer.longitude,
    );

    if (result != null && context.mounted) {
      try {
        await FirestoreCustomerService.instance.updateCustomerAddress(
          uid: customer.uid,
          address: result.address,
          latitude: result.latitude,
          longitude: result.longitude,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address updated successfully.', style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: const Color(0xFF3A5A2A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update address: $e', style: GoogleFonts.outfit(color: Colors.white)),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ─── Edit Profile Modal ────────────────────────────────────────────────────

  void _showEditProfileModal(BuildContext context, CustomerModel customer) {
    final nameCtrl = TextEditingController(text: customer.fullName);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final addressCtrl = TextEditingController(text: customer.address);
    double selectedLat = customer.latitude;
    double selectedLng = customer.longitude;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_rounded, color: Color(0xFF2563EB)),
                      tooltip: 'Select Address on Map',
                      onPressed: () async {
                        final res = await AddressPickerModal.show(
                          ctx,
                          initialAddress: addressCtrl.text,
                          initialLatitude: selectedLat,
                          initialLongitude: selectedLng,
                        );
                        if (res != null) {
                          setModalState(() {
                            addressCtrl.text = res.address;
                            selectedLat = res.latitude;
                            selectedLng = res.longitude;
                          });
                        }
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            try {
                              await FirestoreCustomerService.instance.updateCustomerProfile(
                                uid: customer.uid,
                                fullName: nameCtrl.text,
                                phone: phoneCtrl.text,
                                address: addressCtrl.text,
                                latitude: selectedLat,
                                longitude: selectedLng,
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile updated successfully!')),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update profile: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A5A2A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Change Password Modal ─────────────────────────────────────────────────

  void _showChangePasswordModal(BuildContext context, String email) {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address associated with this account.')),
      );
      return;
    }

    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Change Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
            content: Text(
              'A password reset link will be sent to your registered email address:\n\n$email\n\nFollow the instructions in the email to update your password.',
              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF4B5563)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        setModalState(() => isSending = true);
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Password reset email sent to $email!')),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSending = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send reset email: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A5A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Logout Dialog ────────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFDC2626), size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                'Log Out?',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await FirebaseAuthService.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder: (ctx, anim, anim2) => const LoginScreen(),
                              transitionsBuilder: (ctx, anim, anim2, child) => FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3A5A2A), size: 20),
      ),
    );
  }
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF3A5A2A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Divider ─────────────────────────────────────────────────────────────

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFF3A5A2A).withValues(alpha: 0.18),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;

  const _MenuSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.7,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? trailingLabel;
  final bool isDestructive;
  final bool showChevron;
  final bool isLast;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.trailingLabel,
    this.isDestructive = false,
    this.showChevron = true,
    this.isLast = false,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final iconColor = widget.isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF3A5A2A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF9F9F6) : Colors.transparent,
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  if (widget.trailingLabel != null) ...[
                    Flexible(
                      child: Text(
                        widget.trailingLabel!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (widget.showChevron)
                    const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
            if (!widget.isLast)
              const Padding(
                padding: EdgeInsets.only(left: 52),
                child: Divider(
                  height: 1,
                  color: Color(0xFFF3F4F6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
