import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Dramatic storm animation with lightning, heavy rain, and turbulent clouds
class StormyPainter extends CustomPainter {
  const StormyPainter({
    required this.isDaytime,
    required this.animationValue,
    required this.colorScheme,
    this.scrollOffset = 0.0,
    this.intensity = 0.8,
    this.simplified = false,
  });

  final bool isDaytime;
  final double animationValue;
  final ColorScheme colorScheme;
  final double scrollOffset;
  final double intensity;
  final bool simplified;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollFactor = (1.0 - (scrollOffset / 300).clamp(0.0, 1.0));

    // Dark stormy sky
    _paintStormySky(canvas, size, scrollFactor);

    // Turbulent clouds
    _paintTurbulentClouds(canvas, size, scrollFactor);

    // Lightning flashes
    if (!simplified) {
      _paintLightning(canvas, size, scrollFactor);
    }

    // Heavy rain
    _paintHeavyRain(canvas, size, scrollFactor);
    _paintGround(canvas, size, scrollFactor);
    _paintPerson(canvas, size, scrollFactor);
  }

  void _paintStormySky(Canvas canvas, Size size, double scrollFactor) {
    final rect = Offset.zero & size;

    // Lightning flash effect
    final flashIntensity = _calculateLightningFlash();

    List<Color> colors;
    if (isDaytime) {
      colors = [
        Color.lerp(
          colorScheme.primary.withValues(alpha: 0.35),
          Colors.white,
          flashIntensity * 0.5,
        )!.withValues(alpha: scrollFactor),
        Color.lerp(
          colorScheme.errorContainer.withValues(alpha: 0.4),
          Colors.white,
          flashIntensity * 0.3,
        )!.withValues(alpha: scrollFactor),
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.5 * scrollFactor),
      ];
    } else {
      colors = [
        Color.lerp(
          colorScheme.primary.withValues(alpha: 0.15),
          Colors.white,
          flashIntensity * 0.4,
        )!.withValues(alpha: scrollFactor),
        Color.lerp(
          Colors.black.withValues(alpha: 0.4),
          Colors.white,
          flashIntensity * 0.2,
        )!.withValues(alpha: scrollFactor),
        Colors.black.withValues(alpha: 0.5 * scrollFactor),
      ];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  double _calculateLightningFlash() {
    // Create periodic lightning flashes
    final flashCycle = (animationValue * 8) % 1.0;

    // Multiple flash patterns
    if (flashCycle > 0.85 && flashCycle < 0.88) {
      return ((flashCycle - 0.85) / 0.03).clamp(0.0, 1.0);
    } else if (flashCycle > 0.88 && flashCycle < 0.91) {
      return (1.0 - (flashCycle - 0.88) / 0.03).clamp(0.0, 1.0);
    } else if (flashCycle > 0.92 && flashCycle < 0.94) {
      return ((flashCycle - 0.92) / 0.02).clamp(0.0, 1.0) * 0.7;
    } else if (flashCycle > 0.94 && flashCycle < 0.96) {
      return (1.0 - (flashCycle - 0.94) / 0.02).clamp(0.0, 1.0) * 0.7;
    }

    return 0.0;
  }

  void _paintTurbulentClouds(Canvas canvas, Size size, double scrollFactor) {
    final random = Random(789);

    final cloudColor = isDaytime
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    // Multiple layers of dark, moving clouds
    final layerCount = simplified ? 2 : 3;
    for (int layer = 0; layer < layerCount; layer++) {
      final opacity =
          (0.3 + layer * 0.1) * scrollFactor * (simplified ? 0.85 : 1.0);
      final blur = (18.0 + layer * 8.0) * (simplified ? 0.85 : 1.0);
      final speed = 0.05 + layer * 0.03;

      final paint = Paint()
        ..color = cloudColor.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

      final drift = (animationValue * size.width * speed) % (size.width * 1.5);
      final parallaxY = scrollOffset * (0.15 * (layer + 1));

      for (int i = 0; i < 2; i++) {
        final baseX = (random.nextDouble() * size.width * 1.3) - drift;
        final baseY =
            size.height * (0.15 + random.nextDouble() * 0.35) + parallaxY;

        _drawTurbulentCloud(canvas, size, paint, baseX, baseY, random);
      }
    }
  }

  void _drawTurbulentCloud(
    Canvas canvas,
    Size size,
    Paint paint,
    double x,
    double y,
    Random random,
  ) {
    // Irregular, turbulent cloud shapes
    final numPuffs = 6 + random.nextInt(4);
    final baseSize = size.width * (0.18 + random.nextDouble() * 0.15);

    for (int i = 0; i < numPuffs; i++) {
      final angle = (i / numPuffs) * pi * 2;
      final distance = baseSize * (0.3 + random.nextDouble() * 0.4);

      final puffX = x + cos(angle) * distance;
      final puffY = y + sin(angle) * distance * 0.6;
      final puffSize = baseSize * (0.6 + random.nextDouble() * 0.7);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(puffX, puffY),
          width: puffSize,
          height: puffSize * 0.65,
        ),
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size, double scrollFactor) {
    final flashIntensity = _calculateLightningFlash();

    if (flashIntensity < 0.1) return;

    final random = Random(((animationValue * 8).floor()).toInt());

    // Lightning bolt
    final lightningPaint = Paint()
      ..color = colorScheme.tertiary.withValues(
        alpha: flashIntensity * 0.9 * scrollFactor,
      )
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final startX = size.width * (0.3 + random.nextDouble() * 0.4);
    final startY = size.height * 0.1;

    final path = Path();
    path.moveTo(startX, startY);

    // Create jagged lightning path
    double currentX = startX;
    double currentY = startY;

    for (int i = 0; i < 4; i++) {
      currentX += (random.nextDouble() - 0.5) * 40;
      currentY += size.height * 0.15;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, lightningPaint);

    // Brighter core
    canvas.drawPath(
      path,
      lightningPaint
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: flashIntensity * scrollFactor),
    );
  }

  void _paintHeavyRain(Canvas canvas, Size size, double scrollFactor) {
    final random = Random(456);
    final dropCount = ((simplified ? 60 : 100) * intensity * scrollFactor)
        .round();

    final dropColor = isDaytime
        ? colorScheme.primary.withValues(alpha: 0.7 * scrollFactor)
        : colorScheme.secondary.withValues(alpha: 0.6 * scrollFactor);

    final paint = Paint()
      ..color = dropColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dropCount; i++) {
      final seed = i / dropCount;
      final speed = 0.8 + random.nextDouble() * 0.5;

      // Vertical position with animation
      final progress = ((animationValue * speed) + seed) % 1.0;
      final windEffect = sin((animationValue + seed) * pi) * 15;

      final x = random.nextDouble() * size.width + windEffect;
      final y = progress * size.height;

      // Parallax with scroll
      final parallaxY = y - scrollOffset * 0.5;

      if (parallaxY > -10 && parallaxY < size.height + 10) {
        final dropLength =
            (simplified ? 10.0 : 12.0) +
            random.nextDouble() * (simplified ? 8.0 : 10.0);
        final opacity = (0.5 + random.nextDouble() * 0.4) * scrollFactor;

        paint.color = dropColor.withValues(alpha: opacity);

        canvas.drawLine(
          Offset(x, parallaxY),
          Offset(x + 2, parallaxY + dropLength),
          paint,
        );
      }
    }
  }

  void _paintGround(Canvas canvas, Size size, double scrollFactor) {
    final groundHeight = size.height * 0.18;
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
            alpha: 0.22 * scrollFactor,
          ),
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.32 * scrollFactor,
          ),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _paintPerson(Canvas canvas, Size size, double scrollFactor) {
    final groundY = size.height * 0.82;
    final scale = size.width * 0.0016;
    final base = Offset(size.width * 0.32, groundY);

    final bodyPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.85 * scrollFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    canvas.drawLine(
      base.translate(0, -54 * scale),
      base.translate(0, -18 * scale),
      bodyPaint,
    );
    canvas.drawLine(
      base.translate(0, -18 * scale),
      base.translate(-12 * scale, 0),
      bodyPaint,
    );
    canvas.drawLine(
      base.translate(0, -18 * scale),
      base.translate(12 * scale, 0),
      bodyPaint,
    );

    canvas.drawCircle(
      base.translate(0, -68 * scale),
      8 * scale,
      bodyPaint..style = PaintingStyle.fill,
    );

    bodyPaint..style = PaintingStyle.stroke;
    canvas.drawLine(
      base.translate(0, -42 * scale),
      base.translate(18 * scale, -30 * scale),
      bodyPaint,
    );

    canvas.drawLine(
      base.translate(0, -54 * scale),
      base.translate(36 * scale, -96 * scale),
      bodyPaint,
    );
    final canopyCenter = base.translate(36 * scale, -96 * scale);
    final canopyRadius = 40 * scale;
    canvas.drawArc(
      Rect.fromCircle(center: canopyCenter, radius: canopyRadius),
      pi,
      pi,
      true,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                colorScheme.tertiary.withValues(alpha: 0.85 * scrollFactor),
                colorScheme.primary.withValues(alpha: 0.55 * scrollFactor),
              ],
            ).createShader(
              Rect.fromCircle(center: canopyCenter, radius: canopyRadius),
            ),
    );
  }

  @override
  bool shouldRepaint(StormyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDaytime != isDaytime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.intensity != intensity ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.simplified != simplified;
  }
}
