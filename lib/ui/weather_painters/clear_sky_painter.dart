import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Renders a beautiful clear sky with sun/moon, atmospheric haze, and soft gradients
class ClearSkyPainter extends CustomPainter {
  const ClearSkyPainter({
    required this.isDaytime,
    required this.animationValue,
    required this.colorScheme,
    this.scrollOffset = 0.0,
    this.simplified = false,
  });

  final bool isDaytime;
  final double animationValue;
  final ColorScheme colorScheme;
  final double scrollOffset;
  final bool simplified;

  static final List<Offset> _stars = _precomputeStars();

  static List<Offset> _precomputeStars() {
    final rnd = Random(42);
    return List.generate(32, (_) => Offset(rnd.nextDouble(), rnd.nextDouble()));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scrollFactor = (1.0 - (scrollOffset / 300).clamp(0.0, 1.0));

    // Dynamic gradient based on time of day and color scheme
    _paintGradientSky(canvas, size, scrollFactor);

    // Celestial body (sun or moon) with glow effect
    _paintCelestialBody(canvas, size, scrollFactor);

    // Atmospheric effects
    _paintAtmosphericHaze(canvas, size, scrollFactor);

    // Subtle moving stars for night
    if (!isDaytime && !simplified) {
      _paintStars(canvas, size, scrollFactor);
    }

    // Subtle wispy clouds
    _paintWispyClouds(canvas, size, scrollFactor);

    // Ground and hero
    _paintGround(canvas, size, scrollFactor);
    _paintPerson(canvas, size, scrollFactor);
  }

  void _paintGradientSky(Canvas canvas, Size size, double scrollFactor) {
    final rect = Offset.zero & size;

    List<Color> colors;
    List<double> stops;

    if (isDaytime) {
      // Daytime: use color scheme primary colors
      colors = [
        colorScheme.primary.withValues(alpha: 0.3 * scrollFactor),
        colorScheme.primaryContainer.withValues(alpha: 0.5 * scrollFactor),
        colorScheme.secondaryContainer.withValues(alpha: 0.6 * scrollFactor),
        colorScheme.tertiaryContainer.withValues(alpha: 0.4 * scrollFactor),
      ];
      stops = [0.0, 0.35, 0.65, 1.0];
    } else {
      // Nighttime: deeper blues and purples from color scheme
      colors = [
        colorScheme.primary.withValues(alpha: 0.25 * scrollFactor),
        colorScheme.primaryContainer.withValues(alpha: 0.35 * scrollFactor),
        colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4 * scrollFactor,
        ),
        Colors.black.withValues(alpha: 0.5 * scrollFactor),
      ];
      stops = [0.0, 0.3, 0.6, 1.0];
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintCelestialBody(Canvas canvas, Size size, double scrollFactor) {
    // Position changes with scroll for parallax effect
    final baseY = isDaytime ? size.height * 0.25 : size.height * 0.3;
    final yOffset = scrollOffset * 0.3; // Parallax
    final y = baseY + yOffset;

    final x = isDaytime ? size.width * 0.7 : size.width * 0.3;
    final center = Offset(x, y);
    final baseRadius = size.width * (simplified ? 0.09 : 0.12);

    // Subtle breathing animation
    final breathe = simplified
        ? 1.0
        : sin(animationValue * 2 * pi) * 0.05 + 1.0;
    final radius = baseRadius * breathe * scrollFactor;

    if (isDaytime) {
      // Sun with warm glow
      _paintSun(canvas, center, radius, scrollFactor);
    } else {
      // Moon with soft glow
      _paintMoon(canvas, center, radius, scrollFactor);
    }
  }

  void _paintSun(
    Canvas canvas,
    Offset center,
    double radius,
    double scrollFactor,
  ) {
    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.tertiary.withValues(alpha: 0.15 * scrollFactor),
          colorScheme.tertiary.withValues(alpha: 0.08 * scrollFactor),
          colorScheme.tertiary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 3));

    canvas.drawCircle(center, radius * 3, glowPaint);

