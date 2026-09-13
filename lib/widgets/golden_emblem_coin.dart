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
      duration: const Duration(milliseconds: 3000),
    );

    _gleamAnimation = Tween<double>(begin: -0.8, end: 1.8).animate(
      CurvedAnimation(parent: _gleamController, curve: Curves.easeInOutSine),
    );

    if (widget.animateGleam) {
      _gleamController.repeat();
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
                width: s * 0.94,
                height: s * 0.94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                      blurRadius: s * 0.25,
                      spreadRadius: s * 0.05,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.25),
                      blurRadius: s * 0.40,
                      spreadRadius: s * 0.08,
                    ),
                  ],
                ),
              ),

            // 2. 3D Solid Gold Bullion Coin Outer Rim
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  center: Alignment.center,
                  colors: [
                    Color(0xFFFFE885), // Bright Gold
                    Color(0xFFC99723), // Deep Gold
                    Color(0xFF8B5E0D), // Bronze Shadow
                    Color(0xFFFFE885), // Specular Peak
                    Color(0xFFC99723),
                    Color(0xFF8B5E0D),
                    Color(0xFFFFE885),
                  ],
                  stops: [0.0, 0.2, 0.45, 0.55, 0.75, 0.9, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: s * 0.12,
                    offset: Offset(0, s * 0.05),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(s * 0.035),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF4B8),
                        Color(0xFFD4AF37),
                        Color(0xFFA17417),
                        Color(0xFF5D3F08),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(s * 0.02),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 3. Official 3D Pure Gold Emblem Image
                          Image.asset(
                            'assets/images/gold_emblem.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/official_logo.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1E102F),
                                  child: const Center(
                                    child: Icon(
                                      Icons.shield,
                                      color: Color(0xFFD4AF37),
                                      size: 50,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // 4. Subtle Inset Radial Depth Shadow
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                  stops: const [0.0, 0.80, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // 5. Dynamic Light Sweep Overlay (Gleam Shimmer)
                          if (widget.animateGleam)
                            AnimatedBuilder(
                              animation: _gleamAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _GleamSweepPainter(
                                    progress: _gleamAnimation.value,
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
                                final glintOpacity =
                                    (1.0 - (p - 0.5).abs() * 3.5).clamp(0.0, 1.0);
                                if (glintOpacity <= 0.02) {
                                  return const SizedBox.shrink();
                                }

                                return Positioned(
                                  top: s * 0.14,
                                  right: s * 0.16,
                                  child: Opacity(
                                    opacity: glintOpacity,
                                    child: Transform.rotate(
                                      angle: p * pi * 1.5,
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
          ],
        ),
      ),
    );
  }
}

/// Paints a luminous sweeping shine band across the coin
class _GleamSweepPainter extends CustomPainter {
  final double progress;

  _GleamSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -0.6 || progress > 1.6) return;

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(progress - 0.6, -1.0),
        end: Alignment(progress + 0.6, 1.0),
        colors: [
          Colors.transparent,
          const Color(0xFFFFE082).withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.35),
          const Color(0xFFFFE082).withValues(alpha: 0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.48, 0.50, 0.52, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GleamSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Paints a sharp 8-pointed golden star sparkle
class _StarGlintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width / 2;

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFF9C4),
          const Color(0xFFFFD54F).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));

    canvas.drawCircle(Offset(cx, cy), maxR * 0.45, corePaint);

    final rayPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;

    // 4 Long Cardinal Rays
    rayPaint.strokeWidth = 2.0;
    canvas.drawLine(Offset(cx, cy - maxR), Offset(cx, cy + maxR), rayPaint);
    canvas.drawLine(Offset(cx - maxR, cy), Offset(cx + maxR, cy), rayPaint);

    // 4 Medium Diagonal Rays
    rayPaint.strokeWidth = 1.2;
    final diagR = maxR * 0.6;
    canvas.drawLine(
      Offset(cx - diagR, cy - diagR),
      Offset(cx + diagR, cy + diagR),
      rayPaint,
    );
    canvas.drawLine(
      Offset(cx - diagR, cy + diagR),
      Offset(cx + diagR, cy - diagR),
      rayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
