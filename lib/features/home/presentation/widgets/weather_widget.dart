import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/mqtt_live_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'weather_condition.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final MqttLiveService _mqtt;
  StreamSubscription<WeatherReading>? _sub;
  WeatherReading? _reading;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _mqtt = getIt<MqttLiveService>()..connect();
    _sub = _mqtt.weatherReadings.listen((r) {
      if (mounted) setState(() => _reading = r);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>() ?? AppColors.darkTokens;
    final r = _reading;
    if (r == null) return _WaitingCard(tokens: tokens);

    final cond = resolveCondition(r);
    final humidity = r.humidity.round().clamp(0, 100);
    final lightPct = r.light.round().clamp(0, 100);
    final waterPct = r.water.round().clamp(0, 100);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cond.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.deviceCardBorder.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(color: cond.gradient[1].withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 5)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -10, right: -8, child: _Glow(anim: _anim, color: cond.glowColor)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cond.label,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(_subLabel(cond, r),
                          style: const TextStyle(color: Color(0xFFB7CEF2), fontSize: 11, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    _ConditionIcon(anim: _anim, condition: cond),
                  ]),
                  const SizedBox(height: 12),
                  // ── Temperature ──
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.temperature.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w300, height: 1, letterSpacing: -1.8)),
                    const Padding(padding: EdgeInsets.only(top: 8),
                      child: Text('°C', style: TextStyle(color: Color(0xFFB7CEF2), fontSize: 20, fontWeight: FontWeight.w500))),
                  ]),
                  const SizedBox(height: 16),
                  // ── Divider ──
                  Container(height: 1, decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0),
                    ]),
                  )),
                  const SizedBox(height: 14),
                  // ── Metrics ──
                  Row(children: [
                    Expanded(child: _MetricTile(label: 'Humidity', value: '$humidity%',
                      icon: Icons.water_drop_rounded, color: const Color(0xFF67D3FF))),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricTile(label: 'Light', value: '$lightPct%',
                      icon: cond.isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      color: cond.isNight ? const Color(0xFFB7C9FF) : const Color(0xFFFFD767))),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricTile(label: 'Water', value: '$waterPct%',
                      icon: cond.hasRain ? Icons.umbrella_rounded : Icons.grain_rounded,
                      color: cond.hasRain ? const Color(0xFF7BC4FF) : const Color(0xFF9FD1FF))),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _subLabel(WeatherCondition c, WeatherReading r) {
    final t = r.temperature;
    final feel = t >= 35 ? 'Very hot' : t >= 25 ? 'Warm' : t >= 15 ? 'Comfortable' : t >= 5 ? 'Cool' : 'Cold';
    if (c == WeatherCondition.thunderstorm) return '$feel · Watch out for lightning';
    if (c == WeatherCondition.sunShower) return '$feel · Sun & rain together';
    if (c == WeatherCondition.foggy) return '$feel · Low visibility';
    return '$feel · ${r.humidity.round()}% humidity';
  }
}

// ─────────────── Animated condition icon (56×56) ───────────────

class _ConditionIcon extends StatelessWidget {
  const _ConditionIcon({required this.anim, required this.condition});
  final AnimationController anim;
  final WeatherCondition condition;

  @override
  Widget build(BuildContext context) {
    switch (condition) {
      case WeatherCondition.clearSunny:     return _Sun(anim: anim);
      case WeatherCondition.partlyCloudy:   return _SunCloud(anim: anim);
      case WeatherCondition.cloudy:         return _Clouds(anim: anim);
      case WeatherCondition.foggy:          return _Fog(anim: anim);
      case WeatherCondition.drizzle:        return _Drizzle(anim: anim);
      case WeatherCondition.rainy:          return _Rain(anim: anim, heavy: false);
      case WeatherCondition.heavyRain:      return _Rain(anim: anim, heavy: true);
      case WeatherCondition.thunderstorm:   return _Thunder(anim: anim);
      case WeatherCondition.sunShower:      return _SunShower(anim: anim);
      case WeatherCondition.clearNight:     return _Moon(anim: anim, stars: true);
      case WeatherCondition.cloudyNight:    return _MoonCloud(anim: anim);
      case WeatherCondition.rainyNight:     return _NightRain(anim: anim);
    }
  }
}

// ── Sun ──
class _Sun extends StatelessWidget {
  const _Sun({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final rot = anim.value * 2 * math.pi;
    final s = 1.0 + 0.06 * math.sin(anim.value * 4 * math.pi);
    return Transform.scale(scale: s, child: SizedBox(width: 56, height: 56,
      child: Stack(alignment: Alignment.center, children: [
        Transform.rotate(angle: rot, child: CustomPaint(size: const Size(56, 56),
          painter: _SunRaysPainter(color: const Color(0xFFFFD766).withValues(alpha: 0.55)))),
        Container(width: 26, height: 26, decoration: const BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Color(0xFFFFE59F), Color(0xFFFFCF5E), Color(0xFFFFB748)]))),
      ])));
  }
}

