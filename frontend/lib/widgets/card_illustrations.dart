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

/// A vector illustration widget drawn with CustomPaint — no external assets
/// required. Each type renders a unique scene using Flutter Canvas APIs.
class CardIllustration extends StatelessWidget {
  final CardIllustrationType type;
  final double height;
  final double? width;

  const CardIllustration({
    super.key,
    required this.type,
    this.height = 110,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _getIllustrationPainter(type),
        ),
      ),
    );
  }

  CustomPainter _getIllustrationPainter(CardIllustrationType type) {
    switch (type) {
      case CardIllustrationType.cropHealth:
        return _CropHealthPainter();
      case CardIllustrationType.cropRecommendation:
        return _CropRecommendationPainter();
      case CardIllustrationType.weather:
        return _WeatherPainter();
      case CardIllustrationType.irrigation:
        return _IrrigationPainter();
      case CardIllustrationType.yieldProfit:
        return _YieldProfitPainter();
      case CardIllustrationType.aiAssistant:
        return _AiAssistantPainter();
      case CardIllustrationType.farmProfile:
        return _FarmProfilePainter();
      case CardIllustrationType.fertilizer:
        return _FertilizerPainter();
      case CardIllustrationType.marketPrices:
        return _MarketPricesPainter();
      case CardIllustrationType.govSchemes:
        return _GovSchemesPainter();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 1. CROP HEALTH DIAGNOSIS — close-up leaf with scan overlay
// ─────────────────────────────────────────────────────────────
class _CropHealthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradient background — soft sage green
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Draw stylised leaf shapes
    _drawLeaf(canvas, Offset(w * 0.18, h * 0.75), w * 0.28, h * 0.65, -0.5,
        const Color(0xFF2E7D32));
    _drawLeaf(canvas, Offset(w * 0.42, h * 0.80), w * 0.32, h * 0.70, -0.2,
        const Color(0xFF388E3C));
    _drawLeaf(canvas, Offset(w * 0.68, h * 0.78), w * 0.26, h * 0.60, 0.3,
        const Color(0xFF43A047));

    // Disease spots on middle leaf
    final spotPaint = Paint()..color = const Color(0xFFBF360C).withOpacity(0.75);
    canvas.drawCircle(Offset(w * 0.45, h * 0.52), 5, spotPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.44), 3.5, spotPaint);
    canvas.drawCircle(Offset(w * 0.39, h * 0.60), 4, spotPaint);
    final spotPaint2 = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.5);
    canvas.drawCircle(Offset(w * 0.48, h * 0.63), 2.5, spotPaint2);

    // AI scan circle overlay
    final scanPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset(w * 0.48, h * 0.52), h * 0.33, scanPaint);

    // Corner scan brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF1B5E20).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final cx = w * 0.48;
    final cy = h * 0.52;
    final r = h * 0.33;
    final bLen = 10.0;
    // top-left bracket
    canvas.drawLine(Offset(cx - r, cy - r + bLen), Offset(cx - r, cy - r), bracketPaint);
    canvas.drawLine(Offset(cx - r, cy - r), Offset(cx - r + bLen, cy - r), bracketPaint);
    // top-right bracket
    canvas.drawLine(Offset(cx + r - bLen, cy - r), Offset(cx + r, cy - r), bracketPaint);
    canvas.drawLine(Offset(cx + r, cy - r), Offset(cx + r, cy - r + bLen), bracketPaint);

    // Sparkle dot at top right
    final dotPaint = Paint()..color = const Color(0xFF43A047).withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), 4.5, dotPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.15), 2.8, dotPaint);
  }

  void _drawLeaf(Canvas canvas, Offset tip, double width, double height,
      double angle, Color color) {
    final path = Path();
    final center = Offset(tip.dx, tip.dy - height * 0.1);

    path.moveTo(tip.dx, tip.dy);
    path.cubicTo(
      tip.dx - width * 0.5, tip.dy - height * 0.4,
      tip.dx - width * 0.3, tip.dy - height * 0.9,
      tip.dx, tip.dy - height,
    );
    path.cubicTo(
      tip.dx + width * 0.3, tip.dy - height * 0.9,
      tip.dx + width * 0.5, tip.dy - height * 0.4,
      tip.dx, tip.dy,
    );

    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle)
      ..translate(-center.dx, -center.dy);

    final transformedPath = path.transform(matrix.storage);

    canvas.drawPath(transformedPath, Paint()..color = color);

    // Vein line
    final veinPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final veinPath = Path();
    veinPath.moveTo(tip.dx, tip.dy);
    veinPath.lineTo(tip.dx, tip.dy - height);
    final tVein = veinPath.transform(matrix.storage);
    canvas.drawPath(tVein, veinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 2. CROP RECOMMENDATION — multi-crop row with sparkles
// ─────────────────────────────────────────────────────────────
class _CropRecommendationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background — warm cream-amber
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Soil base strip
    final soilPaint = Paint()..color = const Color(0xFF8D6E63).withOpacity(0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
        Radius.zero,
      ),
      soilPaint,
    );

    // Draw 4 simple stylised crop silhouettes
    final cropPositions = [0.14, 0.34, 0.56, 0.78];
    final cropColors = [
      const Color(0xFF2E7D32), // rice — dark green
      const Color(0xFF558B2F), // wheat — medium green
      const Color(0xFF388E3C), // cotton — green
      const Color(0xFFF57F17), // maize — amber
    ];
    final cropHeights = [0.68, 0.72, 0.65, 0.70];

    for (int i = 0; i < 4; i++) {
      _drawCropSilhouette(
        canvas,
        Offset(w * cropPositions[i], h * 0.78),
        h * cropHeights[i],
        cropColors[i],
        i,
      );
    }

    // Sparkle / AI selection badge on 2nd crop
    _drawSparkle(canvas, Offset(w * 0.34, h * 0.14), 8, const Color(0xFFF59E0B));

    // Check badge
    final badgePaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(w * 0.34, h * 0.14), 7, badgePaint);
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path();
    checkPath.moveTo(w * 0.34 - 3.5, h * 0.14);
    checkPath.lineTo(w * 0.34 - 0.5, h * 0.14 + 3);
    checkPath.lineTo(w * 0.34 + 4, h * 0.14 - 3.5);
    canvas.drawPath(checkPath, checkPaint);

    // Small sparkles around 2nd crop
    _drawSparkle(canvas, Offset(w * 0.26, h * 0.22), 5, const Color(0xFFF59E0B).withOpacity(0.7));
    _drawSparkle(canvas, Offset(w * 0.44, h * 0.20), 4, const Color(0xFFF59E0B).withOpacity(0.6));
  }

  void _drawCropSilhouette(Canvas canvas, Offset base, double height,
      Color color, int type) {
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Stem
    canvas.drawLine(base, Offset(base.dx, base.dy - height), stemPaint);

    // Leaves based on type
    if (type == 0) {
      // Rice — drooping leaves
      for (int i = 1; i <= 3; i++) {
        final y = base.dy - height * (0.4 + i * 0.15);
        final side = i.isOdd ? 1 : -1;
        final path = Path()
          ..moveTo(base.dx, y)
          ..quadraticBezierTo(
            base.dx + side * 14, y - 4,
            base.dx + side * 22, y + 8,
          );
        canvas.drawPath(path, stemPaint);
      }
      // Grain head
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - height + 5),
          width: 7,
          height: 20,
        ),
        Paint()..color = const Color(0xFFF9A825),
      );
    } else if (type == 1) {
      // Wheat — upright bushy top
      for (double a = -0.6; a <= 0.6; a += 0.3) {
        final path = Path()
          ..moveTo(base.dx, base.dy - height * 0.5)
          ..quadraticBezierTo(
            base.dx + a * 20,
            base.dy - height * 0.75,
            base.dx + a * 10,
            base.dy - height,
          );
        canvas.drawPath(path, stemPaint);
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - height + 6),
          width: 10,
          height: 22,
        ),
        Paint()..color = const Color(0xFF8BC34A),
      );
    } else if (type == 2) {
      // Cotton — round boll
      final path = Path()
        ..moveTo(base.dx, base.dy - height * 0.6)
        ..quadraticBezierTo(
          base.dx - 12, base.dy - height * 0.75,
          base.dx - 10, base.dy - height * 0.9,
        );
      canvas.drawPath(path, stemPaint);
      final path2 = Path()
        ..moveTo(base.dx, base.dy - height * 0.6)
        ..quadraticBezierTo(
          base.dx + 12, base.dy - height * 0.75,
          base.dx + 10, base.dy - height * 0.9,
        );
      canvas.drawPath(path2, stemPaint);
      canvas.drawCircle(
        Offset(base.dx, base.dy - height + 2),
        9,
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    } else {
      // Maize — wide leaves
      for (int i = 1; i <= 3; i++) {
        final y = base.dy - height * (0.3 + i * 0.18);
        final side = i.isOdd ? 1 : -1;
        final leafPath = Path()
          ..moveTo(base.dx, y)
          ..quadraticBezierTo(
            base.dx + side * 18, y - 6,
            base.dx + side * 28, y + 2,
          );
        canvas.drawPath(leafPath, stemPaint);
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(base.dx + 6, base.dy - height * 0.65),
          width: 10,
          height: 24,
        ),
        Paint()..color = const Color(0xFFF9A825),
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * size,
            center.dy + math.sin(angle) * size),
        paint,
      );
    }
    canvas.drawCircle(center, size * 0.3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 3. WEATHER — sun, clouds, farm field
// ─────────────────────────────────────────────────────────────
class _WeatherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Sun
    final sunPaint = Paint()..color = const Color(0xFFFDD835);
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), h * 0.22, sunPaint);
    // Sun glow
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.28),
      h * 0.28,
      Paint()..color = const Color(0xFFFDD835).withOpacity(0.2),
    );
    // Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFF9A825).withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r1 = h * 0.30;
      final r2 = h * 0.36;
      canvas.drawLine(
        Offset(w * 0.72 + math.cos(angle) * r1, h * 0.28 + math.sin(angle) * r1),
        Offset(w * 0.72 + math.cos(angle) * r2, h * 0.28 + math.sin(angle) * r2),
        rayPaint,
      );
    }

    // Clouds
    _drawCloud(canvas, Offset(w * 0.25, h * 0.30), w * 0.28, h * 0.14,
        Colors.white.withOpacity(0.95));
    _drawCloud(canvas, Offset(w * 0.55, h * 0.42), w * 0.22, h * 0.11,
        Colors.white.withOpacity(0.80));

    // Rain drops below second cloud
    final rainPaint = Paint()
      ..color = const Color(0xFF64B5F6).withOpacity(0.75)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final x = w * 0.44 + i * (w * 0.07);
      canvas.drawLine(
        Offset(x, h * 0.56),
        Offset(x - 3, h * 0.68),
        rainPaint,
      );
    }

    // Ground / fields
    final groundPaint = Paint()..color = const Color(0xFF8BC34A).withOpacity(0.5);
    final groundPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.25, h * 0.70, w * 0.5, h * 0.76)
      ..quadraticBezierTo(w * 0.75, h * 0.82, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    final ground2 = Paint()..color = const Color(0xFF558B2F).withOpacity(0.6);
    final groundPath2 = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.3, h * 0.80, w * 0.6, h * 0.85)
      ..quadraticBezierTo(w * 0.8, h * 0.90, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath2, ground2);
  }

  void _drawCloud(Canvas canvas, Offset center, double width, double height,
      Color color) {
    final paint = Paint()..color = color;
    // Main cloud body from overlapping circles
    canvas.drawOval(
        Rect.fromCenter(center: center, width: width, height: height), paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx - width * 0.22, center.dy - height * 0.1),
            width: width * 0.55,
            height: height * 0.8),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx + width * 0.22, center.dy - height * 0.08),
            width: width * 0.50,
            height: height * 0.75),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 4. IRRIGATION — drip system + water droplets
