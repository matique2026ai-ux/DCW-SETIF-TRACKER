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
      duration: const Duration(milliseconds: 3200),
    );

    // Realistic sweep: light sweeps across in first 45% of time, pauses naturally for 55%
    _sheenProgress = Tween<double>(begin: -0.8, end: 1.8).animate(
      CurvedAnimation(
        parent: _sheenController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOutSine),
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
            // 1. Warm Ambient Gold Halo Glow
            if (widget.showOuterGlow)
              Container(
                width: s * 0.95,
                height: s * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      blurRadius: s * 0.25,
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

            // 2. Main 3D Medallion Coin with Realistic Sheen
            ClipOval(
              child: SizedBox(
                width: s,
                height: s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Coin Base Structure & Emblem
                    _buildCoinLayers(s),

                    // Realistic Metallic Light Reflection Sweep
                    if (widget.animateGleam)
                      AnimatedBuilder(
                        animation: _sheenProgress,
                        builder: (context, child) {
                          final p = _sheenProgress.value;
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: _RealisticMetallicSheenPainter(progress: p),
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
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: s * 0.15,
            spreadRadius: s * 0.01,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: s * 0.1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/gold_emblem.jpg',
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/official_logo.jpg',
              width: s,
              height: s,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}

/// Renders a vivid, natural metallic specular sheen sweep that replicates
/// sunlight glinting across a polished gold coin.
class _RealisticMetallicSheenPainter extends CustomPainter {
  final double progress;

  _RealisticMetallicSheenPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -0.5 || progress > 1.5) return;

    final w = size.width;
    final h = size.height;
    final diag = w * 1.5;

    canvas.save();
    // Rotate canvas by -35 degrees to cast a realistic diagonal reflection angle
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.61); // ~ -35 degrees
    canvas.translate(-w / 2, -h / 2);

    // Calculate light beam position along the diagonal
    final currentX = progress * diag - (diag - w) / 2;
    final beamWidth = w * 0.42;

    final sheenRect = Rect.fromLTWH(
      currentX - beamWidth / 2,
      -h * 0.5,
      beamWidth,
      h * 2.0,
    );

    // Realistic multi-tier metallic reflection gradient
    final sheenShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        const Color(0xFFFFF7D6).withValues(alpha: 0.15), // Soft outer halo
        const Color(0xFFFFFBE8).withValues(alpha: 0.45), // Bright specular warm band
        Colors.white.withValues(alpha: 0.85),           // Intense diamond razor core
        const Color(0xFFFFFBE8).withValues(alpha: 0.45), // Trailing specular band
        const Color(0xFFFFF7D6).withValues(alpha: 0.15), // Trailing halo
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.20, 0.40, 0.50, 0.60, 0.80, 1.0],
    ).createShader(sheenRect);

    final sheenPaint = Paint()
      ..shader = sheenShader
      ..blendMode = BlendMode.screen;

    canvas.drawRect(sheenRect, sheenPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RealisticMetallicSheenPainter oldDelegate) =>
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
