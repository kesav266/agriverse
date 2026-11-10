import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Enum of all AgriVerse AI feature card illustration types.
enum CardIllustrationType {
  cropHealth,
  cropRecommendation,
  weather,
  irrigation,
  yieldProfit,
  aiAssistant,
  farmProfile,
  fertilizer,
  marketPrices,
  govSchemes,
}

/// A scale-invariant, responsive vector illustration widget for feature cards.
/// Regardless of card width or aspect ratio, artwork stays perfectly centered,
/// proportional, and visually balanced without distortion.
class CardIllustration extends StatelessWidget {
  final CardIllustrationType type;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const CardIllustration({
    super.key,
    required this.type,
    this.height = 110,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: borderRadius ?? const BorderRadius.vertical(top: Radius.circular(20)),
        child: CustomPaint(
          painter: _getIllustrationPainter(type),
        ),
      ),
    );
  }

  CustomPainter _getIllustrationPainter(CardIllustrationType type) {
    switch (type) {
      case CardIllustrationType.cropHealth:
        return const _CropHealthPainter();
      case CardIllustrationType.cropRecommendation:
        return const _CropRecommendationPainter();
      case CardIllustrationType.weather:
        return const _WeatherPainter();
      case CardIllustrationType.irrigation:
        return const _IrrigationPainter();
      case CardIllustrationType.yieldProfit:
        return const _YieldProfitPainter();
      case CardIllustrationType.aiAssistant:
        return const _AiAssistantPainter();
      case CardIllustrationType.farmProfile:
        return const _FarmProfilePainter();
      case CardIllustrationType.fertilizer:
        return const _FertilizerPainter();
      case CardIllustrationType.marketPrices:
        return const _MarketPricesPainter();
      case CardIllustrationType.govSchemes:
        return const _GovSchemesPainter();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 1. CROP HEALTH DIAGNOSIS — Centered leaf with AI scan beam & crosshairs
// ─────────────────────────────────────────────────────────────
class _CropHealthPainter extends CustomPainter {
  const _CropHealthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;
    // Scale unit based on height so it never stretches horizontally
    final s = h * 0.42;

    // Background gradient — soft forest mist
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle ambient background circles
    final auraPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx - s * 1.2, cy - s * 0.4), s * 0.8, auraPaint);
    canvas.drawCircle(Offset(cx + s * 1.4, cy + s * 0.3), s * 0.6, auraPaint);

    // Leaf stem
    final stemPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(cx - s * 0.4, cy + s * 0.8)
      ..quadraticBezierTo(cx - s * 0.1, cy + s * 0.3, cx + s * 0.2, cy - s * 0.7);
    canvas.drawPath(stemPath, stemPaint);

    // Main central lush leaf (curving gracefully, proportional to 's')
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    final leafPath = Path()
      ..moveTo(cx - s * 0.3, cy + s * 0.65)
      ..cubicTo(
        cx - s * 0.9, cy + s * 0.1,
        cx - s * 0.6, cy - s * 0.5,
        cx + s * 0.2, cy - s * 0.7,
      )
      ..cubicTo(
        cx + s * 0.6, cy - s * 0.2,
        cx + s * 0.4, cy + s * 0.4,
        cx - s * 0.3, cy + s * 0.65,
      );
    canvas.drawPath(leafPath, leafPaint);

    // Secondary lighter leaf
    final leaf2Paint = Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.85);
    final leaf2Path = Path()
      ..moveTo(cx - s * 0.2, cy + s * 0.4)
      ..cubicTo(
        cx + s * 0.3, cy + s * 0.3,
        cx + s * 0.8, cy - s * 0.1,
        cx + s * 0.6, cy - s * 0.5,
      )
      ..cubicTo(
        cx + s * 0.2, cy - s * 0.3,
        cx - s * 0.1, cy + s * 0.1,
        cx - s * 0.2, cy + s * 0.4,
      );
    canvas.drawPath(leaf2Path, leaf2Paint);

    // Leaf central vein
    final veinPaint = Paint()
      ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.6)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(stemPath, veinPaint);

    // Disease symptom spots
    final spotPaint = Paint()..color = const Color(0xFFE65100).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx - s * 0.25, cy - s * 0.1), s * 0.10, spotPaint);
    canvas.drawCircle(Offset(cx - s * 0.05, cy + s * 0.12), s * 0.07, spotPaint);
    canvas.drawCircle(Offset(cx - s * 0.40, cy + s * 0.18), s * 0.08, spotPaint);

    // AI Laser Scan line (horizontal radiant green beam)
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E676).withValues(alpha: 0.8),
          Colors.white,
          const Color(0xFF00E676).withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(cx - s * 1.5, cy - s * 0.05, s * 3.0, 3));
    canvas.drawRect(Rect.fromLTWH(cx - s * 1.5, cy - s * 0.05, s * 3.0, 2.5), scanLinePaint);

    // AI Corner Bracket Target Box around the symptom
    final targetPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bx = cx - s * 0.25;
    final by = cy - s * 0.08;
    final tr = s * 0.38;
    final bLen = s * 0.14;

    // Top-left
    canvas.drawLine(Offset(bx - tr, by - tr + bLen), Offset(bx - tr, by - tr), targetPaint);
    canvas.drawLine(Offset(bx - tr, by - tr), Offset(bx - tr + bLen, by - tr), targetPaint);
    // Top-right
    canvas.drawLine(Offset(bx + tr - bLen, by - tr), Offset(bx + tr, by - tr), targetPaint);
    canvas.drawLine(Offset(bx + tr, by - tr), Offset(bx + tr, by - tr + bLen), targetPaint);
    // Bottom-left
    canvas.drawLine(Offset(bx - tr, by + tr - bLen), Offset(bx - tr, by + tr), targetPaint);
    canvas.drawLine(Offset(bx - tr, by + tr), Offset(bx - tr + bLen, by + tr), targetPaint);
    // Bottom-right
    canvas.drawLine(Offset(bx + tr - bLen, by + tr), Offset(bx + tr, by + tr), targetPaint);
    canvas.drawLine(Offset(bx + tr, by + tr), Offset(bx + tr, by + tr - bLen), targetPaint);

    // Small status pill badge inside illustration
    final badgeBg = Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.85);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + s * 1.1, cy - s * 0.6), width: s * 1.2, height: s * 0.45),
      const Radius.circular(8),
    );
    canvas.drawRRect(badgeRect, badgeBg);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'AI SCAN',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx + s * 1.1 - tp.width / 2, cy - s * 0.6 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 2. CROP RECOMMENDATION — 3 Sprouting crops + AI selection star
