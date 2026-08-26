import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer_model.dart';
import 'firestore_customer_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? message;
  final CustomerModel? customer;
  final User? user;

  AuthResult({
    required this.isSuccess,
    this.message,
    this.customer,
    this.user,
  });
}

class FirebaseAuthService {
  static final FirebaseAuthService instance = FirebaseAuthService._();
  FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreCustomerService _firestoreService = FirestoreCustomerService.instance;

  /// Current authenticated Firebase User
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register user with Email and Password, then store profile in Firestore
  Future<AuthResult> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    double latitude = 0.0,
    double longitude = 0.0,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) {
        return AuthResult(
          isSuccess: false,
          message: 'Failed to retrieve Firebase user authentication ID.',
        );
      }

      // Optional: Update display name in Firebase Auth
      await user.updateDisplayName(fullName.trim());

      // 2. Build Customer Model with Firebase UID
      final customer = CustomerModel(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        latitude: latitude,
        longitude: longitude,
        role: 'customer',
        isActive: true,
        isVerified: true,
      );

      // 3. Store customer profile in Firestore collections 'customers/{uid}' & 'users/{uid}'
      await _firestoreService.createCustomerProfile(customer);

      return AuthResult(
        isSuccess: true,
        message: 'Account registered successfully!',
        customer: customer,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email address is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address entered is invalid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/Password sign-in is not enabled in Firebase Console.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network connection error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed. Code: ${e.code}';
      }
      return AuthResult(isSuccess: false, message: errorMessage);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'An unexpected error occurred during registration: ${e.toString()}',
      );
    }
  }

  /// Sign in existing customer with Email and Password
  Future<AuthResult> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;
      if (user == null) {
        return AuthResult(
          isSuccess: false,
          message: 'Failed to sign in. User account not found.',
        );
      }

      // Ensure customer details are saved/updated in Firestore collection 'customers/{uid}'
      final customer = await _firestoreService.saveOrUpdateCustomerOnLogin(user);

      return AuthResult(
        isSuccess: true,
        message: 'Login successful!',
        customer: customer,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Invalid email address or password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address format is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed login attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Code: ${e.code}';
      }
      return AuthResult(isSuccess: false, message: errorMessage);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message: 'An unexpected error occurred during login: ${e.toString()}',
      );
    }
  }

  /// Send Password Reset Email to customer
  Future<AuthResult> sendPasswordResetEmail({
    required String email,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return AuthResult(
        isSuccess: false,
        message: 'Please enter your email address.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return AuthResult(
        isSuccess: true,
        message:
            'A password reset link has been sent to your email. Please check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address format is invalid.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network connection error. Please check your internet connection.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many requests sent. Please wait a while before trying again.';
          break;
        default:
          errorMessage =
              e.message ?? 'Failed to send password reset email. Code: ${e.code}';
      }
      return AuthResult(isSuccess: false, message: errorMessage);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        message:
            'An unexpected error occurred while sending reset email: ${e.toString()}',
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
