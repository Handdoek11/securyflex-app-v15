import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/unified_dashboard_card.dart';

import '../models/weather_data.dart';

/// Weather Card Widget for outdoor shift conditions
/// 
/// Features:
/// - Current weather conditions with Dutch descriptions
/// - Temperature in Celsius with "feels like" temperature
/// - Wind speed in km/h and direction
/// - Precipitation probability and amount
/// - Dutch weather warnings and recommendations
/// - Clothing and equipment recommendations for outdoor shifts
/// - Weather forecast for next few hours
/// - Safety alerts for extreme weather conditions
class WeatherCardWidget extends StatelessWidget {
  final WeatherData? weather;
  final bool hasOutdoorShifts;

  const WeatherCardWidget({
    super.key,
    this.weather,
    this.hasOutdoorShifts = false,
  });

  @override
  Widget build(BuildContext context) {
    if (weather == null || !hasOutdoorShifts) {
      return const SizedBox.shrink();
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return UnifiedDashboardCard(
      title: 'Weer Vandaag',
      subtitle: 'Voor je buitendiensten',
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weather overview
          _buildCurrentWeather(colorScheme),
          
          const SizedBox(height: DesignTokens.spacingL),
          
          // Weather details
          _buildWeatherDetails(colorScheme),
          
          if (weather!.alerts.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildWeatherWarnings(colorScheme),
          ],
          
          const SizedBox(height: DesignTokens.spacingM),
          
          // Recommendations
          _buildRecommendations(colorScheme),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(ColorScheme colorScheme) {
    return Row(
      children: [
        // Weather icon and temperature
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherIcon(),
                const SizedBox(width: DesignTokens.spacingS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather!.temperature.toInt()}°C',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontSize: DesignTokens.fontSizeDisplayLarge,
                        color: colorScheme.primary,
                        height: DesignTokens.lineHeightTight,
                      ),
                    ),
                    Text(
                      'Voelt als ${weather!.feelsLike.toInt()}°C',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              weather!.dutchDescription,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (weather!.condition) {
      case WeatherCondition.sunny:
        iconData = Icons.wb_sunny;
        iconColor = DesignTokens.colorWarning;
        break;
      case WeatherCondition.partlyCloudy:
        iconData = Icons.wb_cloudy;
        iconColor = DesignTokens.colorInfo;
        break;
      case WeatherCondition.cloudy:
        iconData = Icons.cloud;
        iconColor = DesignTokens.colorGray500;
        break;
      case WeatherCondition.rainy:
        iconData = Icons.grain;
        iconColor = DesignTokens.colorInfo;
        break;
      case WeatherCondition.stormy:
        iconData = Icons.thunderstorm;
        iconColor = DesignTokens.colorError;
        break;
      case WeatherCondition.snowy:
        iconData = Icons.ac_unit;
        iconColor = DesignTokens.colorInfo;
        break;
      case WeatherCondition.foggy:
        iconData = Icons.cloud;
        iconColor = DesignTokens.colorGray400;
        break;
      case WeatherCondition.windy:
        iconData = Icons.air;
        iconColor = DesignTokens.colorInfo;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: DesignTokens.iconSizeXXL,
      ),
    );
  }

  Widget _buildWeatherDetails(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildDetailRow(
          Icons.air,
          'Wind',
          '${weather!.windSpeed.toInt()} km/u ${weather!.windDirection}',
          _getWindColor(),
          colorScheme,
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildDetailRow(
          Icons.water_drop,
          'Neerslag',
          '${weather!.precipitation.toStringAsFixed(1)} mm',
          _getPrecipitationColor(),
          colorScheme,
        ),
        
        if (weather!.precipitation > 0) ...[
          const SizedBox(height: DesignTokens.spacingS),
          _buildDetailRow(
            Icons.umbrella,
            'Verwacht',
            '${weather!.precipitation.toStringAsFixed(1)} mm',
            DesignTokens.colorInfo,
            colorScheme,
          ),
        ],
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildDetailRow(
          Icons.visibility,
          'Zicht',
          '${weather!.visibility.toInt()} km',
          _getVisibilityColor(),
          colorScheme,
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildDetailRow(
          Icons.water,
          'Luchtvochtigheid',
          '${weather!.humidity.toInt()}%',
          _getHumidityColor(),
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color statusColor, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          color: statusColor,
          size: DesignTokens.iconSizeM,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightRegular,
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeBody,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherWarnings(ColorScheme colorScheme) {
    return Material(
      elevation: DesignTokens.elevationLevel3,
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.error.withValues(alpha: DesignTokens.surfaceTintAlphaLevel3),
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Weerswaarschuwing',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorError,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacingS),
          
          ...weather!.alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingXS),
            child: Text(
              '• ${alert.dutchDescription}',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorError,
              ),
            ),
          )),
        ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ColorScheme colorScheme) {
    final recommendations = _getWeatherRecommendations();
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorInfo.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.colorInfo,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Aanbevelingen',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorInfo,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacingS),
          
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingXS),
            child: Text(
              '• $recommendation',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorInfo,
              ),
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getWeatherRecommendations() {
    final recommendations = <String>[];
    
    // Temperature-based recommendations
    if (weather!.temperature < 5) {
      recommendations.add('Draag warme winterkleding en handschoenen');
      recommendations.add('Let op gladheid en ijsvorming');
    } else if (weather!.temperature < 10) {
      recommendations.add('Draag een dikke jas en warme kleding');
      recommendations.add('Zorg voor goede isolatie');
    } else if (weather!.temperature > 25) {
      recommendations.add('Draag lichte, ademende kleding');
      recommendations.add('Zorg voor voldoende water en schaduw');
      if (weather!.temperature > 30) {
        recommendations.add('Let op hittestress en neem regelmatig pauzes');
      }
    }
    
    // Weather condition recommendations
    switch (weather!.condition) {
      case WeatherCondition.rainy:
        recommendations.add('Draag waterdichte kleding en schoenen');
        recommendations.add('Zorg voor droge reservekleding');
        break;
      case WeatherCondition.stormy:
        recommendations.add('Blijf binnen indien mogelijk');
        recommendations.add('Let op vallende takken en objecten');
        break;
      case WeatherCondition.snowy:
        recommendations.add('Draag antislipschoenen');
        recommendations.add('Let extra goed op bij verplaatsingen');
        break;
      case WeatherCondition.foggy:
        recommendations.add('Gebruik extra verlichting');
        recommendations.add('Verhoog je zichtbaarheid met reflecterende kleding');
        break;
      default:
        break;
    }
    
    // Wind-based recommendations
    if (weather!.windSpeed > 50) {
      recommendations.add('Sterke wind - let op vallende objecten');
      recommendations.add('Vermijd werken op hoogte');
    } else if (weather!.windSpeed > 30) {
      recommendations.add('Matige wind - zorg voor windbestendige kleding');
    }
    
    // Default recommendations if none specific
    if (recommendations.isEmpty) {
      recommendations.add('Controleer het weer regelmatig');
      recommendations.add('Zorg voor gepaste kleding voor buitenwerk');
    }
    
    return recommendations;
  }

  Color _getWindColor() {
    if (weather!.windSpeed > 50) {
      return DesignTokens.colorError;
    } else if (weather!.windSpeed > 30) {
      return DesignTokens.colorWarning;
    } else {
      return DesignTokens.colorSuccess;
    }
  }

  Color _getPrecipitationColor() {
    if (weather!.precipitation > 10) {
      return DesignTokens.colorError;
    } else if (weather!.precipitation > 2) {
      return DesignTokens.colorWarning;
    } else {
      return DesignTokens.colorSuccess;
    }
  }

  Color _getVisibilityColor() {
    if (weather!.visibility < 1) {
      return DesignTokens.colorError;
    } else if (weather!.visibility < 5) {
      return DesignTokens.colorWarning;
    } else {
      return DesignTokens.colorSuccess;
    }
  }

  Color _getHumidityColor() {
    if (weather!.humidity > 80 || weather!.humidity < 30) {
      return DesignTokens.colorWarning;
    } else {
      return DesignTokens.colorSuccess;
    }
  }
}