// ── Sun + Cloud ──
class _SunCloud extends StatelessWidget {
  const _SunCloud({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final drift = math.sin(anim.value * 2 * math.pi) * 2;
    return SizedBox(width: 56, height: 56, child: Stack(children: [
      Positioned(top: 2, right: 2, child: Transform.scale(scale: 0.55, child: _Sun(anim: anim))),
      Positioned(bottom: 4 + drift, left: 0,
        child: Icon(Icons.cloud_rounded, size: 36, color: Colors.white.withValues(alpha: 0.85))),
    ]));
  }
}

// ── Clouds ──
class _Clouds extends StatelessWidget {
  const _Clouds({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final d1 = math.sin(anim.value * 2 * math.pi) * 1.5;
    final d2 = math.cos(anim.value * 2 * math.pi) * 1.5;
    return SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
      Positioned(top: 6 + d1, left: 2, child: const Icon(Icons.cloud_rounded, size: 30, color: Color(0xFF90A4AE))),
      Positioned(top: 12 + d2, right: 0, child: const Icon(Icons.cloud_rounded, size: 36, color: Color(0xFFB0BEC5))),
    ]));
  }
}

// ── Fog ──
class _Fog extends StatelessWidget {
  const _Fog({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final o = 0.4 + 0.3 * math.sin(anim.value * 2 * math.pi);
    return SizedBox(width: 56, height: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(height: 3, width: 40, margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: o))),
      Container(height: 3, width: 32, margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: o * 0.8))),
      Container(height: 3, width: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.white.withValues(alpha: o * 0.6))),
    ]));
  }
}

// ── Drizzle (cloud + small drops) ──
class _Drizzle extends StatelessWidget {
  const _Drizzle({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final d = math.sin(anim.value * 3 * math.pi) * 2;
    return SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
      const Positioned(top: 4, child: Icon(Icons.cloud_rounded, size: 32, color: Color(0xFFB0BEC5))),
      Positioned(bottom: 6 + d, left: 18, child: Icon(Icons.water_drop, size: 8, color: const Color(0xFF90CAF9).withValues(alpha: 0.7))),
      Positioned(bottom: 8 - d, right: 18, child: Icon(Icons.water_drop, size: 8, color: const Color(0xFF90CAF9).withValues(alpha: 0.7))),
    ]));
  }
}

// ── Rain ──
class _Rain extends StatelessWidget {
  const _Rain({required this.anim, required this.heavy});
  final AnimationController anim;
  final bool heavy;

  @override
  Widget build(BuildContext context) {
    final d = math.sin(anim.value * 4 * math.pi) * 2;
    final cloudColor = heavy ? const Color(0xFF78909C) : const Color(0xFFC3D6EA);
    return SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
      Positioned(top: 3, child: Icon(Icons.cloud_rounded, size: 34, color: cloudColor)),
      Positioned(bottom: 2 + d, left: 14,
        child: Icon(Icons.water_drop, size: heavy ? 12 : 10, color: const Color(0xFF68B9FF).withValues(alpha: 0.9))),
      Positioned(bottom: 6 - d, child:
        Icon(Icons.water_drop, size: heavy ? 14 : 12, color: const Color(0xFF4FAEFF).withValues(alpha: 0.9))),
      Positioned(bottom: 3 + d * 0.7, right: 14,
        child: Icon(Icons.water_drop, size: heavy ? 11 : 9, color: const Color(0xFF89CCFF).withValues(alpha: 0.85))),
      if (heavy) Positioned(bottom: 8 - d * 0.5, left: 22,
        child: Icon(Icons.water_drop, size: 10, color: const Color(0xFF64B5F6).withValues(alpha: 0.8))),
    ]));
  }
}

// ── Thunderstorm ──
class _Thunder extends StatelessWidget {
  const _Thunder({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final d = math.sin(anim.value * 4 * math.pi) * 2;
    // Lightning flash effect
    final flash = (math.sin(anim.value * 12 * math.pi) > 0.85) ? 1.0 : 0.0;
    return SizedBox(width: 56, height: 56, child: Stack(alignment: Alignment.center, children: [
      const Positioned(top: 2, child: Icon(Icons.cloud_rounded, size: 36, color: Color(0xFF546E7A))),
      // Lightning bolt
      Positioned(bottom: 10, child: Opacity(opacity: flash,
        child: const Icon(Icons.bolt_rounded, size: 22, color: Color(0xFFFFEB3B)))),
      Positioned(bottom: 2 + d, left: 14,
        child: Icon(Icons.water_drop, size: 10, color: const Color(0xFF68B9FF).withValues(alpha: 0.9))),
      Positioned(bottom: 4 - d, right: 14,
        child: Icon(Icons.water_drop, size: 10, color: const Color(0xFF89CCFF).withValues(alpha: 0.85))),
    ]));
  }
}

// ── Sun Shower (sun + rain) ──
class _SunShower extends StatelessWidget {
  const _SunShower({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final d = math.sin(anim.value * 4 * math.pi) * 2;
    return SizedBox(width: 56, height: 56, child: Stack(children: [
      Positioned(top: 0, right: 0, child: Transform.scale(scale: 0.45, child: _Sun(anim: anim))),
      Positioned(top: 8, left: 0, child: Icon(Icons.cloud_rounded, size: 30, color: Colors.white.withValues(alpha: 0.8))),
      Positioned(bottom: 4 + d, left: 8,
        child: Icon(Icons.water_drop, size: 9, color: const Color(0xFF64B5F6).withValues(alpha: 0.8))),
      Positioned(bottom: 6 - d, left: 20,
        child: Icon(Icons.water_drop, size: 10, color: const Color(0xFF42A5F5).withValues(alpha: 0.85))),
    ]));
  }
}

// ── Moon (with stars) ──
class _Moon extends StatelessWidget {
  const _Moon({required this.anim, this.stars = false});
  final AnimationController anim;
  final bool stars;

