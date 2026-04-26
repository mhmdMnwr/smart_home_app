import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A rounded gauge widget inspired by dark futuristic dashboards.
/// Colors sweep from green → yellow → red based on [value] in [min]..[max].
class SensorGauge extends StatelessWidget {
  const SensorGauge({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.min = 0,
    this.max = 100,
  });

  final double value;
  final String unit;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max);
    final ratio = (clampedValue - min) / (max - min);
    final isDanger = ratio >= 0.85;
    final valueColor = isDanger ? const Color(0xFFEF4444) : Colors.white;

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _GaugePainter(ratio: ratio, isDanger: isDanger),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDanger
                        ? const Color(0xFFEF4444).withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: TextStyle(
                    color: isDanger
                        ? const Color(0xFFEF4444).withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.ratio, required this.isDanger});

  final double ratio;
  final bool isDanger;

  static const double _startAngle = 2.356; // 135° in radians
  static const double _sweepTotal = 4.712; // 270° in radians

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // --- Outer glow ring ---
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0A1A3A).withValues(alpha: 0.7);
    canvas.drawArc(rect, _startAngle, _sweepTotal, false, glowPaint);

    // --- Track (dark background arc) ---
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1A2744);
    canvas.drawArc(rect, _startAngle, _sweepTotal, false, trackPaint);

    // --- Active arc with gradient green → yellow → red ---
    if (ratio > 0.001) {
      final sweepAngle = _sweepTotal * ratio;
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      if (isDanger) {
        gradientPaint.color = const Color(0xFFEF4444);
      } else {
        gradientPaint.shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepTotal,
          colors: const [
            Color(0xFF22C55E), // green
            Color(0xFF84CC16), // lime
            Color(0xFFEAB308), // yellow
            Color(0xFFF97316), // orange
            Color(0xFFEF4444), // red
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect);
      }
      canvas.drawArc(rect, _startAngle, sweepAngle, false, gradientPaint);

      // --- Bright dot at the tip ---
      final tipAngle = _startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final tipColor = isDanger ? const Color(0xFFEF4444) : _colorAtRatio(ratio);

      // outer glow
      canvas.drawCircle(
        Offset(tipX, tipY),
        10,
        Paint()..color = tipColor.withValues(alpha: 0.35),
      );
      // inner dot
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()..color = tipColor,
      );
    }

    // --- Inner decorative ring ---
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.5);
    canvas.drawCircle(center, radius - 14, innerRingPaint);
  }

  Color _colorAtRatio(double r) {
    if (r < 0.25) return Color.lerp(const Color(0xFF22C55E), const Color(0xFF84CC16), r / 0.25)!;
    if (r < 0.5) return Color.lerp(const Color(0xFF84CC16), const Color(0xFFEAB308), (r - 0.25) / 0.25)!;
    if (r < 0.75) return Color.lerp(const Color(0xFFEAB308), const Color(0xFFF97316), (r - 0.5) / 0.25)!;
    return Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), (r - 0.75) / 0.25)!;
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.ratio != ratio || old.isDanger != isDanger;
}
