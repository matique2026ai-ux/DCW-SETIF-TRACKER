import 'dart:math';
import 'package:flutter/material.dart';

/// A luxury 3D pure gold coin medallion displaying the official emblem
/// with natural metallic shimmer, bevel reflections, and sparkle glints.
class GoldenEmblemCoin extends StatefulWidget {
  final double size;
  final bool animateGleam;
  final bool showOuterGlow;

  const GoldenEmblemCoin({
    super.key,
    this.size = 180.0,
    this.animateGleam = true,
    this.showOuterGlow = true,
  });

  @override
  State<GoldenEmblemCoin> createState() => _GoldenEmblemCoinState();
}

class _GoldenEmblemCoinState extends State<GoldenEmblemCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _gleamController;
  late Animation<double> _gleamAnimation;

  @override
  void initState() {
    super.initState();
    _gleamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _gleamAnimation = Tween<double>(begin: -1.2, end: 2.2).animate(
      CurvedAnimation(parent: _gleamController, curve: Curves.easeInOutSine),
    );

    if (widget.animateGleam) {
      _gleamController.repeat(reverse: false);
    }
  }

  @override
  void dispose() {
    _gleamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return Center(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Ambient Warm Golden Halo Glow
            if (widget.showOuterGlow)
              Container(
                width: s * 0.95,
                height: s * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      blurRadius: s * 0.28,
                      spreadRadius: s * 0.04,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.2),
                      blurRadius: s * 0.45,
                      spreadRadius: s * 0.08,
                    ),
                  ],
                ),
              ),

            // 2. 3D Solid Gold Coin Rim and Bevels
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  center: Alignment.center,
                  colors: [
                    Color(0xFFFFDF73), // Bright Gold
                    Color(0xFFC99723), // Deep Gold
                    Color(0xFF8B5E0D), // Bronze Shadow
                    Color(0xFFFFDF73), // Specular Peak
                    Color(0xFFC99723),
                    Color(0xFF8B5E0D),
                    Color(0xFFFFDF73),
                  ],
                  stops: [0.0, 0.2, 0.45, 0.55, 0.75, 0.9, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: s * 0.12,
                    offset: Offset(0, s * 0.05),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    blurRadius: s * 0.06,
                    offset: Offset(-s * 0.015, -s * 0.015),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CoinSerrationPainter(),
                child: Padding(
                  padding: EdgeInsets.all(s * 0.024),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF2A8),
                          Color(0xFFD4AF37),
                          Color(0xFFA17417),
                          Color(0xFF5D3F08),
                        ],
                        stops: [0.0, 0.35, 0.75, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(s * 0.016),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF140D05),
                        ),
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 3. The 3D Pure Gold Bullion Emblem Asset
                              Image.asset(
                                'assets/images/gold_emblem.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback official emblem or vector rendering
                                  return Image.asset(
                                    'assets/images/official_logo.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.shield_outlined,
                                        color: Color(0xFFFFD700),
                                        size: 60,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 4. Fine Metallic Radial Inner Shadow for 3D Inset Depth
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.0),
                                        Colors.black.withValues(alpha: 0.35),
                                      ],
                                      stops: const [0.0, 0.82, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // 5. Sweeping Specular Gleam / Natural Shimmer
                              if (widget.animateGleam)
                                AnimatedBuilder(
                                  animation: _gleamAnimation,
                                  builder: (context, child) {
                                    final progress = _gleamAnimation.value;
                                    return ClipOval(
                                      child: ShaderMask(
                                        blendMode: BlendMode.screen,
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment(progress - 0.7, -1.0),
                                            end: Alignment(progress + 0.7, 1.0),
                                            colors: [
                                              Colors.transparent,
                                              const Color(0xFFFFE082).withValues(alpha: 0.0),
                                              const Color(0xFFFFF9C4).withValues(alpha: 0.45),
                                              Colors.white.withValues(alpha: 0.85),
                                              const Color(0xFFFFF9C4).withValues(alpha: 0.45),
                                              const Color(0xFFFFE082).withValues(alpha: 0.0),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.35, 0.46, 0.50, 0.54, 0.65, 1.0],
                                          ).createShader(bounds);
                                        },
                                        child: Container(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // 6. Dynamic Corner Star Glint
                              if (widget.animateGleam)
                                AnimatedBuilder(
                                  animation: _gleamAnimation,
                                  builder: (context, child) {
                                    final p = _gleamAnimation.value;
                                    // Flare glint at peak sweep
                                    final glintOpacity = (1.0 - (p - 0.5).abs() * 4).clamp(0.0, 1.0);
                                    if (glintOpacity <= 0.01) return const SizedBox.shrink();

                                    return Positioned(
                                      top: s * 0.12,
                                      right: s * 0.18,
                                      child: Opacity(
                                        opacity: glintOpacity,
                                        child: Transform.rotate(
                                          angle: p * pi,
                                          child: CustomPaint(
                                            size: Size(s * 0.18, s * 0.18),
                                            painter: _StarGlintPainter(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws fine coin rim serrations and coin grooves
class _CoinSerrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const numTeeth = 100;

    final paintLight = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintDark = Paint()
      ..color = const Color(0xFF4E342E).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < numTeeth; i++) {
      final angle = (i * 2 * pi) / numTeeth;
      final cosA = cos(angle);
      final sinA = sin(angle);

      final p1 = Offset(center.dx + (radius - 2.5) * cosA, center.dy + (radius - 2.5) * sinA);
      final p2 = Offset(center.dx + radius * cosA, center.dy + radius * sinA);

      if (i % 2 == 0) {
        canvas.drawLine(p1, p2, paintLight);
      } else {
        canvas.drawLine(p1, p2, paintDark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Star glint / lens flare reflection
class _StarGlintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFF9C4).withValues(alpha: 0.8),
          const Color(0xFFFFD54F).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, glowPaint);

    final rayPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // 4-point lens rays
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), rayPaint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), rayPaint);

    // Diagonal mini rays
    final rayPaintMini = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    const diag = 0.55;
    canvas.drawLine(
      Offset(center.dx - r * diag, center.dy - r * diag),
      Offset(center.dx + r * diag, center.dy + r * diag),
      rayPaintMini,
    );
    canvas.drawLine(
      Offset(center.dx - r * diag, center.dy + r * diag),
      Offset(center.dx + r * diag, center.dy - r * diag),
      rayPaintMini,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
