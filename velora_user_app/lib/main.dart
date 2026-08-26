import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/cart_service.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Cloud Firestore database connection
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  // Pre-load persistent cart database
  await CartService.instance.loadCart();

  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
    _logoScaleAnim = Tween<double>(begin: 0.80, end: 1.0).animate(
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
            final user = FirebaseAuthService.instance.currentUser;
            final Widget targetScreen =
            
                user != null ? const HomeScreen() : const RegisterScreen();
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (ctx, anim, _) => targetScreen,
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3FAAF), // pastel lime-yellow at top
              Color(0xFFE8F59F), // warm soft yellow-lime mid
              Color(0xFFDCF08A), // soft lime green
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Wavy Green Footer Background Layers ─────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: size.height * 0.28,
              child: CustomPaint(
                painter: _WavyGreenFooterPainter(),
              ),
            ),

            // ── Main Content Area ──────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // ── Logo Stack (Aura Glow + Leaves + White Card) ─────
                        FadeTransition(
                          opacity: _logoFadeAnim,
                          child: ScaleTransition(
                            scale: _logoScaleAnim,
                            child: SizedBox(
                              width: 320,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Translucent Circular Backdrop Glow
                                  Container(
                                    width: 270,
                                    height: 270,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFC7E86B).withValues(alpha: 0.35),
                                    ),
                                  ),

                                  // Leaves Artwork sticking out behind card
                                  CustomPaint(
                                    size: const Size(310, 260),
                                    painter: _LeavesArtworkPainter(),
                                  ),

                                  // Central White Logo Card
                                  _LogoCard(),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Brand Name Title ─────────────────────────────────
                        FadeTransition(
                          opacity: _titleFadeAnim,
                          child: Text(
                            'VELORA',
                            style: GoogleFonts.outfit(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              color: const Color(0xFF0F1E36),
                              height: 1.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Tagline Subtitle ──────────────────────────────────
                        FadeTransition(
                          opacity: _subtitleFadeAnim,
                          child: Text(
                            'Freshness. Simplified.',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                              letterSpacing: 0.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom Progress & Status Section ─────────────────────
                  FadeTransition(
                    opacity: _bottomFadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                      child: Column(
                        children: [
                          // Twin Leaf Sprout Icon
                          const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF4D7C1B),
                            size: 32,
                          ),

                          const SizedBox(height: 14),

                          // Animated Progress Bar
                          SizedBox(
                            width: 250,
                            child: AnimatedBuilder(
                              animation: _progressAnim,
                              builder: (context, _) {
                                return _AnimatedProgressBar(
                                  progress: _progressAnim.value,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Status Text
                          Text(
                            'INITIALIZING KIOSK',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.8,
                              color: const Color(0xFF3B5418),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── White Logo Card Widget ───────────────────────────────────────────────────

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      height: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF4D7C1B).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Image.asset(
            'assests/velora.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─── Leaves Artwork Painter ───────────────────────────────────────────────────

class _LeavesArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Left Leaves Group ────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(center.dx - 82, center.dy - 10);
    canvas.rotate(-0.38);
    _drawLeaf(
      canvas,
      length: 110,
      width: 48,
      baseColor: const Color(0xFF5A9420),
      tipColor: const Color(0xFF86C13B),
      veinColor: const Color(0xFF3C6A12),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx - 92, center.dy + 35);
    canvas.rotate(-0.75);
    _drawLeaf(
      canvas,
      length: 95,
      width: 42,
      baseColor: const Color(0xFF4D8318),
      tipColor: const Color(0xFF7CB830),
      veinColor: const Color(0xFF335C0D),
    );
    canvas.restore();

    // ── Right Leaves Group ───────────────────────────────────────────────────
    canvas.save();
    canvas.translate(center.dx + 82, center.dy - 5);
    canvas.rotate(0.38);
    _drawLeaf(
      canvas,
      length: 112,
      width: 48,
      baseColor: const Color(0xFF5B9621),
      tipColor: const Color(0xFF87C23C),
      veinColor: const Color(0xFF3C6B13),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx + 92, center.dy + 40);
    canvas.rotate(0.70);
    _drawLeaf(
      canvas,
      length: 90,
      width: 40,
      baseColor: const Color(0xFF4B8017),
      tipColor: const Color(0xFF7AB52F),
      veinColor: const Color(0xFF31580C),
    );
    canvas.restore();
  }

  void _drawLeaf(
    Canvas canvas, {
    required double length,
    required double width,
    required Color baseColor,
    required Color tipColor,
    required Color veinColor,
  }) {
    final path = Path();
    path.moveTo(0, 0);

    // Left curve of leaf
    path.cubicTo(
      -width * 0.55,
      length * 0.35,
      -width * 0.45,
      length * 0.75,
      0,
      length,
    );

    // Right curve of leaf back to base
    path.cubicTo(
      width * 0.45,
      length * 0.75,
      width * 0.55,
      length * 0.35,
      0,
      0,
    );

    path.close();

    // Leaf body gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [baseColor, tipColor],
      ).createShader(Rect.fromLTWH(-width / 2, 0, width, length));

    canvas.drawPath(path, fillPaint);

    // Central Stem Line
    final stemPaint = Paint()
      ..color = veinColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(0, length * 0.88), stemPaint);

    // Side Veins
    final veinBranchPaint = Paint()
      ..color = veinColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i <= 4; i++) {
      final y = length * (0.18 * i);
      final veinWidth = (width * 0.32) * (1 - (i * 0.15));

      // Left vein branch
      canvas.drawLine(
        Offset(0, y),
        Offset(-veinWidth, y + (length * 0.08)),
        veinBranchPaint,
      );

      // Right vein branch
      canvas.drawLine(
        Offset(0, y),
        Offset(veinWidth, y + (length * 0.08)),
        veinBranchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Wavy Green Footer Painter ───────────────────────────────────────────────

class _WavyGreenFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Wave 1: Top Light Lime Wave ──────────────────────────────────────────
    final wave1Path = Path()
      ..moveTo(0, h * 0.50)
      ..quadraticBezierTo(w * 0.28, h * 0.30, w * 0.58, h * 0.55)
      ..quadraticBezierTo(w * 0.82, h * 0.72, w, h * 0.42)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final wave1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF99C449),
          Color(0xFF86B339),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wave1Path, wave1Paint);

    // ── Wave 2: Middle Vibrant Green Wave ────────────────────────────────────
    final wave2Path = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.42, w * 0.68, h * 0.65)
      ..quadraticBezierTo(w * 0.88, h * 0.78, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final wave2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5B8F1D),
          Color(0xFF4C7B16),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wave2Path, wave2Paint);

    // ── Wave 3: Bottom Deep Forest Green Wave ────────────────────────────────
    final wave3Path = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.52, h * 0.76)
      ..quadraticBezierTo(w * 0.78, h * 0.88, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final wave3Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF33550E),
          Color(0xFF243F08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wave3Path, wave3Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            // Track (subtle background line)
            Container(
              width: trackWidth,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF3B5418).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Filled active portion
            Container(
              width: trackWidth * progress,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF4D7C1B),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4D7C1B).withValues(alpha: 0.5),
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
