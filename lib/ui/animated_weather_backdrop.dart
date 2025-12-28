import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedWeatherBackdrop extends StatefulWidget {
  const AnimatedWeatherBackdrop({
    super.key,
    required this.condition,
    required this.isDaytime,
    this.height = 320,
    this.intensity = 0.6,
  });

  final String condition;
  final bool isDaytime;
  final double height;
  final double intensity;

  @override
  State<AnimatedWeatherBackdrop> createState() =>
      _AnimatedWeatherBackdropState();
}

class _AnimatedWeatherBackdropState extends State<AnimatedWeatherBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late _Palette _palette;
  late _SceneProfile _profile;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildScene();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeatherBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition ||
        oldWidget.isDaytime != widget.isDaytime ||
        oldWidget.intensity != widget.intensity) {
      _rebuildScene();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rebuildScene() {
    final scheme = Theme.of(context).colorScheme;
    _profile = _sceneFor(widget.condition.toLowerCase());
    _palette = _paletteFor(widget.condition, widget.isDaytime, scheme);
    _particles = _buildParticles(_profile);
  }

  List<_Particle> _buildParticles(_SceneProfile profile) {
    final rnd = Random(widget.condition.hashCode + widget.isDaytime.hashCode);
    final count = profile.isRain
        ? 80
        : profile.isSnow
            ? 60
            : profile.isStorm
                ? 70
                : 0;
    return List.generate(count, (i) {
      final speedBase = profile.isSnow ? 18.0 : 60.0;
      return _Particle(
        startX: rnd.nextDouble(),
        startY: rnd.nextDouble(),
        speed: speedBase + rnd.nextDouble() * 32,
        sway: profile.isSnow
            ? 18 + rnd.nextDouble() * 12
            : 4 + rnd.nextDouble() * 6,
        size: profile.isSnow
            ? (1.8 + rnd.nextDouble() * 2.2)
            : (1.0 + rnd.nextDouble() * 1.4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      height: widget.height,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = disableAnimations ? 0.3 : _controller.value;
            final wave = sin(2 * pi * t) * 0.08 * widget.intensity;

            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _palette.start,
                        Color.lerp(_palette.start, _palette.end, 0.35)!,
                        _palette.end,
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GlowPainter(
                      palette: _palette,
                      isDay: widget.isDaytime,
                      phase: t,
                      wave: wave,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CloudPainter(
                      palette: _palette,
                      phase: t,
                      density: widget.intensity,
                      hasClouds: _profile.hasClouds,
                    ),
                  ),
                ),
                if (_profile.hasParticles)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        particles: _particles,
                        phase: t,
                        profile: _profile,
                        palette: _palette,
                      ),
                    ),
                  ),
                if (_profile.isStorm)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LightningPainter(phase: t),
                    ),
                  ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: const SizedBox(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({
    required this.palette,
    required this.isDay,
    required this.phase,
    required this.wave,
  });

  final _Palette palette;
  final bool isDay;
  final double phase;
  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * (isDay ? 0.75 : 0.3),
        size.height * (isDay ? 0.28 : 0.35 + wave));
    final radius = size.width * 0.35;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.highlight.withValues(alpha: isDay ? 0.38 : 0.22),
          palette.highlight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glow);

    final core = Paint()
      ..color = palette.highlight.withValues(alpha: isDay ? 0.8 : 0.55);
    canvas.drawCircle(center, radius * 0.18, core);

    final halo = Paint()
      ..color =
          palette.highlight.withValues(alpha: 0.12 + 0.05 * sin(phase * pi));
    canvas.drawCircle(center, radius * 0.32, halo);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.wave != wave ||
        oldDelegate.palette != palette ||
        oldDelegate.isDay != isDay;
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter({
    required this.palette,
    required this.phase,
    required this.density,
    required this.hasClouds,
  });

  final _Palette palette;
  final double phase;
  final double density;
  final bool hasClouds;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasClouds) return;
    final paint = Paint()
      ..color = palette.cloud.withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final wave = sin(phase * 2 * pi) * 16 * density;
    final yBase = size.height * 0.35 + wave;

    void drawBlob(double x, double width, double height, double opacity) {
      final path = Path()
        ..moveTo(x, yBase)
        ..quadraticBezierTo(x + width * 0.25, yBase - height, x + width * 0.5,
            yBase - height * 0.4)
        ..quadraticBezierTo(x + width * 0.75, yBase, x + width, yBase)
        ..lineTo(x + width, yBase + height * 0.45)
        ..lineTo(x, yBase + height * 0.45)
        ..close();

      canvas.drawPath(
          path, paint..color = paint.color.withValues(alpha: opacity));
    }

    drawBlob(size.width * 0.05, size.width * 0.55, 120, 0.35);
    drawBlob(size.width * 0.45, size.width * 0.7, 140, 0.32);
    drawBlob(size.width * 0.12, size.width * 0.5, 110, 0.28);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.density != density ||
        oldDelegate.palette != palette ||
        oldDelegate.hasClouds != hasClouds;
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.phase,
    required this.profile,
    required this.palette,
  });

  final List<_Particle> particles;
  final double phase;
  final _SceneProfile profile;
  final _Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = profile.isSnow
          ? palette.highlight.withValues(alpha: 0.8)
          : palette.highlight.withValues(alpha: 0.7);

    for (final p in particles) {
      final progress = (phase + p.startY) % 1.0;
      final x = (p.startX * size.width) + sin(progress * pi * 2) * p.sway;
      final y = progress * size.height;

      if (profile.isSnow) {
        canvas.drawCircle(
            Offset(x, y), p.size, paint..style = PaintingStyle.fill);
      } else {
        final end = Offset(x, y + p.size * 6);
        paint.strokeWidth = profile.isStorm ? 1.6 : 1.2;
        canvas.drawLine(Offset(x, y), end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.particles != particles ||
        oldDelegate.profile != profile ||
        oldDelegate.palette != palette;
  }
}

class _LightningPainter extends CustomPainter {
  const _LightningPainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final flash = (sin(phase * pi * 12).abs() > 0.92) ? 0.35 : 0.0;
    if (flash == 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: flash)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _Particle {
  _Particle({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.sway,
    required this.size,
  });

  final double startX;
  final double startY;
  final double speed;
  final double sway;
  final double size;
}

class _SceneProfile {
  const _SceneProfile({
    required this.isRain,
    required this.isSnow,
    required this.isStorm,
    required this.hasClouds,
  });

  final bool isRain;
  final bool isSnow;
  final bool isStorm;
  final bool hasClouds;

  bool get hasParticles => isRain || isSnow || isStorm;

  @override
  bool operator ==(Object other) {
    return other is _SceneProfile &&
        other.isRain == isRain &&
        other.isSnow == isSnow &&
        other.isStorm == isStorm &&
        other.hasClouds == hasClouds;
  }

  @override
  int get hashCode => Object.hash(isRain, isSnow, isStorm, hasClouds);
}

_SceneProfile _sceneFor(String condition) {
  final lower = condition.toLowerCase();
  final isRain = lower.contains('rain') || lower.contains('drizzle');
  final isSnow = lower.contains('snow') || lower.contains('sleet');
  final isStorm = lower.contains('storm') || lower.contains('thunder');
  final hasClouds = lower.contains('cloud') ||
      lower.contains('overcast') ||
      isRain ||
      isSnow ||
      isStorm;
  return _SceneProfile(
    isRain: isRain,
    isSnow: isSnow,
    isStorm: isStorm,
    hasClouds: hasClouds,
  );
}

class _Palette {
  const _Palette({
    required this.start,
    required this.end,
    required this.highlight,
    required this.cloud,
  });

  final Color start;
  final Color end;
  final Color highlight;
  final Color cloud;

  @override
  bool operator ==(Object other) {
    return other is _Palette &&
        other.start == start &&
        other.end == end &&
        other.highlight == highlight &&
        other.cloud == cloud;
  }

  @override
  int get hashCode => Object.hash(start, end, highlight, cloud);
}

_Palette _paletteFor(String condition, bool isDaytime, ColorScheme scheme) {
  final lower = condition.toLowerCase();

  if (!isDaytime) {
    return _Palette(
      start: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
      end: scheme.primary.withValues(alpha: 0.28),
      highlight: scheme.primary,
      cloud: scheme.onSurface.withValues(alpha: 0.6),
    );
  }

  if (lower.contains('rain') || lower.contains('drizzle')) {
    return _Palette(
      start: scheme.secondary.withValues(alpha: 0.55),
      end: scheme.primary.withValues(alpha: 0.38),
      highlight: scheme.tertiary,
      cloud: scheme.onSecondaryContainer.withValues(alpha: 0.55),
    );
  }

  if (lower.contains('cloud') || lower.contains('overcast')) {
    return _Palette(
      start: scheme.secondaryContainer.withValues(alpha: 0.7),
      end: scheme.primaryContainer.withValues(alpha: 0.55),
      highlight: scheme.primary,
      cloud: scheme.onSecondaryContainer.withValues(alpha: 0.5),
    );
  }

  if (lower.contains('snow') || lower.contains('sleet')) {
    return _Palette(
      start: scheme.onPrimaryFixedVariant.withValues(alpha: 0.3),
      end: scheme.surfaceTint.withValues(alpha: 0.42),
      highlight: scheme.secondary,
      cloud: scheme.onPrimaryFixed.withValues(alpha: 0.65),
    );
  }

  if (lower.contains('thunder') || lower.contains('storm')) {
    return _Palette(
      start: scheme.primary.withValues(alpha: 0.62),
      end: scheme.error.withValues(alpha: 0.32),
      highlight: scheme.onPrimary,
      cloud: scheme.onSurface.withValues(alpha: 0.55),
    );
  }

  return _Palette(
    start: scheme.primary.withValues(alpha: 0.65),
    end: scheme.tertiaryContainer.withValues(alpha: 0.6),
    highlight: scheme.tertiary,
    cloud: scheme.onSurface.withValues(alpha: 0.38),
  );
}
