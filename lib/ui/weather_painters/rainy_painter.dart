import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Lush rain scene with layered sky, fast gravity-driven drops, ground, and a hero figure.
class RainyPainter extends CustomPainter {
  const RainyPainter({
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

  // Precomputed drop seeds to avoid per-frame randomness jitter.
  static final List<_DropSeed> _seeds = List.generate(260, (i) {
    final rnd = Random(i + 42);
    return _DropSeed(
      baseX: rnd.nextDouble(),
      phase: rnd.nextDouble(),
      speed: 1.05 + rnd.nextDouble() * 0.75, // Faster gravity feel
      drift: rnd.nextDouble() * 10 - 5,
      length: 7 + rnd.nextDouble() * 10,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scrollFactor = (1.0 - (scrollOffset / 300).clamp(0.0, 1.0));

    _paintRainySky(canvas, size, scrollFactor);
    _paintCloudCap(canvas, size, scrollFactor);
    _paintRainDrops(canvas, size, scrollFactor);
    _paintGround(canvas, size, scrollFactor);
    _paintPerson(canvas, size, scrollFactor);

    if (!simplified) {
      _paintFog(canvas, size, scrollFactor);
    }
  }

  void _paintRainySky(Canvas canvas, Size size, double scrollFactor) {
    final rect = Offset.zero & size;

    final colors = isDaytime
        ? [
            colorScheme.primary.withValues(alpha: 0.15 * scrollFactor),
            colorScheme.secondary.withValues(alpha: 0.45 * scrollFactor),
            colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6 * scrollFactor,
            ),
          ]
        : [
            colorScheme.primary.withValues(alpha: 0.25 * scrollFactor),
            colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.35 * scrollFactor,
            ),
            Colors.black.withValues(alpha: 0.55 * scrollFactor),
          ];

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: const [0.0, 0.55, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintCloudCap(Canvas canvas, Size size, double scrollFactor) {
    final random = Random(7);
    final cloudColor = isDaytime
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;

    final paint = Paint()
      ..color = cloudColor.withValues(alpha: 0.22 * scrollFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    final drift = (animationValue * size.width * 0.05) % (size.width * 1.2);
    final baseY = size.height * 0.18 + scrollOffset * 0.1;

    for (int i = 0; i < (simplified ? 2 : 3); i++) {
      final baseX = (random.nextDouble() * size.width * 1.1) - drift;
      final puffCount = 6 + random.nextInt(3);
      final baseSize = size.width * (0.18 + random.nextDouble() * 0.1);

      for (int p = 0; p < puffCount; p++) {
        final offsetX = baseX + (p - puffCount / 2) * baseSize * 0.35;
        final offsetY = baseY + sin(p * 0.5) * baseSize * 0.2;
        final sizeMul = 0.75 + random.nextDouble() * 0.6;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(offsetX, offsetY),
            width: baseSize * sizeMul,
            height: baseSize * sizeMul * 0.6,
          ),
          paint,
        );
      }
    }
  }

  void _paintRainDrops(Canvas canvas, Size size, double scrollFactor) {
    final dropColor = isDaytime
        ? colorScheme.tertiary.withValues(alpha: 0.7 * scrollFactor)
        : colorScheme.secondary.withValues(alpha: 0.65 * scrollFactor);

    final paint = Paint()
      ..color = dropColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final visibleCount = ((simplified ? 120 : 200) * intensity * scrollFactor)
        .clamp(24, 220)
        .round();

    for (int i = 0; i < visibleCount; i++) {
      final seed = _seeds[i % _seeds.length];
      final progress = ((animationValue * seed.speed) + seed.phase) % 1.0;
      final sway = sin((animationValue + seed.phase) * pi * 2) * seed.drift;

      final x = seed.baseX * size.width + sway;
      final y = progress * (size.height + 60) - 30;

      final parallaxY = y - scrollOffset * 0.45;
      if (parallaxY < -20 || parallaxY > size.height + 40) continue;

      final length = seed.length * (simplified ? 0.85 : 1.1);
      final opacity = (0.4 + (seed.phase) * 0.5) * scrollFactor;

      paint.color = dropColor.withValues(alpha: opacity);
      canvas.drawLine(
        Offset(x, parallaxY),
        Offset(x + 1.5, parallaxY + length),
        paint,
      );

      if (!simplified && progress > 0.92) {
        _paintSplash(canvas, Offset(x, parallaxY + length), scrollFactor, i);
      }
    }
  }

  void _paintSplash(
    Canvas canvas,
    Offset position,
    double scrollFactor,
    int seed,
  ) {
    final random = Random(seed * 13);
    final splashPaint = Paint()
      ..color = (isDaytime ? colorScheme.tertiary : colorScheme.secondary)
          .withValues(alpha: 0.28 * scrollFactor)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * pi * 2;
      final len = 3.5 + random.nextDouble() * 3.5;

      canvas.drawLine(
        position,
        Offset(
          position.dx + cos(angle) * len,
          position.dy + sin(angle) * len * 0.4,
        ),
        splashPaint,
      );
    }
  }

  void _paintGround(Canvas canvas, Size size, double scrollFactor) {
    final groundHeight = size.height * 0.18;
    final groundRect = Rect.fromLTWH(
      0,
      size.height - groundHeight,
      size.width,
      groundHeight + 10,
    );

    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.18 * scrollFactor,
          ),
          colorScheme.surfaceContainerHigh.withValues(
            alpha: 0.3 * scrollFactor,
          ),
        ],
      ).createShader(groundRect);

