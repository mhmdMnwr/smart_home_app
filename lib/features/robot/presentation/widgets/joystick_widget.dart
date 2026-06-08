import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A transparent, game-style virtual joystick for robot teleoperation.
///
/// Reports normalized (dx, dy) in the range [-1, 1] via [onMove].
/// Calls [onMove] with (0, 0) when the user lifts their finger.
class JoystickWidget extends StatefulWidget {
  const JoystickWidget({
    super.key,
    this.size = 160,
    this.onMove,
  });

  /// Diameter of the outer ring.
  final double size;

  /// Called continuously with normalised (dx, dy) while dragging.
  final void Function(double dx, double dy)? onMove;

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  Offset _thumbOffset = Offset.zero;
  bool _isDragging = false;

  double get _radius => widget.size / 2;
  double get _thumbRadius => widget.size * 0.18;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _JoystickPainter(
            radius: _radius,
            thumbRadius: _thumbRadius,
            thumbOffset: _thumbOffset,
            isDragging: _isDragging,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(_radius, _radius);
    final localPos = details.localPosition;
    var delta = localPos - center;

    // Clamp to outer circle boundary
    final maxDist = _radius - _thumbRadius;
    if (delta.distance > maxDist) {
      delta = Offset.fromDirection(delta.direction, maxDist);
    }

    setState(() => _thumbOffset = delta);

    // Normalize to [-1, 1]
    final dx = delta.dx / maxDist;
    final dy = -delta.dy / maxDist; // Invert Y so up = positive
    widget.onMove?.call(dx, dy);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _thumbOffset = Offset.zero;
      _isDragging = false;
    });
    widget.onMove?.call(0, 0);
  }
}

/// Custom painter that draws the transparent joystick rings and thumb.
class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.radius,
    required this.thumbRadius,
    required this.thumbOffset,
    required this.isDragging,
  });

  final double radius;
  final double thumbRadius;
  final Offset thumbOffset;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── Outer ring ──
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDragging ? 0.18 : 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    final outerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDragging ? 0.35 : 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerBorderPaint);

    // ── Crosshair lines ──
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 8),
      Offset(center.dx, center.dy + radius - 8),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius + 8, center.dy),
      Offset(center.dx + radius - 8, center.dy),
      crossPaint,
    );

    // ── Direction arrows ──
    _drawArrow(canvas, center, -math.pi / 2, radius - 14); // Up
    _drawArrow(canvas, center, math.pi / 2, radius - 14);  // Down
    _drawArrow(canvas, center, math.pi, radius - 14);       // Left
    _drawArrow(canvas, center, 0, radius - 14);             // Right

    // ── Inner dead-zone ring ──
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.3, innerPaint);

    // ── Thumb ──
    final thumbCenter = center + thumbOffset;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4FAEFF).withValues(alpha: isDragging ? 0.25 : 0.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(thumbCenter, thumbRadius, glowPaint);

    // Fill
    final thumbFill = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isDragging ? 0.40 : 0.25),
          Colors.white.withValues(alpha: isDragging ? 0.15 : 0.08),
        ],
      ).createShader(Rect.fromCircle(center: thumbCenter, radius: thumbRadius));
    canvas.drawCircle(thumbCenter, thumbRadius, thumbFill);

    // Border
    final thumbBorder = Paint()
      ..color = Colors.white.withValues(alpha: isDragging ? 0.50 : 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(thumbCenter, thumbRadius, thumbBorder);
  }

  void _drawArrow(Canvas canvas, Offset center, double angle, double dist) {
    final tip = center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const arrowSize = 5.0;
    final p1 = tip;
    final p2 = tip + Offset(math.cos(angle + 2.5) * arrowSize, math.sin(angle + 2.5) * arrowSize);
    final p3 = tip + Offset(math.cos(angle - 2.5) * arrowSize, math.sin(angle - 2.5) * arrowSize);

    final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) =>
      old.thumbOffset != thumbOffset || old.isDragging != isDragging;
}