// ─────────────────────────────────────────────────────────────
class _CropRecommendationPainter extends CustomPainter {
  const _CropRecommendationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;
    final s = h * 0.42;

    // Warm golden cream gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFE082)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Rich curved soil mound
    final soilPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
      ).createShader(Rect.fromLTWH(0, cy + s * 0.45, w, h - (cy + s * 0.45)));
    final soilPath = Path()
      ..moveTo(0, cy + s * 0.55)
      ..quadraticBezierTo(cx, cy + s * 0.35, w, cy + s * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(soilPath, soilPaint);

    // Draw 3 distinct crops centered around cx:
    _drawCropPlant(canvas, Offset(cx - s * 0.9, cy + s * 0.45), s * 0.8, const Color(0xFF558B2F), 0);
    _drawCropPlant(canvas, Offset(cx, cy + s * 0.40), s * 1.1, const Color(0xFF2E7D32), 1);
    _drawCropPlant(canvas, Offset(cx + s * 0.9, cy + s * 0.45), s * 0.85, const Color(0xFF388E3C), 2);

    // Glowing recommendation star above the central crop
    final starCenter = Offset(cx, cy - s * 0.65);
    final glowPaint = Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.3);
    canvas.drawCircle(starCenter, s * 0.35, glowPaint);

    // Check badge circle
    final checkCircle = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(starCenter, s * 0.22, checkCircle);
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final checkPath = Path()
      ..moveTo(starCenter.dx - s * 0.09, starCenter.dy)
      ..lineTo(starCenter.dx - s * 0.02, starCenter.dy + s * 0.08)
      ..lineTo(starCenter.dx + s * 0.10, starCenter.dy - s * 0.07);
    canvas.drawPath(checkPath, checkPaint);

    // Sparkles
    _drawSparkle(canvas, Offset(cx - s * 0.4, cy - s * 0.4), s * 0.12, const Color(0xFFF59E0B));
    _drawSparkle(canvas, Offset(cx + s * 0.5, cy - s * 0.35), s * 0.10, const Color(0xFFF59E0B));
  }

  void _drawCropPlant(Canvas canvas, Offset base, double height, Color color, int type) {
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Stem
    canvas.drawLine(base, Offset(base.dx, base.dy - height), stemPaint);

    if (type == 1) {
      // Golden grain head
      final headCenter = Offset(base.dx, base.dy - height + 4);
      canvas.drawOval(
        Rect.fromCenter(center: headCenter, width: height * 0.28, height: height * 0.55),
        Paint()..color = const Color(0xFFF9A825),
      );
      // Leaves
      canvas.drawLine(base, Offset(base.dx - height * 0.3, base.dy - height * 0.4), stemPaint);
      canvas.drawLine(base, Offset(base.dx + height * 0.3, base.dy - height * 0.5), stemPaint);
    } else {
      // Lush leaves
      final leafPath1 = Path()
        ..moveTo(base.dx, base.dy - height * 0.4)
        ..quadraticBezierTo(base.dx - height * 0.35, base.dy - height * 0.55, base.dx - height * 0.4, base.dy - height * 0.3);
      canvas.drawPath(leafPath1, stemPaint);
      final leafPath2 = Path()
        ..moveTo(base.dx, base.dy - height * 0.6)
        ..quadraticBezierTo(base.dx + height * 0.35, base.dy - height * 0.75, base.dx + height * 0.4, base.dy - height * 0.5);
      canvas.drawPath(leafPath2, stemPaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - size, center.dy), Offset(center.dx + size, center.dy), p);
    canvas.drawLine(Offset(center.dx, center.dy - size), Offset(center.dx, center.dy + size), p);
    canvas.drawCircle(center, size * 0.35, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 3. WEATHER INTELLIGENCE — Glowing Sun, Fluffy Cloud & Raindrops
// ─────────────────────────────────────────────────────────────
class _WeatherPainter extends CustomPainter {
  const _WeatherPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.50;
    final s = h * 0.42;

    // Sky gradient background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD), Color(0xFFEDE7F6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Sun with radiant aura
    final sunCenter = Offset(cx + s * 0.45, cy - s * 0.30);
    canvas.drawCircle(sunCenter, s * 0.48, Paint()..color = const Color(0xFFFDD835).withValues(alpha: 0.25));
    canvas.drawCircle(sunCenter, s * 0.32, Paint()..color = const Color(0xFFFDD835));

    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFF9A825).withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r1 = s * 0.38;
      final r2 = s * 0.48;
      canvas.drawLine(
        Offset(sunCenter.dx + math.cos(angle) * r1, sunCenter.dy + math.sin(angle) * r1),
        Offset(sunCenter.dx + math.cos(angle) * r2, sunCenter.dy + math.sin(angle) * r2),
        rayPaint,
      );
    }

    // Fluffy cloud in foreground
    final cloudCenter = Offset(cx - s * 0.30, cy + s * 0.05);
    _drawCloud(canvas, cloudCenter, s * 0.95);

    // Falling rain drops under the cloud
    final dropPaint = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final dx = cloudCenter.dx - s * 0.35 + i * (s * 0.24);
      final dy = cloudCenter.dy + s * 0.42;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 3, dy + s * 0.22), dropPaint);
    }

    // Distant soft hill at bottom
    final hillPaint = Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.4);
    final hillPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.85)
      ..quadraticBezierTo(cx * 0.6, h * 0.72, cx, h * 0.82)
      ..quadraticBezierTo(cx * 1.4, h * 0.90, w, h * 0.80)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hillPath, hillPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 1.2, height: size * 0.55),
      p,
    );
    canvas.drawCircle(Offset(center.dx - size * 0.25, center.dy - size * 0.15), size * 0.30, p);
    canvas.drawCircle(Offset(center.dx + size * 0.15, center.dy - size * 0.22), size * 0.35, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 4. SMART IRRIGATION — Precision Drip tube, Moisture Arc & Drops
// ─────────────────────────────────────────────────────────────
class _IrrigationPainter extends CustomPainter {
  const _IrrigationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.50;
    final s = h * 0.42;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final ripplePaint = Paint()
      ..color = const Color(0xFF00ACC1).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy + s * 0.3), s * 0.9, ripplePaint);
    canvas.drawCircle(Offset(cx, cy + s * 0.3), s * 0.6, ripplePaint);

    final soilPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
      ).createShader(Rect.fromLTWH(0, cy + s * 0.45, w, h - (cy + s * 0.45)));
    canvas.drawRect(Rect.fromLTWH(0, cy + s * 0.45, w, h - (cy + s * 0.45)), soilPaint);

    final pipePaint = Paint()
      ..color = const Color(0xFF006064)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - s * 1.4, cy - s * 0.25), Offset(cx + s * 1.4, cy - s * 0.25), pipePaint);

    for (final xOff in [-s * 0.7, 0.0, s * 0.7]) {
      final emitX = cx + xOff;
      final emitY = cy - s * 0.25;
      canvas.drawCircle(Offset(emitX, emitY + 4), 3.5, Paint()..color = const Color(0xFF00838F));
      _drawDrop(canvas, Offset(emitX, emitY + s * 0.35), s * 0.18, const Color(0xFF0288D1));
    }

    final plantPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy + s * 0.45), Offset(cx, cy + s * 0.15), plantPaint);
    final leaf = Path()
      ..moveTo(cx, cy + s * 0.25)
      ..quadraticBezierTo(cx - s * 0.2, cy + s * 0.18, cx - s * 0.25, cy + s * 0.28);
    canvas.drawPath(leaf, plantPaint);
    final leaf2 = Path()
      ..moveTo(cx, cy + s * 0.20)
      ..quadraticBezierTo(cx + s * 0.2, cy + s * 0.12, cx + s * 0.25, cy + s * 0.22);
    canvas.drawPath(leaf2, plantPaint);

    _drawGauge(canvas, Offset(cx + s * 1.1, cy - s * 0.45), s * 0.32);
  }

  void _drawDrop(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size * 1.3)
      ..quadraticBezierTo(center.dx + size, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx - size, center.dy, center.dx, center.dy - size * 1.3)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawGauge(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.9));
    final arcPaint = Paint()
      ..color = const Color(0xFF00BCD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r - 3), math.pi * 0.8, math.pi * 1.4 * 0.7, false, arcPaint);
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF006064));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 5. YIELD & PROFIT ESTIMATOR — Upward Trend Bars + Wheat Ear + ₹ Coin
// ─────────────────────────────────────────────────────────────
class _YieldProfitPainter extends CustomPainter {
  const _YieldProfitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;
    final s = h * 0.42;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4), Color(0xFFFFF176)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final barWidth = s * 0.28;
    final barHeights = [s * 0.45, s * 0.70, s * 0.95, s * 1.25];
    final barColors = [
      const Color(0xFFFFB74D),
      const Color(0xFFFFA726),
      const Color(0xFF66BB6A),
      const Color(0xFF2E7D32),
    ];

    final baseY = cy + s * 0.65;
    for (int i = 0; i < 4; i++) {
      final bx = cx - s * 0.85 + i * (s * 0.56);
      final bHeight = barHeights[i];
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx - barWidth / 2, baseY - bHeight, barWidth, bHeight),
        const Radius.circular(5),
      );
      canvas.drawRRect(rRect, Paint()..color = barColors[i]);
    }

    final trendPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final trendPath = Path()
      ..moveTo(cx - s * 0.85, baseY - barHeights[0] - s * 0.1)
      ..lineTo(cx - s * 0.29, baseY - barHeights[1] - s * 0.1)
      ..lineTo(cx + s * 0.27, baseY - barHeights[2] - s * 0.1)
      ..lineTo(cx + s * 0.83, baseY - barHeights[3] - s * 0.15);
    canvas.drawPath(trendPath, trendPaint);

    final coinCenter = Offset(cx + s * 0.83, baseY - barHeights[3] - s * 0.40);
    final coinGlow = Paint()..color = const Color(0xFFFFA000).withValues(alpha: 0.3);
    canvas.drawCircle(coinCenter, s * 0.32, coinGlow);
    final coinBody = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(coinCenter, s * 0.24, coinBody);
    final coinBorder = Paint()
      ..color = const Color(0xFFFF6F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(coinCenter, s * 0.24, coinBorder);

    final tp = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(coinCenter.dx - tp.width / 2, coinCenter.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 6. AI FARMING ASSISTANT — Friendly AI Bot + Farmer + Speech Rings
// ─────────────────────────────────────────────────────────────
class _AiAssistantPainter extends CustomPainter {
  const _AiAssistantPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;
    final s = h * 0.42;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5), Color(0xFFE8F5E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final botCenter = Offset(cx - s * 0.65, cy);
    final botHead = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(botCenter.dx, botCenter.dy - s * 0.2), width: s * 0.7, height: s * 0.55),
      const Radius.circular(10),
    );
    canvas.drawRRect(botHead, Paint()..color = const Color(0xFF7B1FA2));
    final eyePaint = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset(botCenter.dx - s * 0.15, botCenter.dy - s * 0.2), s * 0.08, eyePaint);
    canvas.drawCircle(Offset(botCenter.dx + s * 0.15, botCenter.dy - s * 0.2), s * 0.08, eyePaint);
    final antPaint = Paint()
      ..color = const Color(0xFF9C27B0)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(botCenter.dx, botCenter.dy - s * 0.48), Offset(botCenter.dx, botCenter.dy - s * 0.68), antPaint);
    canvas.drawCircle(Offset(botCenter.dx, botCenter.dy - s * 0.72), s * 0.07, Paint()..color = const Color(0xFF00E5FF));

    final farmerCenter = Offset(cx + s * 0.65, cy);
    final hatPath = Path()
      ..moveTo(farmerCenter.dx - s * 0.45, farmerCenter.dy - s * 0.35)
      ..lineTo(farmerCenter.dx + s * 0.45, farmerCenter.dy - s * 0.35)
      ..lineTo(farmerCenter.dx + s * 0.20, farmerCenter.dy - s * 0.65)
      ..lineTo(farmerCenter.dx - s * 0.20, farmerCenter.dy - s * 0.65)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFFFFA000));
    canvas.drawCircle(Offset(farmerCenter.dx, farmerCenter.dy - s * 0.15), s * 0.22, Paint()..color = const Color(0xFF8D6E63));

    for (int i = 1; i <= 3; i++) {
      final wavePaint = Paint()
        ..color = const Color(0xFF7B1FA2).withValues(alpha: 0.25 * (4 - i))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(Offset(cx, cy - s * 0.15), i * (s * 0.22), wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 7. FARM PROFILE / LAND PARCELS — Farmland Panorama + Barn + Tractor
// ─────────────────────────────────────────────────────────────
class _FarmProfilePainter extends CustomPainter {
  const _FarmProfilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;
    final s = h * 0.42;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC), Color(0xFFE8F5E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final hill1 = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.6);
    final p1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, cy + s * 0.1)
      ..quadraticBezierTo(cx * 0.5, cy - s * 0.2, cx, cy + s * 0.1)
      ..quadraticBezierTo(cx * 1.5, cy + s * 0.3, w, cy)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(p1, hill1);

    final hill2 = Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.85);
    final p2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, cy + s * 0.35)
      ..quadraticBezierTo(cx * 0.8, cy + s * 0.15, w, cy + s * 0.45)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(p2, hill2);

    final barnX = cx - s * 0.3;
    final barnY = cy + s * 0.05;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barnX, barnY, s * 0.6, s * 0.45), const Radius.circular(3)),
      Paint()..color = const Color(0xFFC62828),
    );
    final roof = Path()
      ..moveTo(barnX - s * 0.08, barnY)
      ..lineTo(barnX + s * 0.3, barnY - s * 0.30)
      ..lineTo(barnX + s * 0.68, barnY)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF37474F));

    canvas.drawCircle(Offset(cx + s * 1.2, cy - s * 0.65), s * 0.28, Paint()..color = const Color(0xFFFDD835));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 8. FERTILIZER — Soil cross-section & nutrient ions
