import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for kiosk display
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Hide system UI for a full-screen kiosk experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const VeloraApp());
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora – Freshness. Simplified.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.outfitTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash / Kiosk Init Screen ──────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Progress bar animation controller
  late final AnimationController _progressController;
  late final Animation<double> _progressAnim;

  // Logo card fade + scale animation
  late final AnimationController _logoController;
  late final Animation<double> _logoFadeAnim;
  late final Animation<double> _logoScaleAnim;

  // Text fade animations
  late final AnimationController _textController;
  late final Animation<double> _titleFadeAnim;
  late final Animation<double> _subtitleFadeAnim;

  // Bottom label fade animation
  late final AnimationController _bottomController;
  late final Animation<double> _bottomFadeAnim;

  @override
  void initState() {
    super.initState();

    // ── Logo card entrance ──────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFadeAnim = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // ── Title + subtitle fade-in ────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFadeAnim = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _subtitleFadeAnim = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // ── Bottom label fade-in ────────────────────────────────────────
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bottomFadeAnim = CurvedAnimation(
      parent: _bottomController,
      curve: Curves.easeOut,
    );

    // ── Progress bar ────────────────────────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    // Staggered sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bottomController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _progressController.forward().whenComplete(() {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (ctx, anim, _) => const HomeScreen(),
                transitionsBuilder: (ctx, anim, _, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 700),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.25),
            radius: 1.1,
            colors: [
              Color(0xFFF8FDE8), // very light, almost white-yellow at center
              Color(0xFFE8F5A0), // soft lime-yellow mid
              Color(0xFFCEE847), // vivid lime-green at edges
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Main content – vertically centered with slight upward bias ──
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // ── Logo card ──────────────────────────────────
                    FadeTransition(
                      opacity: _logoFadeAnim,
                      child: ScaleTransition(
                        scale: _logoScaleAnim,
                        child: _LogoCard(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Brand name ────────────────────────────────
                    FadeTransition(
                      opacity: _titleFadeAnim,
                      child: const Text(
                        'VELORA',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: Color(0xFF111827),
                          height: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Tagline ───────────────────────────────────
                    FadeTransition(
                      opacity: _subtitleFadeAnim,
                      child: const Text(
                        'Freshness. Simplified.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF374151),
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom section ─────────────────────────────────────────────
              FadeTransition(
                opacity: _bottomFadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                  child: Column(
                    children: [
                      // Progress bar
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (context, _) {
                          return _AnimatedProgressBar(
                            progress: _progressAnim.value,
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // "Initializing Kiosk" label
                      const Text(
                        'INITIALIZING KIOSK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo Card Widget ─────────────────────────────────────────────────────────

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: Image.asset(
              'assests/velora.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Animated Progress Bar ────────────────────────────────────────────────────

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;

  const _AnimatedProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        return Stack(
          children: [
            // Track (subtle background)
            Container(
              width: trackWidth,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Filled portion
            Container(
              width: trackWidth * progress,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF8DC63F), // vivid lime-green
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8DC63F).withValues(alpha: 0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
