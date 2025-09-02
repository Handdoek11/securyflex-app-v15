import 'package:equatable/equatable.dart';

/// Weather data for outdoor security shifts using KNMI (Dutch weather service)
class WeatherData extends Equatable {
  final double temperature;        // Temperature in Celsius
  final double feelsLike;         // Perceived temperature
  final int humidity;             // Humidity percentage
  final double windSpeed;         // Wind speed in km/h
  final String windDirection;     // Wind direction (N, NE, etc.)
  final String description;       // Weather description
  final String dutchDescription;  // Dutch weather description
  final WeatherCondition condition;
  final int uvIndex;              // UV index (0-11)
  final double precipitation;     // Precipitation in mm
  final double visibility;        // Visibility in km
  final DateTime timestamp;
  final String location;
  final List<WeatherAlert> alerts; // Weather alerts for safety

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.description,
    required this.dutchDescription,
    required this.condition,
    required this.uvIndex,
    required this.precipitation,
    required this.visibility,
    required this.timestamp,
    required this.location,
    this.alerts = const [],
  });

  /// Get clothing recommendation for outdoor security work
  String get dutchClothingRecommendation {
    if (temperature < 0) {
      return 'Winterjas, handschoenen en warme muts verplicht';
    } else if (temperature < 10) {
      return 'Jas en warme kleding aanbevolen';
    } else if (temperature < 20) {
      return 'Lange mouwen of vest aanbevolen';
    } else if (temperature > 30) {
      return 'Lichte kleding en extra water meenemen';
    } else {
      return 'Standaard beveiligingsuniform geschikt';
    }
  }

  /// Get safety warnings for outdoor work
  List<String> get dutchSafetyWarnings {
    final warnings = <String>[];
    
    if (temperature < -5) {
      warnings.add('WAARSCHUWING: Extreme kou - risico op bevriezing');
    }
    
    if (temperature > 35) {
      warnings.add('WAARSCHUWING: Extreme hitte - risico op oververhitting');
    }
    
    if (windSpeed > 50) {
      warnings.add('WAARSCHUWING: Harde wind - vermijd hoge structuren');
    }
    
    if (precipitation > 10) {
      warnings.add('WAARSCHUWING: Zware neerslag - extra voorzichtigheid');
    }
    
    if (uvIndex >= 8) {
      warnings.add('WAARSCHUWING: Hoge UV-index - zonbescherming vereist');
    }
    
    if (visibility < 1.0) {
      warnings.add('WAARSCHUWING: Slecht zicht - verhoogde alertheid vereist');
    }
    
    return warnings;
  }

  /// Check if weather conditions are suitable for outdoor security work
  bool get isSuitableForOutdoorWork {
    if (temperature < -10 || temperature > 40) return false;
    if (windSpeed > 70) return false;
    if (precipitation > 25) return false;
    if (visibility < 0.5) return false;
    return alerts.every((alert) => alert.severity != WeatherAlertSeverity.extreme);
  }

  /// Get Dutch weather emoji
  String get weatherEmoji {
    switch (condition) {
      case WeatherCondition.sunny:
        return '☀️';
      case WeatherCondition.partlyCloudy:
        return '⛅';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.snowy:
        return '❄️';
      case WeatherCondition.stormy:
        return '⛈️';
      case WeatherCondition.foggy:
        return '🌫️';
      case WeatherCondition.windy:
        return '💨';
    }
  }

  WeatherData copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    String? windDirection,
    String? description,
    String? dutchDescription,
    WeatherCondition? condition,
    int? uvIndex,
    double? precipitation,
    double? visibility,
    DateTime? timestamp,
    String? location,
    List<WeatherAlert>? alerts,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      description: description ?? this.description,
      dutchDescription: dutchDescription ?? this.dutchDescription,
      condition: condition ?? this.condition,
      uvIndex: uvIndex ?? this.uvIndex,
      precipitation: precipitation ?? this.precipitation,
      visibility: visibility ?? this.visibility,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      alerts: alerts ?? this.alerts,
    );
  }

  /// JSON serialization
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDirection: json['windDirection'] as String,
      description: json['description'] as String,
      dutchDescription: json['dutchDescription'] as String,
      condition: WeatherCondition.values.firstWhere((e) => e.name == json['condition']),
      uvIndex: json['uvIndex'] as int,
      precipitation: (json['precipitation'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      location: json['location'] as String,
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((alertJson) => WeatherAlert.fromJson(alertJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'description': description,
      'dutchDescription': dutchDescription,
      'condition': condition.name,
      'uvIndex': uvIndex,
      'precipitation': precipitation,
      'visibility': visibility,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'location': location,
      'alerts': alerts.map((alert) => alert.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    temperature,
    feelsLike,
    humidity,
    windSpeed,
    windDirection,
    description,
    dutchDescription,
    condition,
    uvIndex,
    precipitation,
    visibility,
    timestamp,
    location,
    alerts,
  ];
}

/// Weather conditions enum
enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  snowy,
  stormy,
  foggy,
  windy,
}

/// Weather alert for safety warnings
class WeatherAlert extends Equatable {
  final String id;
  final WeatherAlertType type;
  final WeatherAlertSeverity severity;
  final String dutchTitle;
  final String dutchDescription;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> affectedAreas;

  const WeatherAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.dutchTitle,
    required this.dutchDescription,
    required this.startTime,
    required this.endTime,
    required this.affectedAreas,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// JSON serialization
  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] as String,
      type: WeatherAlertType.values.firstWhere((e) => e.name == json['type']),
      severity: WeatherAlertSeverity.values.firstWhere((e) => e.name == json['severity']),
      dutchTitle: json['dutchTitle'] as String,
      dutchDescription: json['dutchDescription'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int),
      affectedAreas: List<String>.from(json['affectedAreas'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'dutchTitle': dutchTitle,
      'dutchDescription': dutchDescription,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'affectedAreas': affectedAreas,
    };
  }

  @override
  List<Object> get props => [
    id,
    type,
    severity,
    dutchTitle,
    dutchDescription,
    startTime,
    endTime,
    affectedAreas,
  ];
}

/// Weather alert types
enum WeatherAlertType {
  wind,           // Wind waarschuwing
  rain,           // Regen waarschuwing
  snow,           // Sneeuw waarschuwing
  ice,            // IJzel waarschuwing
  fog,            // Mist waarschuwing
  heat,           // Hitte waarschuwing
  cold,           // Koude waarschuwing
  storm,          // Storm waarschuwing
  lightning,      // Onweer waarschuwing
}

/// Weather alert severity levels
enum WeatherAlertSeverity {
  low,      // Geel - wees alert
  moderate, // Oranje - wees voorbereid
  high,     // Rood - actie ondernemen
  extreme,  // Paars - zeer gevaarlijk
}