// ─────────────────────────────────────────────────────────────
class _IrrigationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background — teal-blue
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Main pipe line (horizontal)
    final pipePaint = Paint()
      ..color = const Color(0xFF00838F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.08, h * 0.28), Offset(w * 0.92, h * 0.28), pipePaint);

    // Drip emitters and water drop trails
    final emitterPositions = [0.18, 0.36, 0.54, 0.72, 0.90];
    for (final xPct in emitterPositions) {
      final ex = w * xPct;
      final ey = h * 0.28;

      // Vertical tube
      canvas.drawLine(
        Offset(ex, ey),
        Offset(ex, ey + h * 0.12),
        pipePaint..strokeWidth = 2.5,
      );

      // Emitter nozzle
      canvas.drawCircle(
        Offset(ex, ey + h * 0.12),
        4,
        Paint()..color = const Color(0xFF006064),
      );

      // Water drops
      for (int d = 0; d < 3; d++) {
        final dropY = ey + h * 0.20 + d * h * 0.14;
        if (dropY > h * 0.88) continue;
        final dropAlpha = 1.0 - d * 0.25;
        _drawWaterDrop(
          canvas,
          Offset(ex, dropY),
          5.0 - d * 0.8,
          const Color(0xFF29B6F6).withOpacity(dropAlpha),
        );
      }
    }

    // Ground / soil layer
    final soilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
      ).createShader(Rect.fromLTWH(0, h * 0.78, w, h * 0.22));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), soilPaint);

    // Plant shoots from soil
    final stemPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final xPct in [0.18, 0.36, 0.54, 0.72]) {
      final bx = w * xPct;
      final by = h * 0.78;
      canvas.drawLine(Offset(bx, by), Offset(bx, by - h * 0.14), stemPaint);
      // Tiny leaf
      final leafPath = Path()
        ..moveTo(bx, by - h * 0.09)
        ..quadraticBezierTo(bx + 10, by - h * 0.14, bx + 14, by - h * 0.08);
      canvas.drawPath(leafPath, stemPaint);
    }

    // Smart gauge dial in top-right
    _drawGaugeDial(canvas, Offset(w * 0.86, h * 0.68), h * 0.14);
  }

  void _drawWaterDrop(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size * 1.3)
      ..quadraticBezierTo(
          center.dx + size, center.dy - size * 0.3, center.dx, center.dy + size)
      ..quadraticBezierTo(
          center.dx - size, center.dy - size * 0.3, center.dx, center.dy - size * 1.3)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawGaugeDial(Canvas canvas, Offset center, double radius) {
    // Dial background
    canvas.drawCircle(
      center, radius,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF00838F).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Arc fill (60% capacity)
    final arcPaint = Paint()
      ..color = const Color(0xFF29B6F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      math.pi * 0.75,
      math.pi * 1.5 * 0.6,
      false,
      arcPaint,
    );

    // Needle
    final needleAngle = math.pi * 0.75 + math.pi * 1.5 * 0.6;
    final needlePaint = Paint()
      ..color = const Color(0xFF006064)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(needleAngle) * (radius - 6),
        center.dy + math.sin(needleAngle) * (radius - 6),
      ),
      needlePaint,
    );
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFF006064));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 5. YIELD & PROFIT — bar chart with wheat stalks
// ─────────────────────────────────────────────────────────────
class _YieldProfitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background — warm golden
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // X-axis baseline
    final axisPaint = Paint()
      ..color = const Color(0xFFE0C170).withOpacity(0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(w * 0.10, h * 0.80),
      Offset(w * 0.90, h * 0.80),
      axisPaint,
    );

    // Bars (ascending trend)
    final barHeights = [0.28, 0.42, 0.35, 0.56, 0.68];
    final barColors = [
      const Color(0xFFFFB300),
      const Color(0xFFF9A825),
      const Color(0xFFFFB300),
      const Color(0xFF2E7D32),
      const Color(0xFF1B5E20),
    ];
    final barWidth = w * 0.10;
    for (int i = 0; i < 5; i++) {
      final barX = w * 0.14 + i * (w * 0.155);
      final barH = h * barHeights[i];
      final barTop = h * 0.80 - barH;

      // Bar fill
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX - barWidth / 2, barTop, barWidth, barH),
        const Radius.circular(5),
      );
      canvas.drawRRect(rRect, Paint()..color = barColors[i].withOpacity(0.85));

      // Wheat stalk on top of last bar
      if (i == 4) {
        final stemPaint = Paint()
          ..color = const Color(0xFF33691E)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        final stalkX = barX;
        canvas.drawLine(
          Offset(stalkX, barTop),
          Offset(stalkX, barTop - h * 0.14),
          stemPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(stalkX, barTop - h * 0.14 - 5),
            width: 8,
            height: 18,
          ),
          Paint()..color = const Color(0xFF8BC34A),
        );
      }
    }

    // Upward trend arrow
    final trendPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final trendPath = Path()
      ..moveTo(w * 0.14, h * 0.74)
      ..lineTo(w * 0.30, h * 0.60)
      ..lineTo(w * 0.46, h * 0.65)
      ..lineTo(w * 0.62, h * 0.52)
      ..lineTo(w * 0.80, h * 0.32);
    canvas.drawPath(trendPath, trendPaint);

    // Rupee symbol coin
    final coinPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(w * 0.86, h * 0.28), 13, coinPaint);
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.28), 13,
      Paint()
        ..color = const Color(0xFFE65100).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.86 - tp.width / 2, h * 0.28 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 6. AI ASSISTANT — robot + farmer + chat bubbles
