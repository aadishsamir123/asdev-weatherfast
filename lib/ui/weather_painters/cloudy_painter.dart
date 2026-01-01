import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Renders beautiful animated clouds with depth and movement
class CloudyPainter extends CustomPainter {
  const CloudyPainter({
    required this.isDaytime,
    required this.animationValue,
    required this.colorScheme,
    this.scrollOffset = 0.0,
    this.density = 0.7,
    this.simplified = false,
  });

  final bool isDaytime;
  final double animationValue;
  final ColorScheme colorScheme;
  final double scrollOffset;
  final double density;
  final bool simplified;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollFactor = (1.0 - (scrollOffset / 300).clamp(0.0, 1.0));

    // Gradient sky background
    _paintSky(canvas, size, scrollFactor);

    // Dimmed sun/moon behind clouds
    _paintDimmedCelestial(canvas, size, scrollFactor);

    // Multiple cloud layers for depth
    _paintCloudLayer(canvas, size, scrollFactor, depth: 3, speed: 0.25);
    if (!simplified) {
      _paintCloudLayer(canvas, size, scrollFactor, depth: 2, speed: 0.45);
      _paintCloudLayer(canvas, size, scrollFactor, depth: 1, speed: 0.65);
    }

    _paintGround(canvas, size, scrollFactor);
    _paintPerson(canvas, size, scrollFactor);
  }

  void _paintSky(Canvas canvas, Size size, double scrollFactor) {
    final rect = Offset.zero & size;

    List<Color> colors;
    if (isDaytime) {
      colors = [
        colorScheme.secondaryContainer.withValues(alpha: 0.4 * scrollFactor),
        colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5 * scrollFactor,
        ),
        colorScheme.surfaceContainer.withValues(alpha: 0.6 * scrollFactor),
      ];
    } else {
      colors = [
        colorScheme.primary.withValues(alpha: 0.2 * scrollFactor),
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.35 * scrollFactor),
        Colors.black.withValues(alpha: 0.4 * scrollFactor),
      ];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintDimmedCelestial(Canvas canvas, Size size, double scrollFactor) {
    final center = Offset(
      isDaytime ? size.width * 0.75 : size.width * 0.25,
      size.height * 0.28 + scrollOffset * 0.2,
    );
    final radius = size.width * 0.1;

    // Very soft glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDaytime ? colorScheme.tertiary : colorScheme.secondary).withValues(
            alpha: 0.15 * scrollFactor,
          ),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2));

    canvas.drawCircle(center, radius * 2, glowPaint);

    // Dimmed celestial body
    final bodyPaint = Paint()
      ..color = (isDaytime ? colorScheme.tertiary : colorScheme.secondary)
          .withValues(alpha: 0.3 * scrollFactor);

    canvas.drawCircle(center, radius, bodyPaint);
  }

  void _paintCloudLayer(
    Canvas canvas,
    Size size,
    double scrollFactor, {
    required int depth,
    required double speed,
  }) {
    final random = Random(depth * 100);

    // Deeper clouds are darker and slower
    final opacity =
        (0.22 + (depth * 0.08)) *
        density *
        scrollFactor *
        (simplified ? 0.8 : 1.0);
    final blur = (15.0 + (depth * 5.0)) * (simplified ? 0.85 : 1.0);

    final cloudColor = isDaytime
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;

    final paint = Paint()
      ..color = cloudColor.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // Animation offset with parallax
    final drift =
        (animationValue * size.width * 0.06 * speed) % (size.width * 1.5);
    final parallaxY = scrollOffset * (0.1 * depth);

    // Draw multiple cloud formations
    final formationCount = simplified ? 2 : 3;
    for (int i = 0; i < formationCount; i++) {
      final baseX = (random.nextDouble() * size.width * 1.2) - drift;
      final baseY = size.height * (0.2 + random.nextDouble() * 0.4) + parallaxY;

      _drawCloudFormation(canvas, size, paint, baseX, baseY, depth, random);
    }
  }

  void _drawCloudFormation(
    Canvas canvas,
    Size size,
    Paint paint,
    double x,
    double y,
    int depth,
    Random random,
  ) {
    // Each cloud is made of multiple overlapping circles
    final numPuffs = 5 + random.nextInt(4);
    final baseSize =
        size.width * (0.15 + random.nextDouble() * 0.1) * (1.0 + depth * 0.1);

    for (int i = 0; i < numPuffs; i++) {
      final puffX = x + (i - numPuffs / 2) * baseSize * 0.4;
      final puffY = y + sin(i * 0.5) * baseSize * 0.2;
      final puffSize = baseSize * (0.7 + random.nextDouble() * 0.6);

      final path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(puffX, puffY),
            width: puffSize,
            height: puffSize * 0.7,
          ),
        );

      canvas.drawPath(path, paint);
    }
  }

  void _paintGround(Canvas canvas, Size size, double scrollFactor) {
    final groundHeight = size.height * 0.16;
    final rect = Rect.fromLTWH(
      0,
      size.height - groundHeight,
      size.width,
      groundHeight + 8,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.surfaceContainerHigh.withValues(
            alpha: 0.16 * scrollFactor,
          ),
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.22 * scrollFactor,
          ),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _paintPerson(Canvas canvas, Size size, double scrollFactor) {
    final groundY = size.height * 0.84;
    final scale = size.width * 0.0015;
    final base = Offset(size.width * 0.7, groundY);

    final bodyPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.65 * scrollFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    canvas.drawLine(
      base.translate(-6 * scale, -52 * scale),
      base.translate(-6 * scale, -18 * scale),
      bodyPaint,
    );
    canvas.drawLine(
      base.translate(-6 * scale, -18 * scale),
      base.translate(-18 * scale, 0),
      bodyPaint,
    );
    canvas.drawLine(
      base.translate(-6 * scale, -18 * scale),
      base.translate(6 * scale, 0),
      bodyPaint,
    );

    canvas.drawCircle(
      base.translate(-6 * scale, -64 * scale),
      7 * scale,
      bodyPaint..style = PaintingStyle.fill,
    );

    bodyPaint..style = PaintingStyle.stroke;
    canvas.drawLine(
      base.translate(-6 * scale, -36 * scale),
      base.translate(-22 * scale, -24 * scale),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(CloudyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDaytime != isDaytime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.density != density ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.simplified != simplified;
  }
}