// ─────────────────────────────────────────────────────────────
class _FertilizerPainter extends CustomPainter {
  const _FertilizerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.50;
    final s = h * 0.42;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5E9), Color(0xFFD7CCC8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final npk = [('N', cx - s * 0.8, cy, const Color(0xFF1976D2)), ('P', cx, cy, const Color(0xFF7B1FA2)), ('K', cx + s * 0.8, cy, const Color(0xFFF57F17))];
    for (final item in npk) {
      canvas.drawCircle(Offset(item.$2, item.$3), s * 0.30, Paint()..color = item.$4.withValues(alpha: 0.2));
      canvas.drawCircle(Offset(item.$2, item.$3), s * 0.22, Paint()..color = item.$4);
      final tp = TextPainter(
        text: TextSpan(text: item.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(item.$2 - tp.width / 2, item.$3 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 9. MARKET PRICES — Mandi Trade Price Tag
// ─────────────────────────────────────────────────────────────
class _MarketPricesPainter extends CustomPainter {
  const _MarketPricesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.50;
    final s = h * 0.42;

    final bgPaint = Paint()..color = const Color(0xFFFFF3E0);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final tagRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: s * 1.6, height: s * 0.9), const Radius.circular(8));
    canvas.drawRRect(tagRect, Paint()..color = Colors.white);
    canvas.drawRRect(tagRect, Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 2);

    final tp = TextPainter(
      text: const TextSpan(text: 'LIVE MANDI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 10. GOVERNMENT SCHEMES — Ashoka Shield & Subsidy Gold Coins
// ─────────────────────────────────────────────────────────────
class _GovSchemesPainter extends CustomPainter {
  const _GovSchemesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.50;
    final s = h * 0.42;

    final bgPaint = Paint()..color = const Color(0xFFE8EAF6);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final shield = Path()
      ..moveTo(cx, cy - s * 0.8)
      ..lineTo(cx + s * 0.6, cy - s * 0.5)
      ..lineTo(cx + s * 0.6, cy + s * 0.2)
      ..quadraticBezierTo(cx + s * 0.6, cy + s * 0.7, cx, cy + s * 0.9)
      ..quadraticBezierTo(cx - s * 0.6, cy + s * 0.7, cx - s * 0.6, cy + s * 0.2)
      ..lineTo(cx - s * 0.6, cy - s * 0.5)
      ..close();
    canvas.drawPath(shield, Paint()..color = const Color(0xFF1565C0));
    canvas.drawCircle(Offset(cx, cy), s * 0.25, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