  @override
  Widget build(BuildContext context) {
    final y = math.sin(anim.value * 2 * math.pi) * 1.6;
    final twinkle = 0.3 + 0.7 * math.sin(anim.value * 6 * math.pi).abs();
    return Transform.translate(offset: Offset(0, y), child: SizedBox(width: 56, height: 56,
      child: Stack(children: [
        if (stars) ...[
          Positioned(top: 6, left: 6, child: Icon(Icons.star_rounded, size: 8, color: Colors.white.withValues(alpha: twinkle * 0.7))),
          Positioned(top: 14, right: 4, child: Icon(Icons.star_rounded, size: 6, color: Colors.white.withValues(alpha: twinkle * 0.5))),
          Positioned(bottom: 16, left: 2, child: Icon(Icons.star_rounded, size: 7, color: Colors.white.withValues(alpha: twinkle * 0.6))),
        ],
        Positioned(top: 10, left: 14, child: Container(width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD5DEFF),
            boxShadow: [BoxShadow(color: const Color(0xFFBECCFF).withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1)]))),
        Positioned(top: 7, left: 22, child: Container(width: 24, height: 24,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A3B7E)))),
      ])));
  }
}

// ── Moon + Cloud ──
class _MoonCloud extends StatelessWidget {
  const _MoonCloud({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final drift = math.sin(anim.value * 2 * math.pi) * 1.5;
    return SizedBox(width: 56, height: 56, child: Stack(children: [
      Positioned(top: 2, right: 2, child: Transform.scale(scale: 0.7, child: _Moon(anim: anim))),
      Positioned(bottom: 6 + drift, left: 0,
        child: Icon(Icons.cloud_rounded, size: 30, color: const Color(0xFF90A4AE).withValues(alpha: 0.7))),
    ]));
  }
}

// ── Night Rain ──
class _NightRain extends StatelessWidget {
  const _NightRain({required this.anim});
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final d = math.sin(anim.value * 4 * math.pi) * 2;
    return SizedBox(width: 56, height: 56, child: Stack(children: [
      Positioned(top: 0, right: 2, child: Transform.scale(scale: 0.5, child: _Moon(anim: anim))),
      Positioned(top: 10, left: 0, child: const Icon(Icons.cloud_rounded, size: 30, color: Color(0xFF546E7A))),
      Positioned(bottom: 4 + d, left: 8,
        child: Icon(Icons.water_drop, size: 9, color: const Color(0xFF64B5F6).withValues(alpha: 0.8))),
      Positioned(bottom: 6 - d, left: 20,
        child: Icon(Icons.water_drop, size: 11, color: const Color(0xFF42A5F5).withValues(alpha: 0.85))),
    ]));
  }
}

// ─────────────── Glow ───────────────

class _Glow extends StatelessWidget {
  const _Glow({required this.anim, required this.color});
  final AnimationController anim;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = 0.65 + 0.35 * math.sin(anim.value * 2 * math.pi);
    return Container(width: 94, height: 94, decoration: BoxDecoration(shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.14 * p), blurRadius: 44 * p, spreadRadius: 10 * p)]));
  }
}

// ─────────────── Waiting Card ───────────────

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.tokens});
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D2954), Color(0xFF184986), Color(0xFF2B74B4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.deviceCardBorder.withValues(alpha: 0.25)),
      ),
      child: const Row(children: [
        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
        SizedBox(width: 12),
        Expanded(child: Text('Waiting for weather data…',
          style: TextStyle(color: Color(0xFFD7E6FF), fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

// ─────────────── Metric Tile ───────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: const Color(0xFFD0E0FF).withValues(alpha: 0.86), fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
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
    final paint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round;
    const rayCount = 8;
    const inner = 17.0;
    const outer = 25.0;
    for (var i = 0; i < rayCount; i++) {
      final a = (i * 2 * math.pi) / rayCount;
      canvas.drawLine(
        Offset(center.dx + inner * math.cos(a), center.dy + inner * math.sin(a)),
        Offset(center.dx + outer * math.cos(a), center.dy + outer * math.sin(a)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) => old.color != color;
}
