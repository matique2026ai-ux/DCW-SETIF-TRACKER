import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/director/director_screen.dart';
import 'package:drh_setif_tracker/screens/head/head_screen.dart';
import 'package:drh_setif_tracker/screens/bureau/bureau_screen.dart';
import 'package:drh_setif_tracker/screens/inspector/inspector_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _barController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _fadeOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _rotateAngle;
  late Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _textSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _fadeOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateAngle = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));
    _barProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeInOut));

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    final auth = context.read<AuthService>();
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fadeController.forward();
    _barController.forward();

    // Check auto-login session in parallel
    bool autoLoggedIn = false;
    try {
      autoLoggedIn = await auth.tryAutoLogin();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Widget targetScreen = const LoginScreen();
      if (autoLoggedIn) {
        switch (auth.currentUser?.role) {
          case 'admin':
          case 'director':
            targetScreen = const DirectorScreen();
            break;
          case 'head_of_department':
            targetScreen = const HeadScreen();
            break;
          case 'bureau_chief':
            targetScreen = const BureauScreen();
            break;
          default:
            targetScreen = const InspectorScreen();
        }
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => targetScreen,
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF1A0A1F),
              Color(0xFF2D1035),
              Color(0xFF881337),
              Color(0xFF4C0519),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Rotating background ring
            AnimatedBuilder(
              animation: _rotateAngle,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _RotatingRingPainter(angle: _rotateAngle.value),
                );
              },
            ),

            // Floating particles
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _ParticlesPainter(pulse: _pulseScale.value),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Golden ring around logo
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFD4AF37),
                                Color(0xFFFDE68A),
                                Color(0xFFD4AF37),
                                Color(0xFF92400E),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF1A0A1F),
                                    Color(0xFF2D1035),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _logoScale,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _logoScale.value,
                                      child: Opacity(
                                        opacity: _logoOpacity.value,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shield_outlined,
                                              size: 52,
                                              color: Color(0xFFD4AF37),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'DCW',
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFD4AF37),
                                                letterSpacing: 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // Directorat name
                  AnimatedBuilder(
                    animation: _textSlide,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                loc.splashDirectorate,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.isArabic ? 'ولاية سطيف' : 'Wilaya de Sétif',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // App title
                  AnimatedBuilder(
                    animation: _textSlide,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlide.value + 10),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Text(
                            loc.isArabic
                                ? 'منصة الرقابة والتفتيش الميداني'
                                : 'Plateforme de Contrôle et d\'Inspection',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Loading bar
                  AnimatedBuilder(
                    animation: _fadeOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeOpacity.value,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _barProgress,
                              builder: (context, child) {
                                return Container(
                                  width: 200,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerRight,
                                    widthFactor: _barProgress.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD4AF37),
                                            Color(0xFFFDE68A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              loc.isArabic
                                  ? 'جاري التحميل...'
                                  : 'Chargement...',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Version at bottom
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeOpacity,
                child: Text(
                  'v2.0.0 • DCW-SETIF-TRACKER',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotatingRingPainter extends CustomPainter {
  final double angle;
  _RotatingRingPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + pi,
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.0),
          const Color(0xFFD4AF37).withValues(alpha: 0.3),
          const Color(0xFFD4AF37).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingRingPainter oldDelegate) =>
      oldDelegate.angle != angle;
}

class _ParticlesPainter extends CustomPainter {
  final double pulse;
  _ParticlesPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = (random.nextDouble() * 2 + 0.5) * pulse;
      final opacity = (random.nextDouble() * 0.15 + 0.05) * pulse;

      paint.color = const Color(0xFFD4AF37).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
