import 'package:flutter/material.dart';

/// An ultra-premium, official institutional 3D gold emblem medallion
/// designed for a government ministry/directorate.
///
/// Features executive luxury aesthetics:
/// - Multi-layered bevelled gold rim with metallic brushed depth
/// - Royal burgundy textured core
/// - Crisp official scales & shield crest
/// - Ultra-smooth, natural metallic sheen sweep (Apple / Luxury Coin style)
///   without any cartoonish star sparkles or neon outline lasers.
class GoldenEmblemCoin extends StatefulWidget {
  final double size;
  final bool showOuterGlow;
  final bool animateGleam;

  const GoldenEmblemCoin({
    super.key,
    this.size = 130.0,
    this.showOuterGlow = true,
    this.animateGleam = true,
  });

  @override
  State<GoldenEmblemCoin> createState() => _GoldenEmblemCoinState();
}

class _GoldenEmblemCoinState extends State<GoldenEmblemCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheenController;
  late Animation<double> _sheenProgress;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _sheenProgress = Tween<double>(begin: -0.6, end: 1.6).animate(
      CurvedAnimation(
        parent: _sheenController,
        // Sweep in first 40% of cycle, then rest smoothly for remaining 60%
        curve: const Interval(0.0, 0.42, curve: Curves.easeInOutCubic),
      ),
    );

    if (widget.animateGleam) {
      _sheenController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GoldenEmblemCoin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateGleam != oldWidget.animateGleam) {
      if (widget.animateGleam) {
        _sheenController.repeat();
      } else {
        _sheenController.stop();
      }
    }
  }

  @override
  void dispose() {
    _sheenController.dispose();
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
            // 1. Soft Warm Ambient Halo Glow
            if (widget.showOuterGlow)
              Container(
                width: s * 0.95,
                height: s * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
                      blurRadius: s * 0.22,
                      spreadRadius: s * 0.02,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: s * 0.16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

            // 2. Main 3D Medallion Coin with Sheen Mask
            ClipOval(
              child: SizedBox(
                width: s,
                height: s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Coin Base Layers
                    _buildCoinLayers(s),

                    // Natural Metallic Sheen Sweep Overlay
                    if (widget.animateGleam)
                      AnimatedBuilder(
                        animation: _sheenProgress,
                        builder: (context, child) {
                          final p = _sheenProgress.value;
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: _NaturalSheenPainter(progress: p),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinLayers(double s) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Heavy 3D Gold Outer Rim
        Container(
          width: s,
          height: s,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF6C2), // Specular Highlight
                Color(0xFFD4AF37), // Pure Gold
                Color(0xFFA87A13), // Deep Gold
                Color(0xFF634305), // Dark Bronze Bevel
                Color(0xFFD4AF37), // Accent
                Color(0xFFFFF9DB), // Corner Specular
              ],
              stops: [0.0, 0.22, 0.48, 0.72, 0.88, 1.0],
            ),
          ),
        ),

        // Precision Machined Inner Bevel Step
        Container(
          width: s * 0.92,
          height: s * 0.92,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                Color(0xFF523603), // Inverted shadow for 3D depth
                Color(0xFFB8860B),
                Color(0xFFFFDF79),
              ],
            ),
          ),
        ),

        // Gold Ring Spacer
        Container(
          width: s * 0.88,
          height: s * 0.88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE57F),
                Color(0xFFD4AF37),
                Color(0xFF8C5E06),
              ],
            ),
          ),
        ),

        // Deep Royal Burgundy Core Medallion
        Container(
          width: s * 0.84,
          height: s * 0.84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                Color(0xFF5E0C22), // Rich Velvet Burgundy
                Color(0xFF380513), // Deep Wine
                Color(0xFF1E020A), // Dark Onyx Burgundy Edge
              ],
              stops: [0.0, 0.65, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
        ),

        // Subtle Concentric Guilloché Pattern Line
        Container(
          width: s * 0.76,
          height: s * 0.76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
        ),

        // Official Crest / Insignia
        Center(
          child: SizedBox(
            width: s * 0.55,
            height: s * 0.55,
            child: CustomPaint(
              painter: _OfficialInsigniaPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders a natural, high-end metallic light reflection sheen across the surface
class _NaturalSheenPainter extends CustomPainter {
  final double progress;

  _NaturalSheenPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -0.4 || progress > 1.4) return;

    final w = size.width;
    final h = size.height;

    final rect = Rect.fromLTWH(0, 0, w, h);


    final sheenShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        const Color(0xFFFFF8D6).withValues(alpha: 0.0),
        const Color(0xFFFFF8D6).withValues(alpha: 0.12),
        const Color(0xFFFFFFFF).withValues(alpha: 0.35), // Polished highlight crest
        const Color(0xFFFFF8D6).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      stops: [
        (progress - 0.22).clamp(0.0, 1.0),
        (progress - 0.10).clamp(0.0, 1.0),
        (progress - 0.03).clamp(0.0, 1.0),
        progress.clamp(0.0, 1.0),
        (progress + 0.08).clamp(0.0, 1.0),
        (progress + 0.20).clamp(0.0, 1.0),
      ],
    ).createShader(rect);

    final sheenPaint = Paint()
      ..shader = sheenShader
      ..blendMode = BlendMode.screen;

    canvas.drawRect(rect, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant _NaturalSheenPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Renders a sharp, elegant 3D Scales of Justice & Shield state insignia in polished gold
class _OfficialInsigniaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Gold Shader for the icon
    final goldShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF9DB),
        Color(0xFFFFDF79),
        Color(0xFFD4AF37),
        Color(0xFFA67C1E),
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final goldPaint = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    // Draw Pillar of Balance / Law
    final pillarTop = cy - h * 0.38;
    final pillarBottom = cy + h * 0.38;

    // Subtle drop shadow under pillar
    canvas.drawLine(
      Offset(cx, pillarTop + 2),
      Offset(cx, pillarBottom + 2),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(cx, pillarTop),
      Offset(cx, pillarBottom),
      goldStroke,
    );

    // Finial Top Star / Diamond
    final starPath = Path();
    final starSize = w * 0.08;
    starPath.moveTo(cx, pillarTop - starSize);
    starPath.lineTo(cx + starSize * 0.7, pillarTop);
    starPath.lineTo(cx, pillarTop + starSize * 0.4);
    starPath.lineTo(cx - starSize * 0.7, pillarTop);
    starPath.close();
    canvas.drawPath(starPath, goldPaint);

    // Cross Beam
    final beamY = cy - h * 0.16;
    final beamHalfW = w * 0.36;
    canvas.drawLine(
      Offset(cx - beamHalfW, beamY + 1.5),
      Offset(cx + beamHalfW, beamY + 1.5),
      shadowPaint,
    );
    canvas.drawLine(
      Offset(cx - beamHalfW, beamY),
      Offset(cx + beamHalfW, beamY),
      goldStroke,
    );

    // Left Scale Pan & Strings
    final leftX = cx - beamHalfW;
    final panDrop = h * 0.30;
    final panY = beamY + panDrop;
    final panRadius = w * 0.16;

    final leftString1 = Path()..moveTo(leftX, beamY)..lineTo(leftX - panRadius * 0.8, panY);
    final leftString2 = Path()..moveTo(leftX, beamY)..lineTo(leftX + panRadius * 0.8, panY);
    final thinStroke = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawPath(leftString1, thinStroke);
    canvas.drawPath(leftString2, thinStroke);

    // Left Pan Bowl
    final leftBowl = Path()
      ..moveTo(leftX - panRadius, panY)
      ..quadraticBezierTo(leftX, panY + panRadius * 0.6, leftX + panRadius, panY)
      ..close();
    canvas.drawPath(leftBowl, goldPaint);

    // Right Scale Pan & Strings
    final rightX = cx + beamHalfW;
    final rightString1 = Path()..moveTo(rightX, beamY)..lineTo(rightX - panRadius * 0.8, panY);
    final rightString2 = Path()..moveTo(rightX, beamY)..lineTo(rightX + panRadius * 0.8, panY);
    canvas.drawPath(rightString1, thinStroke);
    canvas.drawPath(rightString2, thinStroke);

    // Right Pan Bowl
    final rightBowl = Path()
      ..moveTo(rightX - panRadius, panY)
      ..quadraticBezierTo(rightX, panY + panRadius * 0.6, rightX + panRadius, panY)
      ..close();
    canvas.drawPath(rightBowl, goldPaint);

    // Base Pedestal
    final baseW = w * 0.32;
    final baseY = pillarBottom;
    final baseStep = Path()
      ..moveTo(cx - baseW * 0.5, baseY)
      ..lineTo(cx + baseW * 0.5, baseY)
      ..lineTo(cx + baseW * 0.7, baseY + h * 0.05)
      ..lineTo(cx - baseW * 0.7, baseY + h * 0.05)
      ..close();
    canvas.drawPath(baseStep, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
