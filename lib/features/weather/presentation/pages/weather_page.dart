import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mqtt_live_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/weather_cubit.dart';
import '../cubit/weather_state.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppColorTokens>() ?? AppColors.darkTokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            tokens.pageGradientTop,
            tokens.pageGradientMiddle,
            tokens.pageGradientBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<WeatherCubit, WeatherState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    'Weather',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    'Live outdoor conditions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.latestReading == null
                      ? const _WaitingView()
                      : _WeatherContent(reading: state.latestReading!),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────── Waiting View ───────────────

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for weather data…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFD7E6FF),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Main Content ───────────────

class _WeatherContent extends StatefulWidget {
  const _WeatherContent({required this.reading});
  final WeatherReading reading;

  @override
  State<_WeatherContent> createState() => _WeatherContentState();
}

class _WeatherContentState extends State<_WeatherContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reading;
    final tokens =
        Theme.of(context).extension<AppColorTokens>() ?? AppColors.darkTokens;

    final now = DateTime.now();
    final isNight = now.hour >= 18 || now.hour < 6;
    final isRaining = r.water >= 35;
    final isCloudy = r.light < 40;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: <Widget>[
        // ── Hero Card ──
        _HeroWeatherCard(
          reading: r,
          anim: _anim,
          isNight: isNight,
          isRaining: isRaining,
          isCloudy: isCloudy,
          tokens: tokens,
        ),
        const SizedBox(height: 20),
        // ── Metric Grid ──
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _MetricCard(
              label: 'Temperature',
              value: '${r.temperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat_rounded,
              gradient: _tempGradient(r.temperature),
              detail: _tempDetail(r.temperature),
            ),
            _MetricCard(
              label: 'Humidity',
              value: '${r.humidity.round()}%',
              icon: Icons.water_drop_rounded,
              gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
              detail: _humidDetail(r.humidity),
            ),
            _MetricCard(
              label: 'Light',
              value: '${r.light.round()}%',
              icon: isNight
                  ? Icons.nightlight_round
                  : Icons.wb_sunny_rounded,
              gradient: _lightGradient(r.light, isNight),
              detail: _lightDetail(r.light),
            ),
            _MetricCard(
              label: 'Water / Rain',
              value: '${r.water.round()}%',
              icon: isRaining
                  ? Icons.umbrella_rounded
                  : Icons.grain_rounded,
              gradient: _waterGradient(r.water),
              detail: _waterDetail(r.water),
            ),
          ],
        ),
      ],
    );
  }

  // ── helpers ──
  List<Color> _tempGradient(double t) {
    if (t >= 35) return const [Color(0xFFD32F2F), Color(0xFFFF8A65)];
    if (t >= 25) return const [Color(0xFFE65100), Color(0xFFFFB74D)];
    if (t >= 15) return const [Color(0xFF2E7D32), Color(0xFF81C784)];
    return const [Color(0xFF0277BD), Color(0xFF4FC3F7)];
  }

  String _tempDetail(double t) {
    if (t >= 40) return 'Extreme heat';
    if (t >= 35) return 'Very hot';
    if (t >= 25) return 'Warm';
    if (t >= 15) return 'Comfortable';
    if (t >= 5) return 'Cool';
    return 'Cold';
  }

  String _humidDetail(double h) {
    if (h >= 80) return 'Very humid';
    if (h >= 60) return 'Humid';
    if (h >= 40) return 'Comfortable';
    if (h >= 20) return 'Dry';
    return 'Very dry';
  }

  List<Color> _lightGradient(double l, bool isNight) {
    if (isNight) return const [Color(0xFF1A237E), Color(0xFF5C6BC0)];
    if (l >= 70) return const [Color(0xFFF57F17), Color(0xFFFFD54F)];
    if (l >= 35) return const [Color(0xFF827717), Color(0xFFDCE775)];
    return const [Color(0xFF37474F), Color(0xFF78909C)];
  }

  String _lightDetail(double l) {
    if (l >= 70) return 'Bright sunshine';
    if (l >= 35) return 'Partly cloudy';
    if (l >= 10) return 'Overcast';
    return 'Dark';
  }

  List<Color> _waterGradient(double w) {
    if (w >= 70) return const [Color(0xFF0D47A1), Color(0xFF42A5F5)];
    if (w >= 35) return const [Color(0xFF1565C0), Color(0xFF64B5F6)];
    return const [Color(0xFF00695C), Color(0xFF4DB6AC)];
  }

  String _waterDetail(double w) {
    if (w >= 70) return 'Heavy rain';
    if (w >= 35) return 'Light rain';
    if (w >= 10) return 'Drizzle';
    return 'Dry';
  }
}

// ─────────────── Hero Card ───────────────

class _HeroWeatherCard extends StatelessWidget {
  const _HeroWeatherCard({
    required this.reading,
    required this.anim,
    required this.isNight,
    required this.isRaining,
    required this.isCloudy,
    required this.tokens,
  });

  final WeatherReading reading;
  final AnimationController anim;
  final bool isNight;
  final bool isRaining;
  final bool isCloudy;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final gradient = isNight
        ? const [Color(0xFF0A1A3D), Color(0xFF132B61), Color(0xFF1A3B7E)]
        : isRaining
            ? const [Color(0xFF0F2E52), Color(0xFF17466D), Color(0xFF285D84)]
            : const [Color(0xFF0E2A5A), Color(0xFF15508E), Color(0xFF2D7FC5)];

