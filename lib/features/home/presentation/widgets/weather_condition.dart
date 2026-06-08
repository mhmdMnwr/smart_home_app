import 'package:flutter/material.dart';
import '../../../../core/network/mqtt_live_service.dart';

/// All possible weather conditions derived from sensor values.
enum WeatherCondition {
  clearSunny,       // high light, no rain
  partlyCloudy,     // medium light, no rain
  cloudy,           // low light, no rain
  foggy,            // low light, very high humidity, no rain
  drizzle,          // light rain
  rainy,            // moderate rain
  heavyRain,        // heavy rain
  thunderstorm,     // heavy rain + very low light
  sunShower,        // rain + decent light
  clearNight,       // night, no rain
  cloudyNight,      // night, low-ish light, no rain
  rainyNight,       // night + rain
}

extension WeatherConditionX on WeatherCondition {
  String get label {
    switch (this) {
      case WeatherCondition.clearSunny:    return 'Clear & Sunny';
      case WeatherCondition.partlyCloudy:  return 'Partly Cloudy';
      case WeatherCondition.cloudy:        return 'Cloudy';
      case WeatherCondition.foggy:         return 'Foggy';
      case WeatherCondition.drizzle:       return 'Drizzle';
      case WeatherCondition.rainy:         return 'Rainy';
      case WeatherCondition.heavyRain:     return 'Heavy Rain';
      case WeatherCondition.thunderstorm:  return 'Thunderstorm';
      case WeatherCondition.sunShower:     return 'Sun Shower';
      case WeatherCondition.clearNight:    return 'Clear Night';
      case WeatherCondition.cloudyNight:   return 'Cloudy Night';
      case WeatherCondition.rainyNight:    return 'Rainy Night';
    }
  }

  bool get isNight {
    switch (this) {
      case WeatherCondition.clearNight:
      case WeatherCondition.cloudyNight:
      case WeatherCondition.rainyNight:
        return true;
      default:
        return false;
    }
  }

  bool get hasRain {
    switch (this) {
      case WeatherCondition.drizzle:
      case WeatherCondition.rainy:
      case WeatherCondition.heavyRain:
      case WeatherCondition.thunderstorm:
      case WeatherCondition.sunShower:
      case WeatherCondition.rainyNight:
        return true;
      default:
        return false;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case WeatherCondition.clearSunny:
        return const [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)];
      case WeatherCondition.partlyCloudy:
        return const [Color(0xFF0E2A5A), Color(0xFF15508E), Color(0xFF2D7FC5)];
      case WeatherCondition.cloudy:
        return const [Color(0xFF263238), Color(0xFF37474F), Color(0xFF546E7A)];
      case WeatherCondition.foggy:
        return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)];
      case WeatherCondition.drizzle:
        return const [Color(0xFF1A3A5C), Color(0xFF24506E), Color(0xFF366680)];
      case WeatherCondition.rainy:
        return const [Color(0xFF0F2E52), Color(0xFF17466D), Color(0xFF285D84)];
      case WeatherCondition.heavyRain:
        return const [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF1F3044)];
      case WeatherCondition.thunderstorm:
        return const [Color(0xFF0A0E1A), Color(0xFF141822), Color(0xFF1C2030)];
      case WeatherCondition.sunShower:
        return const [Color(0xFF1A4068), Color(0xFF2D6A9E), Color(0xFF4A90C4)];
      case WeatherCondition.clearNight:
        return const [Color(0xFF0A1A3D), Color(0xFF132B61), Color(0xFF1A3B7E)];
      case WeatherCondition.cloudyNight:
        return const [Color(0xFF0E1628), Color(0xFF1A2440), Color(0xFF263352)];
      case WeatherCondition.rainyNight:
        return const [Color(0xFF0A1220), Color(0xFF141E30), Color(0xFF1E2D44)];
    }
  }

  Color get glowColor {
    switch (this) {
      case WeatherCondition.clearSunny:
      case WeatherCondition.partlyCloudy:
      case WeatherCondition.sunShower:
        return const Color(0xFFFFD766);
      case WeatherCondition.clearNight:
      case WeatherCondition.cloudyNight:
        return const Color(0xFFA8BCFF);
      case WeatherCondition.thunderstorm:
        return const Color(0xFFE0E060);
      default:
        return const Color(0xFF6ABEFF);
    }
  }
}

/// Resolves the current weather condition from sensor readings.
WeatherCondition resolveCondition(WeatherReading r) {
  final light = r.light;
  final water = r.water;
  final humidity = r.humidity;
  final isNight = light < 15;

  // ── Night conditions ──
  if (isNight) {
    if (water >= 35) return WeatherCondition.rainyNight;
    if (light < 8) return WeatherCondition.clearNight;
    return WeatherCondition.cloudyNight;
  }

  // ── Thunderstorm: heavy rain + very dark ──
  if (water >= 70 && light < 25) return WeatherCondition.thunderstorm;

  // ── Heavy rain ──
  if (water >= 70) return WeatherCondition.heavyRain;

  // ── Sun shower: rain but still bright ──
  if (water >= 35 && light >= 50) return WeatherCondition.sunShower;

  // ── Rainy ──
  if (water >= 35) return WeatherCondition.rainy;

  // ── Drizzle ──
  if (water >= 15) return WeatherCondition.drizzle;

  // ── Foggy: very humid + low light ──
  if (humidity >= 85 && light < 35) return WeatherCondition.foggy;

  // ── Clear sunny ──
  if (light >= 65) return WeatherCondition.clearSunny;

  // ── Partly cloudy ──
  if (light >= 35) return WeatherCondition.partlyCloudy;

  // ── Cloudy ──
  return WeatherCondition.cloudy;
}