// ─────────────────────────────────────────────────────────────
class _AiAssistantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background — lavender-green gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3E5F5), Color(0xFFE8F5E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // AI Robot body (left)
    _drawRobot(canvas, Offset(w * 0.22, h * 0.55));

    // Farmer silhouette (right)
    _drawFarmer(canvas, Offset(w * 0.76, h * 0.60));

    // Chat bubbles between them
    _drawChatBubble(
        canvas, Offset(w * 0.44, h * 0.26), w * 0.28, h * 0.14, true);
    _drawChatBubble(
        canvas, Offset(w * 0.56, h * 0.46), w * 0.24, h * 0.12, false);

    // Connecting line / signal dots
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * 0.37 + i * w * 0.07, h * 0.58),
        2.5,
        Paint()
          ..color = const Color(0xFF9C27B0).withOpacity(0.3 + i * 0.1),
      );
    }

    // Sparkles
    for (final pos in [(0.65, 0.18), (0.78, 0.30), (0.14, 0.22)]) {
      canvas.drawCircle(
        Offset(w * pos.$1, h * pos.$2),
        3,
        Paint()..color = const Color(0xFFF59E0B).withOpacity(0.7),
      );
    }
  }

  void _drawRobot(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFF7B1FA2).withOpacity(0.75);
    final accentPaint = Paint()..color = const Color(0xFF9C27B0).withOpacity(0.5);

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 22), width: 32, height: 28),
        const Radius.circular(10),
      ),
      bodyPaint,
    );
    // Eyes
    canvas.drawCircle(Offset(center.dx - 7, center.dy - 24), 4,
        Paint()..color = const Color(0xFF4FC3F7));
    canvas.drawCircle(Offset(center.dx + 7, center.dy - 24), 4,
        Paint()..color = const Color(0xFF4FC3F7));
    // Antenna
    canvas.drawLine(
      Offset(center.dx, center.dy - 36),
      Offset(center.dx, center.dy - 44),
      Paint()
        ..color = accentPaint.color
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(center.dx, center.dy - 46), 3, accentPaint);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 2), width: 28, height: 24),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Leaf accent on chest
    canvas.drawCircle(
      Offset(center.dx, center.dy - 2),
      5,
      Paint()..color = const Color(0xFF4CAF50).withOpacity(0.8),
    );
  }

  void _drawFarmer(Canvas canvas, Offset center) {
    final skinPaint = Paint()..color = const Color(0xFF795548);
    final clothPaint = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.75);

    // Head
    canvas.drawCircle(Offset(center.dx, center.dy - 28), 11, skinPaint);

    // Hat
    final hatPath = Path()
      ..moveTo(center.dx - 16, center.dy - 36)
      ..lineTo(center.dx + 16, center.dy - 36)
      ..lineTo(center.dx + 10, center.dy - 48)
      ..lineTo(center.dx - 10, center.dy - 48)
      ..close();
    canvas.drawPath(hatPath, clothPaint);
    canvas.drawLine(
      Offset(center.dx - 16, center.dy - 36),
      Offset(center.dx + 16, center.dy - 36),
      Paint()
        ..color = clothPaint.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 8), width: 24, height: 22),
        const Radius.circular(5),
      ),
      clothPaint,
    );
  }

  void _drawChatBubble(Canvas canvas, Offset center, double width, double height,
      bool isLeft) {
    final bubblePaint = Paint()
      ..color = isLeft
          ? Colors.white.withOpacity(0.9)
          : const Color(0xFF2E7D32).withOpacity(0.15);
    final strokePaint = Paint()
      ..color = isLeft
          ? const Color(0xFF7B1FA2).withOpacity(0.25)
          : const Color(0xFF2E7D32).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, bubblePaint);
    canvas.drawRRect(rect, strokePaint);

    // Dots inside bubble
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(center.dx - 8.0 + i * 8.0, center.dy),
        2.5,
        Paint()
          ..color = (isLeft
                  ? const Color(0xFF7B1FA2)
                  : const Color(0xFF2E7D32))
              .withOpacity(0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 7. FARM PROFILE — landscape overview
// ─────────────────────────────────────────────────────────────
class _FarmProfilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Rolling fields (layered)
    _drawField(canvas, w, h, 0.65, const Color(0xFF558B2F).withOpacity(0.5));
    _drawField(canvas, w, h, 0.76, const Color(0xFF388E3C).withOpacity(0.7));
    _drawField(canvas, w, h, 0.86, const Color(0xFF2E7D32).withOpacity(0.9));

    // Simple farmhouse
    final housePaint = Paint()..color = const Color(0xFFEF9A9A).withOpacity(0.85);
    canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.50, w * 0.18, h * 0.22), housePaint);
    // Roof
    final roofPath = Path()
      ..moveTo(w * 0.09, h * 0.50)
      ..lineTo(w * 0.21, h * 0.36)
      ..lineTo(w * 0.33, h * 0.50)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFB71C1C).withOpacity(0.75));
    // Door
    canvas.drawRect(
      Rect.fromLTWH(w * 0.185, h * 0.60, w * 0.055, h * 0.12),
      Paint()..color = const Color(0xFF5D4037),
    );

    // Tractor silhouette
    _drawTractor(canvas, Offset(w * 0.65, h * 0.70));

    // Sun top right
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.14),
      h * 0.12,
      Paint()..color = const Color(0xFFFDD835).withOpacity(0.9),
    );

    // Birds (simple V shapes)
    for (final pos in [(0.42, 0.14), (0.52, 0.10), (0.60, 0.17)]) {
      final birdPaint = Paint()
        ..color = const Color(0xFF37474F).withOpacity(0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(w * pos.$1 - 6, h * pos.$2),
        Offset(w * pos.$1, h * pos.$2 - 4),
        birdPaint,
      );
      canvas.drawLine(
        Offset(w * pos.$1, h * pos.$2 - 4),
        Offset(w * pos.$1 + 6, h * pos.$2),
        birdPaint,
      );
    }
  }

  void _drawField(Canvas canvas, double w, double h, double yPct, Color color) {
    final path = Path()
      ..moveTo(0, h * yPct)
      ..quadraticBezierTo(w * 0.3, h * (yPct - 0.06), w * 0.6, h * yPct)
      ..quadraticBezierTo(w * 0.8, h * (yPct + 0.04), w, h * (yPct - 0.02))
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawTractor(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFFE65100).withOpacity(0.75);
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 36, height: 20),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    // Cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 6, center.dy - 22, 20, 14),
        const Radius.circular(3),
      ),
      bodyPaint,
    );
    // Wheels
    canvas.drawCircle(Offset(center.dx - 12, center.dy + 8), 8,
        Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(Offset(center.dx + 12, center.dy + 8), 6,
        Paint()..color = const Color(0xFF37474F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 8. FERTILIZER — soil cross-section with NPK molecules
// ─────────────────────────────────────────────────────────────
class _FertilizerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky / above-ground (top half)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.5), skyPaint);

    // Soil layer (bottom half)
    final soilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.5), soilPaint);

    // Ground line
    canvas.drawLine(
      Offset(0, h * 0.5),
      Offset(w, h * 0.5),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 2,
    );

    // Plants above ground
    for (final xPct in [0.18, 0.42, 0.66, 0.88]) {
      _drawPlant(canvas, Offset(w * xPct, h * 0.5));
    }

    // Roots below ground
    for (final xPct in [0.18, 0.42, 0.66, 0.88]) {
      _drawRoots(canvas, Offset(w * xPct, h * 0.5));
    }

    // Fertilizer granules in soil
    final granulePaint = Paint()..color = const Color(0xFF0288D1).withOpacity(0.75);
    for (final pos in [
      (0.28, 0.65), (0.52, 0.72), (0.74, 0.60), (0.36, 0.80),
      (0.60, 0.85), (0.14, 0.75), (0.82, 0.78),
    ]) {
      canvas.drawCircle(Offset(w * pos.$1, h * pos.$2), 3.5, granulePaint);
    }

    // NPK molecule labels
    final npkData = [
      ('N', w * 0.22, h * 0.62, const Color(0xFF1976D2)),
      ('P', w * 0.50, h * 0.68, const Color(0xFF7B1FA2)),
      ('K', w * 0.78, h * 0.63, const Color(0xFFF57F17)),
    ];
    for (final d in npkData) {
      canvas.drawCircle(
        Offset(d.$2, d.$3), 10, Paint()..color = d.$4.withOpacity(0.25));
      canvas.drawCircle(
        Offset(d.$2, d.$3), 10,
        Paint()
          ..color = d.$4.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: d.$1,
          style: TextStyle(
            fontSize: 10,
            color: d.$4,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(d.$2 - tp.width / 2, d.$3 - tp.height / 2));
    }
  }

  void _drawPlant(Canvas canvas, Offset base) {
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, Offset(base.dx, base.dy - 32), stemPaint);
    // Leaves
    final leafPath = Path()
      ..moveTo(base.dx, base.dy - 18)
      ..quadraticBezierTo(base.dx + 14, base.dy - 24, base.dx + 18, base.dy - 14);
    canvas.drawPath(leafPath, stemPaint);
    final leafPath2 = Path()
      ..moveTo(base.dx, base.dy - 24)
      ..quadraticBezierTo(base.dx - 12, base.dy - 30, base.dx - 16, base.dy - 20);
    canvas.drawPath(leafPath2, stemPaint);
  }

  void _drawRoots(Canvas canvas, Offset base) {
    final rootPaint = Paint()
      ..color = const Color(0xFFBCAAA4).withOpacity(0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // Central root
    canvas.drawLine(base, Offset(base.dx, base.dy + 28), rootPaint);
    // Side roots
    canvas.drawLine(
      Offset(base.dx, base.dy + 14),
      Offset(base.dx + 14, base.dy + 24),
      rootPaint,
    );
    canvas.drawLine(
      Offset(base.dx, base.dy + 18),
      Offset(base.dx - 12, base.dy + 28),
      rootPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 9. MARKET PRICES — price tags + crop icons
// ─────────────────────────────────────────────────────────────
class _MarketPricesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Price tag items
    final items = [
      (w * 0.22, h * 0.42, '₹20', const Color(0xFF2E7D32)),
      (w * 0.50, h * 0.38, '₹35', const Color(0xFFE65100)),
      (w * 0.78, h * 0.44, '₹28', const Color(0xFF1565C0)),
    ];

    for (final item in items) {
      _drawPriceTag(canvas, Offset(item.$1, item.$2), item.$3, item.$4);
    }

    // Up/down arrows
    _drawArrow(canvas, Offset(w * 0.30, h * 0.70), true, const Color(0xFF2E7D32));
    _drawArrow(canvas, Offset(w * 0.58, h * 0.68), false, const Color(0xFFD32F2F));
    _drawArrow(canvas, Offset(w * 0.84, h * 0.72), true, const Color(0xFF2E7D32));

    // Small crop silhouettes at top
    final cropPaint = Paint()
      ..color = const Color(0xFF43A047).withOpacity(0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final x in [w * 0.15, w * 0.42, w * 0.70]) {
      canvas.drawLine(Offset(x, h * 0.22), Offset(x, h * 0.08), cropPaint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, h * 0.07), width: 8, height: 14),
        Paint()..color = const Color(0xFF43A047).withOpacity(0.5),
      );
    }
  }

  void _drawPriceTag(Canvas canvas, Offset center, String price, Color color) {
    final tagPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final borderPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 50, height: 28),
        const Radius.circular(8),
      ),
      tagPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 50, height: 28),
        const Radius.circular(8),
      ),
      borderPaint,
    );

    // Tag hole
    canvas.drawCircle(
      Offset(center.dx - 20, center.dy),
      3,
      Paint()..color = color.withOpacity(0.5),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: price,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - 10 - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawArrow(Canvas canvas, Offset tip, bool isUp, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dir = isUp ? -1 : 1;
    canvas.drawLine(tip, Offset(tip.dx, tip.dy + dir * 16), paint);
    canvas.drawLine(tip, Offset(tip.dx - 6, tip.dy + dir * 7), paint);
    canvas.drawLine(tip, Offset(tip.dx + 6, tip.dy + dir * 7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// 10. GOVERNMENT SCHEMES — official document + shield
// ─────────────────────────────────────────────────────────────
class _GovSchemesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8EAF6), Color(0xFFE3F2FD)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Document
    final docPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.44, h * 0.72),
        const Radius.circular(10),
      ),
      docPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.44, h * 0.72),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xFF3F51B5).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Document lines
    final linePaint = Paint()
      ..color = const Color(0xFF9FA8DA).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final y = h * 0.26 + i * h * 0.11;
      final lineWidth = i == 0 ? 0.32 : (i == 2 ? 0.26 : 0.30);
      canvas.drawLine(
        Offset(w * 0.19, y),
        Offset(w * (0.19 + lineWidth), y),
        linePaint,
      );
    }

    // Document header accent
    canvas.drawRect(
      Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.44, h * 0.08),
      Paint()..color = const Color(0xFF3F51B5).withOpacity(0.15),
    );

    // Shield / badge
    _drawShield(canvas, Offset(w * 0.76, h * 0.44));

    // Rupee coins
    final coinPaint = Paint()..color = const Color(0xFFF59E0B).withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.78, h * 0.74), 10, coinPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.80), 8, coinPaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.80), 7, coinPaint);

    // Stars
    for (final pos in [(0.65, 0.18), (0.84, 0.22), (0.74, 0.14)]) {
      canvas.drawCircle(
        Offset(w * pos.$1, h * pos.$2),
        2.5,
        Paint()..color = const Color(0xFFF59E0B).withOpacity(0.7),
      );
    }
  }

  void _drawShield(Canvas canvas, Offset center) {
    final shieldPath = Path()
      ..moveTo(center.dx, center.dy - 30)
      ..lineTo(center.dx + 22, center.dy - 18)
      ..lineTo(center.dx + 22, center.dy + 2)
      ..quadraticBezierTo(center.dx + 22, center.dy + 20, center.dx, center.dy + 28)
      ..quadraticBezierTo(center.dx - 22, center.dy + 20, center.dx - 22, center.dy + 2)
      ..lineTo(center.dx - 22, center.dy - 18)
      ..close();

    canvas.drawPath(shieldPath,
        Paint()..color = const Color(0xFF1565C0).withOpacity(0.75));
    canvas.drawPath(
        shieldPath,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Ashoka chakra–inspired small wheel
    canvas.drawCircle(center, 10, Paint()..color = Colors.white.withOpacity(0.9));
    canvas.drawCircle(
      center, 10,
      Paint()
        ..color = const Color(0xFF1565C0).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * 8, center.dy + math.sin(angle) * 8),
        Paint()
          ..color = const Color(0xFF1565C0).withOpacity(0.5)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

