import 'package:flutter/material.dart';

import 'weather_painters/clear_sky_painter.dart';
import 'weather_painters/cloudy_painter.dart';
import 'weather_painters/rainy_painter.dart';
import 'weather_painters/snowy_painter.dart';
import 'weather_painters/stormy_painter.dart';

class AnimatedWeatherBackdrop extends StatefulWidget {
  const AnimatedWeatherBackdrop({
    super.key,
    required this.condition,
    required this.isDaytime,
    this.scrollOffset = 0.0,
    this.intensity = 0.6,
  });

  final String condition;
  final bool isDaytime;
  final double scrollOffset;
  final double intensity;

  @override
  State<AnimatedWeatherBackdrop> createState() =>
      _AnimatedWeatherBackdropState();
}

class _AnimatedWeatherBackdropState extends State<AnimatedWeatherBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final colorScheme = Theme.of(context).colorScheme;
    final isSimplified = widget.scrollOffset > 140;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final animValue = disableAnimations ? 0.3 : _controller.value;

          return CustomPaint(
            painter: _getPainterForCondition(
              widget.condition.toLowerCase(),
              animValue,
              colorScheme,
              isSimplified,
            ),
            child: Container(),
          );
        },
      ),
    );
  }

  CustomPainter _getPainterForCondition(
    String condition,
    double animValue,
    ColorScheme colorScheme,
    bool simplified,
  ) {
    // Determine which painter to use based on condition
    if (condition.contains('storm') || condition.contains('thunder')) {
      return StormyPainter(
        isDaytime: widget.isDaytime,
        animationValue: animValue,
        colorScheme: colorScheme,
        scrollOffset: widget.scrollOffset,
        intensity: widget.intensity,
        simplified: simplified,
      );
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return RainyPainter(
        isDaytime: widget.isDaytime,
        animationValue: animValue,
        colorScheme: colorScheme,
        scrollOffset: widget.scrollOffset,
        intensity: widget.intensity,
        simplified: simplified,
      );
    } else if (condition.contains('snow') || condition.contains('sleet')) {
      return SnowyPainter(
        isDaytime: widget.isDaytime,
        animationValue: animValue,
        colorScheme: colorScheme,
        scrollOffset: widget.scrollOffset,
        intensity: widget.intensity,
        simplified: simplified,
      );
    } else if (condition.contains('cloud') || condition.contains('overcast')) {
      return CloudyPainter(
        isDaytime: widget.isDaytime,
        animationValue: animValue,
        colorScheme: colorScheme,
        scrollOffset: widget.scrollOffset,
        density: widget.intensity,
        simplified: simplified,
      );
    } else {
      // Clear/default
      return ClearSkyPainter(
        isDaytime: widget.isDaytime,
        animationValue: animValue,
        colorScheme: colorScheme,
        scrollOffset: widget.scrollOffset,
        simplified: simplified,
      );
    }
  }
}
