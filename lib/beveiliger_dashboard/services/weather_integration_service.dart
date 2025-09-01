import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';

/// Service for Dutch weather integration using KNMI data for security operations
/// FIXED: Complete timer lifecycle management to prevent memory leaks
class WeatherIntegrationService {
  final StreamController<WeatherData> _weatherController = 
      StreamController<WeatherData>.broadcast();

  // FIXED: Store timer reference for proper cleanup
  Timer? _weatherMonitoringTimer;
  bool _isDisposed = false;

  /// Stream for real-time weather updates
  Stream<WeatherData> get weatherStream => _weatherController.stream;

  /// Get current weather data for security location
  Future<WeatherData> getCurrentWeatherForShifts(double latitude, double longitude) async {
    return getCurrentWeather(latitude, longitude);
  }

  /// Get current weather data for security location
  Future<WeatherData> getCurrentWeather(double latitude, double longitude) async {
    // Check if service was disposed
    if (_isDisposed) {
      return WeatherData(
        temperature: 15.0,
        feelsLike: 15.0,
        humidity: 60,
        windSpeed: 5.0,
        windDirection: 'W',
        description: 'Unknown',
        dutchDescription: 'Onbekend',
        condition: WeatherCondition.cloudy,
        visibility: 10.0,
        uvIndex: 3,
        precipitation: 0.0,
        timestamp: DateTime.now(),
        location: _getLocationName(latitude, longitude),
        alerts: [],
      );
    }
    
    // Simulate KNMI API call delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Mock weather data - in production this would call KNMI API
    final random = Random();
    final temperature = 5.0 + random.nextDouble() * 20.0; // 5-25°C range
    final humidity = 40 + random.nextInt(50); // 40-90% range
    final windSpeed = random.nextDouble() * 15.0; // 0-15 m/s
    final precipitation = random.nextDouble() < 0.3 ? random.nextDouble() * 10.0 : 0.0;
    
    // Determine weather condition based on precipitation and temperature
    WeatherCondition condition;
    if (precipitation > 5.0) {
      condition = temperature < 2.0 ? WeatherCondition.snowy : WeatherCondition.rainy;
    } else if (precipitation > 0.5) {
      condition = WeatherCondition.rainy;
    } else if (windSpeed > 10.0) {
      condition = WeatherCondition.windy;
    } else {
      condition = _isNightTime() ? WeatherCondition.cloudy : WeatherCondition.sunny;
    }

    final weatherData = WeatherData(
      temperature: temperature,
      feelsLike: temperature + (windSpeed > 5.0 ? -2.0 : 0.0),
      humidity: humidity,
      windSpeed: windSpeed,
      windDirection: _getWindDirection(random.nextInt(360)),
      description: _getWeatherDescription(condition),
      dutchDescription: _getDutchWeatherDescription(condition),
      condition: condition,
      visibility: _calculateVisibility(condition, precipitation),
      uvIndex: _calculateUVIndex(condition),
      precipitation: precipitation,
      timestamp: DateTime.now(),
      location: _getLocationName(latitude, longitude),
      alerts: _generateWeatherAlerts(condition, temperature, windSpeed, precipitation),
    );

    // Only add to stream if not disposed
    if (!_isDisposed && !_weatherController.isClosed) {
      _weatherController.add(weatherData);
    }
    
    return weatherData;
  }

  /// Get weather forecast for upcoming shifts
  Future<List<WeatherData>> getWeatherForecast(
    double latitude, 
    double longitude,
    int days,
  ) async {
    // Simulate KNMI forecast API call
    await Future.delayed(const Duration(milliseconds: 600));

    final forecast = <WeatherData>[];
    final random = Random();

    for (int i = 0; i < days * 8; i++) { // 3-hour intervals
      final futureTime = DateTime.now().add(Duration(hours: i * 3));
      final baseTemp = 10.0 + sin(i * 0.26) * 8.0 + random.nextDouble() * 4.0;
      
      forecast.add(WeatherData(
        temperature: baseTemp,
        feelsLike: baseTemp - random.nextDouble() * 3.0,
        humidity: 50 + random.nextInt(40),
        windSpeed: random.nextDouble() * 12.0,
        windDirection: _getWindDirection(random.nextInt(360)),
        description: _getWeatherDescription(_generateRandomCondition(random)),
        dutchDescription: _getDutchWeatherDescription(_generateRandomCondition(random)),
        condition: _generateRandomCondition(random),
        visibility: 5.0 + random.nextDouble() * 15.0,
        uvIndex: _isNightTime(futureTime) ? 0 : random.nextInt(8) + 1,
        precipitation: random.nextDouble() < 0.25 ? random.nextDouble() * 8.0 : 0.0,
        timestamp: futureTime,
        location: _getLocationName(latitude, longitude),
        alerts: [],
      ));
    }

    return forecast;
  }