    final condition = _resolveCondition();

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: tokens.deviceCardBorder.withValues(alpha: 0.25),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1F78FF).withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Glow effect
              Positioned(
                top: -10,
                right: -8,
                child: _AnimatedGlow(
                  anim: anim,
                  isNight: isNight,
                  isRaining: isRaining,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNight ? 'Night' : 'Daytime',
                              style: const TextStyle(
                                color: Color(0xFFD7E6FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              condition,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AnimatedWeatherIcon(
                        anim: anim,
                        isNight: isNight,
                        isRaining: isRaining,
                        isCloudy: isCloudy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Temperature display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        reading.temperature.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          '°C',
                          style: TextStyle(
                            color: Color(0xFFB7CEF2),
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick metrics row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HeroMetricTile(
                          label: 'Humidity',
                          value: '${reading.humidity.round()}%',
                          icon: Icons.water_drop_rounded,
                          color: const Color(0xFF67D3FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroMetricTile(
                          label: 'Light',
                          value: '${reading.light.round()}%',
                          icon: isNight
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          color: isNight
                              ? const Color(0xFFB7C9FF)
                              : const Color(0xFFFFD767),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroMetricTile(
                          label: 'Rain',
                          value: '${reading.water.round()}%',
                          icon: isRaining
                              ? Icons.umbrella_rounded
                              : Icons.grain_rounded,
                          color: isRaining
                              ? const Color(0xFF7BC4FF)
                              : const Color(0xFF9FD1FF),
                        ),
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

  String _resolveCondition() {
    if (isRaining && reading.water >= 70) return 'Heavy Rain';
    if (isRaining) return 'Rainy';
    if (isNight) return 'Clear Night';
    if (isCloudy) return 'Cloudy';
    if (reading.light >= 70) return 'Sunny';
    return 'Partly Cloudy';
  }
}

// ─────────────── Animated Weather Icon ───────────────

class _AnimatedWeatherIcon extends StatelessWidget {
  const _AnimatedWeatherIcon({
    required this.anim,
    required this.isNight,
    required this.isRaining,
    required this.isCloudy,
  });

  final AnimationController anim;
  final bool isNight;
  final bool isRaining;
  final bool isCloudy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        if (isNight) return _buildMoon();
        if (isRaining) return _buildRain();
        if (isCloudy) return _buildCloudSun();
        return _buildSun();
      },
    );
  }

  Widget _buildSun() {
    final rotation = anim.value * 2 * math.pi;
    final scale = 1.0 + (0.06 * math.sin(anim.value * 4 * math.pi));

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: rotation,
              child: CustomPaint(
                size: const Size(56, 56),
                painter: _SunRaysPainter(
                  color: const Color(0xFFFFD766).withValues(alpha: 0.55),
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFE59F),
                    Color(0xFFFFCF5E),
                    Color(0xFFFFB748),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoon() {
    final yOff = math.sin(anim.value * 2 * math.pi) * 1.6;
    return Transform.translate(
      offset: Offset(0, yOff),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD5DEFF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBECCFF).withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 22,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1A3B7E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRain() {
    final drop = math.sin(anim.value * 4 * math.pi) * 2;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned(
            top: 3,
            child: Icon(Icons.cloud_rounded, size: 34, color: Color(0xFFC3D6EA)),
          ),
          Positioned(
            bottom: 2 + drop,
            left: 14,
            child: Icon(Icons.water_drop, size: 11,
                color: const Color(0xFF68B9FF).withValues(alpha: 0.9)),
          ),
          Positioned(
            bottom: 6 - drop,
            child: Icon(Icons.water_drop, size: 13,
                color: const Color(0xFF4FAEFF).withValues(alpha: 0.9)),
          ),
          Positioned(
            bottom: 3 + (drop * 0.7),
            right: 14,
            child: Icon(Icons.water_drop, size: 10,
                color: const Color(0xFF89CCFF).withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSun() {
    final yOff = math.sin(anim.value * 2 * math.pi) * 1.2;
    return Transform.translate(
      offset: Offset(0, yOff),
      child: const SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 2,
              right: 4,
              child: Icon(Icons.wb_sunny_rounded, size: 22, color: Color(0xFFFFD766)),
            ),
            Positioned(
              bottom: 6,
              child: Icon(Icons.cloud_rounded, size: 36, color: Color(0xFFD0E0F0)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Animated Glow ───────────────

class _AnimatedGlow extends StatelessWidget {
  const _AnimatedGlow({
    required this.anim,
    required this.isNight,
    required this.isRaining,
  });

  final AnimationController anim;
  final bool isNight;
  final bool isRaining;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final pulse = 0.65 + (0.35 * math.sin(anim.value * 2 * math.pi));
        final baseColor = isNight
            ? const Color(0xFFA8BCFF)
            : isRaining
                ? const Color(0xFF6ABEFF)
                : const Color(0xFFFFD766);

        return Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.14 * pulse),
                blurRadius: 44 * pulse,
                spreadRadius: 10 * pulse,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────── Hero Metric Tile ───────────────

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFD0E0FF).withValues(alpha: 0.86),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Metric Card ───────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.35),
            gradient[1].withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              color: gradient[1].withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Sun Rays Painter ───────────────

class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const rayCount = 8;
    const innerRadius = 17.0;
    const outerRadius = 25.0;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final start = Offset(
        center.dx + (innerRadius * math.cos(angle)),
        center.dy + (innerRadius * math.sin(angle)),
      );
      final end = Offset(
        center.dx + (outerRadius * math.cos(angle)),
        center.dy + (outerRadius * math.sin(angle)),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter oldDelegate) =>
      oldDelegate.color != color;
}
