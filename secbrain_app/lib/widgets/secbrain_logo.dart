import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The official brand color of SecBrain (#1F5448)
const Color secBrainPine = Color(0xFF1F5448);
const Color secBrainDark = Color(0xFF1E2220);
const Color secBrainSub = Color(0xFF788880);

/// CustomPainter that renders the exact SecBrain Shield + Brain vector emblem
class SecBrainEmblemPainter extends CustomPainter {
  const SecBrainEmblemPainter({
    this.color = secBrainPine,
    this.backgroundColor,
  });

  final Color color;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != null) {
      final bgPaint = Paint()..color = backgroundColor!;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    final double w = size.width;
    final double h = size.height;
    final double strokeW = math.max(2.0, w * 0.058);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = w * 0.5;
    final cy = h * 0.5;

    // 1. Draw Shield Contour
    final shieldPath = Path();
    final sTop = h * 0.08;
    final sBottom = h * 0.92;
    final sLeft = w * 0.12;
    final sRight = w * 0.88;
    final sCornerR = w * 0.08;

    // Start at top-center, curve slightly to top-right
    shieldPath.moveTo(cx, sTop * 1.15);
    shieldPath.quadraticBezierTo(
      w * 0.72,
      sTop * 0.95,
      sRight - sCornerR,
      sTop * 1.05,
    );
    shieldPath.quadraticBezierTo(
      sRight,
      sTop * 1.08,
      sRight,
      sTop + sCornerR * 1.4,
    );

    // Right side down and inward to bottom tip
    shieldPath.cubicTo(
      sRight * 0.99,
      h * 0.45,
      sRight * 0.85,
      h * 0.72,
      cx + sCornerR * 0.2,
      sBottom - sCornerR * 0.4,
    );
    // Bottom tip curve
    shieldPath.quadraticBezierTo(
      cx,
      sBottom,
      cx - sCornerR * 0.2,
      sBottom - sCornerR * 0.4,
    );

    // Left side up to top-left
    shieldPath.cubicTo(
      sLeft + (w - sRight) * 0.15,
      h * 0.72,
      sLeft * 1.01,
      h * 0.45,
      sLeft,
      sTop + sCornerR * 1.4,
    );
    shieldPath.quadraticBezierTo(
      sLeft,
      sTop * 1.08,
      sLeft + sCornerR,
      sTop * 1.05,
    );
    shieldPath.quadraticBezierTo(w * 0.28, sTop * 0.95, cx, sTop * 1.15);
    shieldPath.close();

    canvas.drawPath(shieldPath, linePaint);

    // 2. Draw Brain Hemispheres inside the Shield
    // Draw Left Hemisphere
    final leftBrain = Path();
    final rightBrain = Path();

    // Scale factors for brain within the shield
    final bx = cx;
    final bTop = cy - h * 0.26;
    final bBottom = cy + h * 0.24;
    final gap = w * 0.024; // Center gap between hemispheres

    // LEFT HEMISPHERE
    // Top lobe
    leftBrain.moveTo(bx - gap, bTop + h * 0.02);
    leftBrain.cubicTo(
      bx - gap - w * 0.06,
      bTop - h * 0.03,
      bx - w * 0.22,
      bTop + h * 0.02,
      bx - w * 0.22,
      bTop + h * 0.13,
    );

    // Middle-outer lobe
    leftBrain.cubicTo(
      bx - w * 0.32,
      bTop + h * 0.15,
      bx - w * 0.32,
      bTop + h * 0.31,
      bx - w * 0.21,
      bTop + h * 0.33,
    );

    // Bottom-outer lobe
    leftBrain.cubicTo(
      bx - w * 0.27,
      bTop + h * 0.42,
      bx - w * 0.14,
      bBottom + h * 0.05,
      bx - gap,
      bBottom,
    );

    // Inner convolutions / loops for left hemisphere
    final leftInner = Path();
    // Mid horizontal branch
    leftInner.moveTo(bx - gap, cy - h * 0.04);
    leftInner.cubicTo(
      bx - w * 0.18,
      cy - h * 0.06,
      bx - w * 0.18,
      cy + h * 0.08,
      bx - gap,
      cy + h * 0.06,
    );

    // Lower inner loop
    leftInner.moveTo(bx - gap, cy + h * 0.16);
    leftInner.cubicTo(
      bx - w * 0.14,
      cy + h * 0.18,
      bx - w * 0.14,
      bBottom - h * 0.03,
      bx - gap,
      bBottom - h * 0.02,
    );

    // Center vertical dividing stem line for Left side
    final leftCenterStem = Path();
    leftCenterStem.moveTo(bx - gap, bTop + h * 0.02);
    leftCenterStem.lineTo(bx - gap, bBottom);

    canvas.drawPath(leftBrain, linePaint);
    canvas.drawPath(leftInner, linePaint);
    canvas.drawPath(leftCenterStem, linePaint);

    // RIGHT HEMISPHERE (Mirrored across bx)
    // Top lobe
    rightBrain.moveTo(bx + gap, bTop + h * 0.02);
    rightBrain.cubicTo(
      bx + gap + w * 0.06,
      bTop - h * 0.03,
      bx + w * 0.22,
      bTop + h * 0.02,
      bx + w * 0.22,
      bTop + h * 0.13,
    );

    // Middle-outer lobe
    rightBrain.cubicTo(
      bx + w * 0.32,
      bTop + h * 0.15,
      bx + w * 0.32,
      bTop + h * 0.31,
      bx + w * 0.21,
      bTop + h * 0.33,
    );

    // Bottom-outer lobe
    rightBrain.cubicTo(
      bx + w * 0.27,
      bTop + h * 0.42,
      bx + w * 0.14,
      bBottom + h * 0.05,
      bx + gap,
      bBottom,
    );

    // Inner convolutions / loops for right hemisphere
    final rightInner = Path();
    rightInner.moveTo(bx + gap, cy - h * 0.04);
    rightInner.cubicTo(
      bx + w * 0.18,
      cy - h * 0.06,
      bx + w * 0.18,
      cy + h * 0.08,
      bx + gap,
      cy + h * 0.06,
    );

    rightInner.moveTo(bx + gap, cy + h * 0.16);
    rightInner.cubicTo(
      bx + w * 0.14,
      cy + h * 0.18,
      bx + w * 0.14,
      bBottom - h * 0.03,
      bx + gap,
      bBottom - h * 0.02,
    );

    // Center vertical dividing stem line for Right side
    final rightCenterStem = Path();
    rightCenterStem.moveTo(bx + gap, bTop + h * 0.02);
    rightCenterStem.lineTo(bx + gap, bBottom);

    canvas.drawPath(rightBrain, linePaint);
    canvas.drawPath(rightInner, linePaint);
    canvas.drawPath(rightCenterStem, linePaint);
  }

  @override
  bool shouldRepaint(covariant SecBrainEmblemPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Standalone SecBrain Shield Logo Emblem
class SecBrainShieldIcon extends StatelessWidget {
  const SecBrainShieldIcon({
    super.key,
    this.size = 32,
    this.color = secBrainPine,
    this.backgroundColor,
    this.useAssetImage = true,
  });

  final double size;
  final Color color;
  final Color? backgroundColor;
  final bool useAssetImage;

  @override
  Widget build(BuildContext context) {
    if (useAssetImage) {
      return Image.asset(
        'assets/images/logo_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size(size, size),
          painter: SecBrainEmblemPainter(
            color: color,
            backgroundColor: backgroundColor,
          ),
        ),
      );
    }
    return CustomPaint(
      size: Size(size, size),
      painter: SecBrainEmblemPainter(
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

/// Complete Brand Logo: Shield Emblem + "SecBrain" + "SECURE INTELLIGENCE"
class SecBrainLogo extends StatelessWidget {
  const SecBrainLogo({
    super.key,
    this.size = 36,
    this.showSubtitle = true,
    this.showText = true,
    this.color,
    this.isDark,
    this.useAssetImage = true,
  });

  final double size;
  final bool showSubtitle;
  final bool showText;
  final Color? color;
  final bool? isDark;
  final bool useAssetImage;

  @override
  Widget build(BuildContext context) {
    if (useAssetImage && showText && showSubtitle) {
      return Image.asset(
        'assets/images/logo.png',
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final emblemColor = color ?? secBrainPine;
    final textColor = dark ? Colors.white : secBrainDark;
    final subColor = dark ? Colors.white60 : secBrainSub;

    final emblem = SecBrainShieldIcon(
      size: size,
      color: emblemColor,
      useAssetImage: useAssetImage,
    );

    if (!showText) {
      return emblem;
    }

    final fontSize = size * 0.68;
    final subtitleFontSize = fontSize * 0.32;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Sec',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: emblemColor,
                      letterSpacing: -0.4,
                      height: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: 'Brain',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.4,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (showSubtitle) ...[
              SizedBox(height: size * 0.08),
              Text(
                'SECURE INTELLIGENCE',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: subtitleFontSize * 0.34,
                  color: subColor,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
