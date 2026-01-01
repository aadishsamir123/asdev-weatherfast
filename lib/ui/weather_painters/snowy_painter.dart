import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Beautiful snow animation with falling flakes and accumulation effect
class SnowyPainter extends CustomPainter {
  const SnowyPainter({
    required this.isDaytime,
    required this.animationValue,
    required this.colorScheme,
    this.scrollOffset = 0.0,
    this.intensity = 0.7,
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

    // Snowy sky background
    _paintSnowySky(canvas, size, scrollFactor);

    // Falling snowflakes with different sizes and speeds
    _paintSnowflakes(canvas, size, scrollFactor);

    // Ground accumulation effect
    _paintSnowAccumulation(canvas, size, scrollFactor);
    _paintPerson(canvas, size, scrollFactor);
  }

  void _paintSnowySky(Canvas canvas, Size size, double scrollFactor) {
    final rect = Offset.zero & size;

    List<Color> colors;
    if (isDaytime) {
      colors = [
        colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35 * scrollFactor,
        ),
        colorScheme.surfaceContainer.withValues(alpha: 0.45 * scrollFactor),
        colorScheme.surface.withValues(alpha: 0.5 * scrollFactor),
      ];
    } else {
      colors = [
        colorScheme.primary.withValues(alpha: 0.15 * scrollFactor),
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.25 * scrollFactor),
        colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35 * scrollFactor,
        ),
      ];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintSnowflakes(Canvas canvas, Size size, double scrollFactor) {
    final random = Random(42);
    final flakeCount = ((simplified ? 36 : 60) * intensity * scrollFactor)
        .round();

    final baseColor = isDaytime
        ? colorScheme.secondary
        : colorScheme.secondaryContainer;

    for (int i = 0; i < flakeCount; i++) {
      final seed = i / flakeCount;
      final speed = 0.15 + random.nextDouble() * 0.25; // Slower than rain

      // Gentle swaying motion
      final swayAmount =
          (simplified ? 12.0 : 20.0) +
          random.nextDouble() * (simplified ? 18.0 : 30.0);
      final swaySpeed = 0.5 + random.nextDouble() * 0.5;

      // Vertical position with animation
      final progress = ((animationValue * speed) + seed) % 1.0;
      final sway =
          sin((animationValue * swaySpeed + seed) * pi * 2) * swayAmount;

      final x = random.nextDouble() * size.width + sway;
      final y = progress * size.height;

      // Parallax with scroll
      final parallaxY = y - scrollOffset * 0.25;

      if (parallaxY > -10 && parallaxY < size.height + 10) {
        final flakeSize = 2.0 + random.nextDouble() * (simplified ? 2.0 : 3.0);
        final opacity = (0.6 + random.nextDouble() * 0.3) * scrollFactor;

        _drawSnowflake(
          canvas,
          Offset(x, parallaxY),
          flakeSize,
          baseColor.withValues(alpha: opacity),
          animationValue + seed,
        );
      }
    }
  }

  void _drawSnowflake(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
    double rotation,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation * pi * 2);

    // Simple 6-pointed snowflake
    for (int i = 0; i < 6; i++) {
      canvas.rotate(pi / 3);

      // Main arm
      final armPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size, 0);

      canvas.drawPath(
        armPath,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.2,
      );

      // Small branches
      canvas.drawLine(
        Offset(size * 0.6, 0),
        Offset(size * 0.7, -size * 0.2),
        paint..strokeWidth = size * 0.15,
      );
      canvas.drawLine(
        Offset(size * 0.6, 0),
        Offset(size * 0.7, size * 0.2),
        paint..strokeWidth = size * 0.15,
      );
    }

    // Center dot
    canvas.drawCircle(
      Offset.zero,
      size * 0.25,
      paint..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  void _paintSnowAccumulation(Canvas canvas, Size size, double scrollFactor) {
    final random = Random(123);

    // Snowy mounds at the bottom
    final paint = Paint()
      ..color =
          (isDaytime
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainer)
              .withValues(alpha: 0.3 * scrollFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(0, size.height);

    // Create wavy snow accumulation
    for (double x = 0; x <= size.width; x += 20) {
      final waveHeight = sin(x * 0.02) * 15 + random.nextDouble() * 10;
      final y = size.height - waveHeight - 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintPerson(Canvas canvas, Size size, double scrollFactor) {
    final groundY = size.height * 0.82;
    final scale = size.width * 0.0016;
    final base = Offset(size.width * 0.28, groundY);

    final bodyPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.75 * scrollFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    canvas.drawLine(
      base.translate(0, -52 * scale),
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
      base.translate(0, -66 * scale),
      7 * scale,
      bodyPaint..style = PaintingStyle.fill,
    );

    // Scarf
    final scarfPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.8 * scrollFactor)
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      base.translate(0, -56 * scale),
      base.translate(12 * scale, -50 * scale),
      scarfPaint,
    );
  }

  @override
  bool shouldRepaint(SnowyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDaytime != isDaytime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.intensity != intensity ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.simplified != simplified;
  }
}