  /// FIXED: Start real-time weather monitoring with proper timer management
  void startRealTimeWeatherMonitoring(double latitude, double longitude) {
    // Prevent multiple timers and disposed state
    if (_isDisposed || _weatherMonitoringTimer != null) return;
    
    _weatherMonitoringTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      // Check if service was disposed during timer execution
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      try {
        final weather = await getCurrentWeather(latitude, longitude);
        
        // Double-check disposal state before adding to stream
        if (!_isDisposed && !_weatherController.isClosed) {
          _weatherController.add(weather);
        }
      } catch (e) {
        // Log error but continue monitoring
        if (kDebugMode) debugPrint('Weather monitoring error: $e');
      }
    });
  }
  
  /// FIXED: Stop real-time weather monitoring and cancel timer
  void stopRealTimeWeatherMonitoring() {
    _weatherMonitoringTimer?.cancel();
    _weatherMonitoringTimer = null;
  }

  /// Calculate visibility based on weather conditions
  double _calculateVisibility(WeatherCondition condition, double precipitation) {
    switch (condition) {
      case WeatherCondition.foggy:
        return 0.5 + Random().nextDouble() * 1.0; // 0.5-1.5 km
      case WeatherCondition.rainy:
        return precipitation > 5.0 ? 2.0 + Random().nextDouble() * 3.0 : 5.0 + Random().nextDouble() * 10.0;
      case WeatherCondition.snowy:
        return 1.0 + Random().nextDouble() * 4.0; // 1-5 km
      case WeatherCondition.stormy:
        return 8.0 + Random().nextDouble() * 7.0; // 8-15 km
      default:
        return 15.0 + Random().nextDouble() * 10.0; // 15-25 km
    }
  }

  /// Calculate UV index based on conditions and time
  int _calculateUVIndex(WeatherCondition condition) {
    if (_isNightTime()) return 0;
    
    final hour = DateTime.now().hour;
    int baseUV = 0;
    
    if (hour >= 10 && hour <= 16) {
      baseUV = 5 + Random().nextInt(5); // Peak hours: 5-9
    } else if (hour >= 8 && hour <= 18) {
      baseUV = 2 + Random().nextInt(4); // Moderate hours: 2-5
    } else {
      baseUV = Random().nextInt(3); // Low hours: 0-2
    }

    // Adjust for weather conditions
    switch (condition) {
      case WeatherCondition.sunny:
        return baseUV;
      case WeatherCondition.partlyCloudy:
        return (baseUV * 0.8).round();
      case WeatherCondition.cloudy:
        return (baseUV * 0.6).round();
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
      case WeatherCondition.snowy:
      case WeatherCondition.foggy:
        return (baseUV * 0.3).round();
      default:
        return baseUV;
    }
  }

  /// Generate weather alerts for security operations
  List<WeatherAlert> _generateWeatherAlerts(
    WeatherCondition condition,
    double temperature,
    double windSpeed,
    double precipitation,
  ) {
    final alerts = <WeatherAlert>[];
    final now = DateTime.now();

    // Temperature alerts
    if (temperature < -5.0) {
      alerts.add(WeatherAlert(
        id: 'cold_${now.millisecondsSinceEpoch}',
        type: WeatherAlertType.cold,
        severity: WeatherAlertSeverity.high,
        dutchTitle: 'Extreme Kou Waarschuwing',
        dutchDescription: 'Zeer lage temperatuur (${temperature.toStringAsFixed(1)}°C). Risico op onderkoeling. Extra warme kleding verplicht.',
        startTime: now,
        endTime: now.add(const Duration(hours: 6)),
        affectedAreas: ['Nederland'],
      ));
    } else if (temperature > 30.0) {
      alerts.add(WeatherAlert(
        id: 'heat_${now.millisecondsSinceEpoch}',
        type: WeatherAlertType.heat,
        severity: WeatherAlertSeverity.moderate,
        dutchTitle: 'Hitte Waarschuwing',
        dutchDescription: 'Hoge temperatuur (${temperature.toStringAsFixed(1)}°C). Risico op oververhitting. Veel water drinken en schaduw zoeken.',
        startTime: now,
        endTime: now.add(const Duration(hours: 8)),
        affectedAreas: ['Nederland'],
      ));
    }

    // Wind alerts
    if (windSpeed > 12.0) {
      alerts.add(WeatherAlert(
        id: 'wind_${now.millisecondsSinceEpoch}',
        type: WeatherAlertType.wind,
        severity: WeatherAlertSeverity.high,
        dutchTitle: 'Storm Waarschuwing',
        dutchDescription: 'Harde wind (${windSpeed.toStringAsFixed(1)} m/s). Gevaar van vallende objecten. Vermijd open terreinen.',
        startTime: now,
        endTime: now.add(const Duration(hours: 4)),
        affectedAreas: ['Nederland'],
      ));
    }

    // Precipitation alerts
    if (precipitation > 8.0) {
      alerts.add(WeatherAlert(
        id: 'rain_${now.millisecondsSinceEpoch}',
        type: WeatherAlertType.rain,
        severity: WeatherAlertSeverity.moderate,
        dutchTitle: 'Zware Neerslag Waarschuwing',
        dutchDescription: 'Intense regenval (${precipitation.toStringAsFixed(1)} mm/h). Verhoogd sliprisico. Gebruik anti-slip schoenen.',
        startTime: now,
        endTime: now.add(const Duration(hours: 3)),
        affectedAreas: ['Nederland'],
      ));
    }

    return alerts;
  }


  /// Get wind direction as string
  String _getWindDirection(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees / 45) % 8).round() % 8;
    return directions[index];
  }

  /// Get weather description in English
  String _getWeatherDescription(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Clear sky';
      case WeatherCondition.partlyCloudy:
        return 'Partly cloudy';
      case WeatherCondition.cloudy:
        return 'Overcast';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.snowy:
        return 'Snow';
      case WeatherCondition.stormy:
        return 'Thunderstorms';
      case WeatherCondition.foggy:
        return 'Fog';
      case WeatherCondition.windy:
        return 'Windy';
    }
  }

  /// Get Dutch weather description
  String _getDutchWeatherDescription(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Zonnig';
      case WeatherCondition.partlyCloudy:
        return 'Wisselend bewolkt';
      case WeatherCondition.cloudy:
        return 'Bewolkt';
      case WeatherCondition.rainy:
        return 'Regen';
      case WeatherCondition.snowy:
        return 'Sneeuw';
      case WeatherCondition.stormy:
        return 'Onweer';
      case WeatherCondition.foggy:
        return 'Mist';
      case WeatherCondition.windy:
        return 'Winderig';
    }
  }

  /// Get location name based on coordinates (simplified)
  String _getLocationName(double latitude, double longitude) {
    // In production, this would use reverse geocoding API
    if (latitude >= 52.3 && latitude <= 52.4 && longitude >= 4.8 && longitude <= 5.0) {
      return 'Amsterdam';
    } else if (latitude >= 51.9 && latitude <= 52.0 && longitude >= 4.4 && longitude <= 4.6) {
      return 'Rotterdam';
    } else if (latitude >= 52.0 && latitude <= 52.1 && longitude >= 5.1 && longitude <= 5.3) {
      return 'Utrecht';
    }
    return 'Nederland';
  }

  /// Check if it's night time
  bool _isNightTime([DateTime? time]) {
    final checkTime = time ?? DateTime.now();
    final hour = checkTime.hour;
    return hour < 6 || hour >= 22;
  }

  /// Generate random weather condition for forecasts
  WeatherCondition _generateRandomCondition(Random random) {
    final conditions = WeatherCondition.values;
    return conditions[random.nextInt(conditions.length)];
  }

  /// FIXED: Comprehensive disposal with timer cancellation
  void dispose() {
    _isDisposed = true;
    
    // Cancel timer first to prevent any pending operations
    _weatherMonitoringTimer?.cancel();
    _weatherMonitoringTimer = null;
    
    // Close stream controller
    if (!_weatherController.isClosed) {
      _weatherController.close();
    }
  }
}