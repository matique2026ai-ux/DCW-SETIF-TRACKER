import 'package:flutter/material.dart';

/// An ultra-premium, official institutional 3D gold emblem medallion
/// designed for a government ministry/directorate.
///
/// Features clean, executive aesthetics:
/// - Multi-layered bevelled gold rim with metallic brushed depth
/// - Royal burgundy textured core
/// - Crisp official scales & shield crest
/// - Elegant static depth with soft ambient shadow (zero cartoonish sparkles/sweeps)
class GoldenEmblemCoin extends StatelessWidget {
  final double size;
  final bool showOuterGlow;

  const GoldenEmblemCoin({
    super.key,
    this.size = 130.0,
    this.showOuterGlow = true,
    bool animateGleam = false, // Kept for backwards compatibility
  });

  @override
  Widget build(BuildContext context) {
    final s = size;

    return Center(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Soft Warm Ambient Shadow
            if (showOuterGlow)
              Container(
                width: s * 0.95,
                height: s * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.20),
                      blurRadius: s * 0.20,
                      spreadRadius: s * 0.02,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: s * 0.15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

            // 2. Heavy 3D Gold Outer Rim
            Container(
              width: s,
              height: s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF3B0), // Highlight
                    Color(0xFFD4AF37), // Pure Gold
                    Color(0xFFAA7C11), // Deep Gold
                    Color(0xFF664606), // Dark Bronze Bevel
                    Color(0xFFD4AF37), // Accent
                    Color(0xFFFFF8D6), // Corner Specular
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 0.9, 1.0],
                ),
              ),
            ),

            // 3. Precision Machined Inner Bevel Step
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

            // 4. Gold Ring Spacer
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

            // 5. Deep Royal Burgundy Core Medallion
            Container(
              width: s * 0.84,
              height: s * 0.84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Color(0xFF5A0B20), // Rich Velvet Burgundy
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

            // 6. Subtle Concentric Guilloché Pattern Line
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

            // 7. Official Crest / Insignia
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
        ),
      ),
    );
  }
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