    canvas.drawRect(groundRect, groundPaint);

    if (simplified) return;

    // Puddles with subtle highlights
    final puddlePaint = Paint()
      ..color = colorScheme.tertiary.withValues(alpha: 0.2 * scrollFactor)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (int i = 0; i < 4; i++) {
      final rnd = Random(90 + i);
      final width = size.width * (0.18 + rnd.nextDouble() * 0.1);
      final height = groundHeight * 0.28;
      final x = size.width * (0.1 + rnd.nextDouble() * 0.8);
      final y = size.height - groundHeight + rnd.nextDouble() * 20;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        puddlePaint,
      );
    }
  }

  void _paintPerson(Canvas canvas, Size size, double scrollFactor) {
    final groundY = size.height * 0.82;
    final scale = size.width * 0.0016;
    final base = Offset(size.width * 0.72, groundY);

    // Body silhouette
    final bodyPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.8 * scrollFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;

    // Torso
    canvas.drawLine(
      base.translate(-8 * scale, -55 * scale),
      base.translate(-8 * scale, -20 * scale),
      bodyPaint,
    );

    // Legs
    canvas.drawLine(
      base.translate(-8 * scale, -20 * scale),
      base.translate(-20 * scale, 0),
      bodyPaint,
    );
    canvas.drawLine(
      base.translate(-8 * scale, -20 * scale),
      base.translate(4 * scale, 0),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(
      base.translate(-8 * scale, -70 * scale),
      8 * scale,
      bodyPaint..style = PaintingStyle.fill,
    );

    // Arm with phone
    bodyPaint..style = PaintingStyle.stroke;
    canvas.drawLine(
      base.translate(-8 * scale, -40 * scale),
      base.translate(-25 * scale, -28 * scale),
      bodyPaint,
    );

    // Umbrella shaft
    canvas.drawLine(
      base.translate(-8 * scale, -55 * scale),
      base.translate(30 * scale, -95 * scale),
      bodyPaint,
    );

    // Umbrella canopy
    final canopyCenter = base.translate(30 * scale, -95 * scale);
    final canopyRadius = 38 * scale;
    final canopyPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.8 * scrollFactor),
              colorScheme.tertiary.withValues(alpha: 0.5 * scrollFactor),
            ],
          ).createShader(
            Rect.fromCircle(center: canopyCenter, radius: canopyRadius),
          );

    canvas.drawArc(
      Rect.fromCircle(center: canopyCenter, radius: canopyRadius),
      pi,
      pi,
      true,
      canopyPaint,
    );
  }

  void _paintFog(Canvas canvas, Size size, double scrollFactor) {
    final fogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.12 * scrollFactor,
          ),
          colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.2 * scrollFactor,
          ),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawRect(Offset.zero & size, fogPaint);
  }

  @override
  bool shouldRepaint(RainyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDaytime != isDaytime ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.intensity != intensity ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.simplified != simplified;
  }
}

class _DropSeed {
  const _DropSeed({
    required this.baseX,
    required this.phase,
    required this.speed,
    required this.drift,
    required this.length,
  });

  final double baseX;
  final double phase;
  final double speed;
  final double drift;
  final double length;
}