    // Main sun body
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.tertiary.withValues(alpha: 0.9 * scrollFactor),
          colorScheme.tertiary.withValues(alpha: 0.7 * scrollFactor),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sunPaint);

    // Bright core
    final corePaint = Paint()
      ..color = colorScheme.tertiaryContainer.withValues(
        alpha: 0.6 * scrollFactor,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, radius * 0.5, corePaint);
  }

  void _paintMoon(
    Canvas canvas,
    Offset center,
    double radius,
    double scrollFactor,
  ) {
    // Soft glow around moon
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.secondary.withValues(alpha: 0.12 * scrollFactor),
          colorScheme.secondary.withValues(alpha: 0.05 * scrollFactor),
          colorScheme.secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.5));

    canvas.drawCircle(center, radius * 2.5, glowPaint);

    // Moon body
    final moonPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.secondary.withValues(alpha: 0.7 * scrollFactor),
          colorScheme.secondary.withValues(alpha: 0.5 * scrollFactor),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, moonPaint);

    if (!simplified) {
      // Subtle craters
      final craterPaint = Paint()
        ..color = colorScheme.onSecondary.withValues(
          alpha: 0.15 * scrollFactor,
        );

      canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.2),
        radius * 0.2,
        craterPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + radius * 0.2, center.dy + radius * 0.3),
        radius * 0.15,
        craterPaint,
      );
    }
  }

  void _paintAtmosphericHaze(Canvas canvas, Size size, double scrollFactor) {
    final hazePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.08 * scrollFactor,
          ),
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.15 * scrollFactor,
          ),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, hazePaint);
  }

  void _paintStars(Canvas canvas, Size size, double scrollFactor) {
    final starPaint = Paint()
      ..color = colorScheme.secondary.withValues(alpha: 0.6 * scrollFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final count = simplified ? 18 : 30;
    for (int i = 0; i < count; i++) {
      final pos = _stars[i % _stars.length];
      final x = pos.dx * size.width;
      final y = pos.dy * size.height * 0.6;

      // Some stars twinkle
      final individualTwinkle = sin(animationValue * 3 * pi + i);
      final opacity = (0.3 + individualTwinkle * 0.3) * scrollFactor;

      starPaint.color = colorScheme.secondary.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.3, starPaint);
    }
  }

  void _paintWispyClouds(Canvas canvas, Size size, double scrollFactor) {
    final cloudPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.05 * scrollFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Animated wispy clouds
    final drift = animationValue * size.width * (simplified ? 0.05 : 0.1);

    void drawWisp(double x, double y, double width, double height) {
      final path = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(x + drift, y),
            width: width,
            height: height,
          ),
        );

      canvas.drawPath(path, cloudPaint);
    }

    final scale = simplified ? 0.75 : 1.0;
    drawWisp(size.width * 0.2, size.height * 0.35, 180 * scale, 40 * scale);
    drawWisp(size.width * 0.6, size.height * 0.45, 220 * scale, 35 * scale);
    if (!simplified) {
      drawWisp(size.width * 0.8, size.height * 0.28, 160, 30);
    }
  }

  void _paintGround(Canvas canvas, Size size, double scrollFactor) {
    final groundHeight = size.height * 0.16;
    final groundRect = Rect.fromLTWH(
      0,
      size.height - groundHeight,
      size.width,
      groundHeight + 6,
    );

    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.tertiaryContainer.withValues(alpha: 0.14 * scrollFactor),
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.18 * scrollFactor,
          ),
        ],
      ).createShader(groundRect);

    canvas.drawRect(groundRect, groundPaint);
  }

  void _paintPerson(Canvas canvas, Size size, double scrollFactor) {
    final groundY = size.height * 0.84;
    final scale = size.width * 0.0015;
    final base = Offset(size.width * 0.72, groundY);

    final bodyPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.7 * scrollFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    // Torso
    canvas.drawLine(
      base.translate(-6 * scale, -50 * scale),
      base.translate(-6 * scale, -18 * scale),
      bodyPaint,
    );

    // Legs
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

    // Head
    canvas.drawCircle(
      base.translate(-6 * scale, -63 * scale),
      7 * scale,
      bodyPaint..style = PaintingStyle.fill,
    );

    // Arm holding phone
    bodyPaint..style = PaintingStyle.stroke;
    canvas.drawLine(
      base.translate(-6 * scale, -36 * scale),
      base.translate(-22 * scale, -26 * scale),
      bodyPaint,
    );

    // Phone glow
    final phonePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.7 * scrollFactor),
              colorScheme.primary.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: base.translate(-24 * scale, -27 * scale),
              radius: 10 * scale,
            ),
          );
    canvas.drawCircle(
      base.translate(-24 * scale, -27 * scale),
      10 * scale,
      phonePaint,
    );
  }

  @override
  bool shouldRepaint(ClearSkyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDaytime != isDaytime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.simplified != simplified;
  }
}
