import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A modern glassmorphic weather widget that displays temperature,
/// weather condition (sun / rain), and additional details like
/// humidity and wind speed.
///
/// This is currently a **UI-only** widget with hard-coded demo data.
/// Replace the static values with real weather API data when ready.
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ── Demo data (replace with real API later) ──────────────────────────
  static const double _temperature = 27;
  static const double _feelsLike = 29;
  static const int _humidity = 62;
  static const double _windSpeed = 12;
  static const String _condition = 'Partly Cloudy'; // 'Sunny', 'Rainy', etc.
  static const bool _isRaining = false;
  static const String _location = 'My Home';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppColorTokens>() ?? AppColors.darkTokens;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isRaining
                  ? <Color>[
                      const Color(0xFF1A2940),
                      const Color(0xFF0D1F3C),
                      const Color(0xFF162D50),
                    ]
                  : <Color>[
                      const Color(0xFF0E2A5A),
                      const Color(0xFF153B7A),
                      const Color(0xFF1A4B8E),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: tokens.deviceCardBorder.withValues(alpha: 0.25),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1F78FF).withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Subtle animated glow behind the icon
              Positioned(top: -10, right: -5, child: _buildAnimatedGlow()),
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: location + condition
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: const Color(0xFF64B5F6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _location,
                        style: const TextStyle(
                          color: Color(0xFFAAC2EC),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      // Weather icon
                      _buildWeatherIcon(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Temperature row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big temperature number
                      Text(
                        '${_temperature.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          '°C',
                          style: TextStyle(
                            color: Color(0xFFAAC2EC),
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Right side: condition + feels like
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              _condition,
                              style: const TextStyle(
                                color: Color(0xFFD4E4FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Feels like ${_feelsLike.round()}°',
                            style: TextStyle(
                              color: const Color(
                                0xFFAAC2EC,
                              ).withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bottom row: weather details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeatherDetailChip(
                        icon: Icons.water_drop_rounded,
                        label: 'Humidity',
                        value: '$_humidity%',
                        iconColor: const Color(0xFF4FC3F7),
                      ),
                      _buildVerticalDivider(),
                      _WeatherDetailChip(
                        icon: Icons.air_rounded,
                        label: 'Wind',
                        value: '${_windSpeed.round()} km/h',
                        iconColor: const Color(0xFF81D4FA),
                      ),
                      _buildVerticalDivider(),
                      _WeatherDetailChip(
                        icon: _isRaining
                            ? Icons.umbrella_rounded
                            : Icons.wb_sunny_rounded,
                        label: _isRaining ? 'Rain' : 'UV Index',
                        value: _isRaining ? '80%' : 'Low',
                        iconColor: _isRaining
                            ? const Color(0xFF64B5F6)
                            : const Color(0xFFFFD54F),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedGlow() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulse =
            0.6 + 0.4 * math.sin(_controller.value * 2 * math.pi);
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    (_isRaining
                            ? const Color(0xFF64B5F6)
                            : const Color(0xFFFFD54F))
                        .withValues(alpha: 0.15 * pulse),
                blurRadius: 50 * pulse,
                spreadRadius: 10 * pulse,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherIcon() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_isRaining) {
          return _buildRainIcon();
        }
        return _buildSunIcon();
      },
    );
  }

  Widget _buildSunIcon() {
    final double rotation = _controller.value * 2 * math.pi;
    final double scale = 1.0 + 0.05 * math.sin(_controller.value * 4 * math.pi);

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer rotating rays
            Transform.rotate(
              angle: rotation,
              child: CustomPaint(
                size: const Size(48, 48),
                painter: _SunRaysPainter(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                ),
              ),
            ),
            // Core sun circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: <Color>[
                    Color(0xFFFFE082),
                    Color(0xFFFFCA28),
                    Color(0xFFFFA726),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFCA28).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRainIcon() {
    final double offset = math.sin(_controller.value * 4 * math.pi) * 2;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud
          Positioned(
            top: 4,
            child: Icon(
              Icons.cloud_rounded,
              color: const Color(0xFFB0BEC5),
              size: 32,
            ),
          ),
          // Animated raindrops
          Positioned(
            bottom: 2 + offset,
            left: 12,
            child: Icon(
              Icons.water_drop,
              color: const Color(0xFF64B5F6).withValues(alpha: 0.9),
              size: 10,
            ),
          ),
          Positioned(
            bottom: 5 - offset,
            child: Icon(
              Icons.water_drop,
              color: const Color(0xFF42A5F5).withValues(alpha: 0.8),
              size: 12,
            ),
          ),
          Positioned(
            bottom: 2 + offset * 0.7,
            right: 12,
            child: Icon(
              Icons.water_drop,
              color: const Color(0xFF64B5F6).withValues(alpha: 0.7),
              size: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

// ── Weather detail chip ────────────────────────────────────────────────

class _WeatherDetailChip extends StatelessWidget {
  const _WeatherDetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFAAC2EC).withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Custom sun rays painter ────────────────────────────────────────────

class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const int rayCount = 8;
    const double innerRadius = 15;
    const double outerRadius = 22;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_SunRaysPainter oldDelegate) => color != oldDelegate.color;
}
