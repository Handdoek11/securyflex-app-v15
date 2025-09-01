import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/profile_screen.dart';
import '../../beveiliger_notificaties/screens/notification_center_screen.dart';
import '../../beveiliger_notificaties/bloc/notification_center_bloc.dart';
import '../models/weather_data.dart';
import '../../routing/app_routes.dart';

/// Manages all navigation operations for the Beveiliger Dashboard
/// 
/// This controller extracts navigation logic from the main dashboard,
/// handling route transitions and bottom sheet presentations.
class DashboardNavigationController {
  final BuildContext context;
  
  DashboardNavigationController({required this.context});
  
  /// Navigate to profile screen
  void navigateToProfile() {
    // 🚀 CONVERTED: Navigator.push → GoRouter context.push
    context.push(AppRoutes.beveiligerProfile);
  }
  
  /// Navigate to certificates screen
  void navigateToCertificates() {
    // 🚀 CONVERTED: Navigator.push → GoRouter context.push
    context.push(AppRoutes.beveiligerCertificates);
  }
  
  /// Navigate to notification center
  void navigateToNotificationCenter() {
    // 🚀 CONVERTED: Navigator.push → GoRouter context.push
    context.push(AppRoutes.beveiligerNotifications);
  }
  
  /// Navigate to planning/shifts tab
  void navigateToPlanning() {
    context.go(AppRoutes.beveiligerSchedule);
  }
  
  /// Show weather details bottom sheet
  void showWeatherDetails(WeatherData? weather) {
    if (weather == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getWeatherIcon(weather.condition),
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toInt()}°C',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        weather.dutchDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildWeatherDetail('Voelt als', '${weather.feelsLike.toInt()}°C'),
            _buildWeatherDetail('Vochtigheid', '${weather.humidity}%'),
            _buildWeatherDetail('Wind', '${(weather.windSpeed * 3.6).toStringAsFixed(1)} km/h'),
            _buildWeatherDetail('UV Index', weather.uvIndex.toString()),
          ],
        ),
      ),
    );
  }
  
  /// Build weather detail row
  Widget _buildWeatherDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get weather icon based on condition
  IconData _getWeatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.cloudy:
        return Icons.cloud;
      case WeatherCondition.rainy:
        return Icons.grain;
      case WeatherCondition.snowy:
        return Icons.ac_unit;
      case WeatherCondition.windy:
        return Icons.air;
      default:
        return Icons.wb_cloudy;
    }
  }
  
  // 🗑️ REMOVED: Custom transition builder no longer needed with GoRouter
  // GoRouter handles all transitions via CustomTransitionPage configuration
}