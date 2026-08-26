import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/employee_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const VeloraEmployeeApp());
}

class VeloraEmployeeApp extends StatelessWidget {
  const VeloraEmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora Employee Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F3EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2D5A),
          primary: const Color(0xFF1A2D5A),
          secondary: const Color(0xFFCEE847),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        useMaterial3: true,
      ),
      home: const EmployeeLoginScreen(),
    );
  }
}
