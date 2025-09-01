import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/enhanced_glassmorphism_2025.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation_helper.dart';
import '../services/weather_integration_service.dart';
import '../models/weather_data.dart';
import '../../auth/auth_service.dart';
import 'mini_map_preview.dart';
import 'full_shift_map_view.dart';

/// Welkomstwidget voor beveiliger dashboard met persoonlijke groet,
/// status indicators, en slimme contextuele informatie.
/// 
/// Features:
/// - Tijd-gebaseerde Nederlandse groeten
/// - Weer informatie voor buitendiensten
/// - Vandaag verdiensten en uren
/// - Volgende dienst preview
/// - Urgente waarschuwingen
class GuardWelcomeWidget extends StatefulWidget {
  final AnimationController animationController;
  final String? guardName;
  final Map<String, dynamic>? todayEarnings;
  final Map<String, dynamic>? nextShift;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onShiftTap;
  
  const GuardWelcomeWidget({
    super.key,
    required this.animationController,
    this.guardName,
    this.todayEarnings,
    this.nextShift,
    this.onWeatherTap,
    this.onShiftTap,
  });

  @override
  State<GuardWelcomeWidget> createState() => _GuardWelcomeWidgetState();
}

class _GuardWelcomeWidgetState extends State<GuardWelcomeWidget> 
    with TickerProviderStateMixin {
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timeUpdateTimer;
  String _currentGreeting = '';
  DateTime _now = DateTime.now();
  
  // Weather data
  WeatherData? _weatherData;
  final WeatherIntegrationService _weatherService = WeatherIntegrationService();
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateGreeting();
    _startTimeUpdates();
    _loadWeatherData();
  }

  void _initializeAnimations() {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
  }

  void _startTimeUpdates() {
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _updateGreeting();
        });
      }
    });
  }

  void _updateGreeting() {
    final hour = _now.hour;
    final name = widget.guardName ?? AuthService.currentUserName;
    final firstName = name.split(' ').first;
    
    if (hour < 12) {
      _currentGreeting = 'Goedemorgen, $firstName';
    } else if (hour < 18) {
      _currentGreeting = 'Goedemiddag, $firstName';
    } else {
      _currentGreeting = 'Goedenavond, $firstName';
    }
  }

  Future<void> _loadWeatherData() async {
    if (_isLoadingWeather) return;
    
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Amsterdam coordinates as default (can be updated based on shift location)
      final weather = await _weatherService.getCurrentWeather(52.3676, 4.9041);
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading weather: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section outside and above the container
            _buildGreetingSection(colorScheme),
            SizedBox(height: DesignTokens.spacingM),
            // ENHANCED: Wrapped with GlassmorphicContainer2025 for premium feel
            GlassmorphicContainer2025(
                enableAdaptiveBlur: true,
                enableGradientShift: true,
                enableDepthLayers: true,
                tintColor: DesignTokens.guardPrimary,
                padding: EdgeInsets.all(DesignTokens.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickInfoSection(colorScheme),
                if (_weatherData != null) ...[
                  SizedBox(height: DesignTokens.spacingL),
                  _buildWeatherSection(colorScheme),
                ],
                if (widget.nextShift != null && widget.nextShift!['location'] != null) ...[
                  SizedBox(height: DesignTokens.spacingL),
                  _buildMapPreviewSection(colorScheme),
                ],
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentGreeting,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.primary,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    DateFormat('EEEE d MMMM', 'nl_NL').format(_now),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildStatusIndicator(colorScheme),
      ],
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    // Check if guard is on active shift (simplified for now)
    final isOnShift = widget.nextShift?['isActive'] ?? false;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: isOnShift 
            ? DesignTokens.statusConfirmed.withValues(alpha: 0.1)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(
          color: isOnShift
              ? DesignTokens.statusConfirmed.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnShift
                  ? DesignTokens.statusConfirmed
                  : colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            isOnShift ? 'In dienst' : 'Vrij',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isOnShift
                  ? DesignTokens.statusConfirmed
                  : colorScheme.onSurfaceVariant,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoSection(ColorScheme colorScheme) {
    return Row(
      children: [
        // Today's earnings card
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.euro,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      'Vandaag',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  widget.todayEarnings?['amount'] ?? '€0',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.primary,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                if (widget.todayEarnings?['hours'] != null)
                  Text(
                    '${widget.todayEarnings!['hours']} uur',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        // Next shift preview
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: widget.onShiftTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: widget.nextShift != null
                  ? _buildNextShiftContent(colorScheme)
                  : _buildNoShiftContent(colorScheme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextShiftContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work_outline,
              size: 16,
              color: colorScheme.primary,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              'Volgende dienst',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          _formatShiftTime(),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        if (widget.nextShift!['location'] != null)
          Text(
            widget.nextShift!['location'],
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
              fontFamily: DesignTokens.fontFamily,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildNoShiftContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              'Planning',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          'Geen diensten',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurfaceVariant,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        Text(
          'Je bent vrij vandaag',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherSection(ColorScheme colorScheme) {
    if (_weatherData == null) return SizedBox.shrink();

    return InkWell(
      onTap: widget.onWeatherTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            _getWeatherIcon(),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weatherData!.temperature.toInt()}°C - ${_weatherData!.dutchDescription}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  Text(
                    'Voelt als ${_weatherData!.feelsLike.toInt()}°C • Wind: ${(_weatherData!.windSpeed * 3.6).toStringAsFixed(0)} km/h',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getWeatherIcon() {
    IconData icon;
    Color color;
    
    switch (_weatherData?.condition) {
      case WeatherCondition.sunny:
        icon = Icons.wb_sunny;
        color = DesignTokens.colorWarning;
        break;
      case WeatherCondition.cloudy:
        icon = Icons.cloud;
        color = DesignTokens.colorInfo;
        break;
      case WeatherCondition.rainy:
        icon = Icons.grain;
        color = DesignTokens.colorInfo.withValues(alpha: 0.8);
        break;
      case WeatherCondition.snowy:
        icon = Icons.ac_unit;
        color = DesignTokens.colorInfo.withValues(alpha: 0.6);
        break;
      case WeatherCondition.windy:
        icon = Icons.air;
        color = DesignTokens.colorWarning.withValues(alpha: 0.7);
        break;
      default:
        icon = Icons.wb_cloudy;
        color = DesignTokens.colorInfo;
    }
    
    return Icon(icon, size: 32, color: color);
  }

  Widget _buildMapPreviewSection(ColorScheme colorScheme) {
    final shiftLocation = widget.nextShift!['location'];
    final shiftTime = widget.nextShift!['startTime'] as DateTime?;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              'Locatie volgende dienst',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Open full map view
                // TODO: Create proper route for full map view
                // For now, show as dialog
                showDialog(
                  context: context,
                  builder: (_) => _buildFullMapView(shiftLocation, shiftTime),
                );
              },
              icon: Icon(
                Icons.map,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text(
                'Volledig',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.primary,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        SizedBox(
          width: double.infinity,  // Force full width
          child: MiniMapPreview(
            location: shiftLocation,
            address: widget.nextShift?['address'] ?? '',
            latitude: widget.nextShift?['latitude']?.toDouble(),
            longitude: widget.nextShift?['longitude']?.toDouble(),
            onTap: () {
              // Open full map view
              // TODO: Create proper route for full map view
              // For now, show as dialog
              showDialog(
                context: context,
                builder: (_) => _buildFullMapView(shiftLocation, shiftTime),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  String _formatShiftTime() {
    final timeValue = widget.nextShift?['time'];
    if (timeValue == null) return 'Binnenkort';
    
    // Handle both DateTime and String types
    if (timeValue is DateTime) {
      return DateFormat('HH:mm', 'nl_NL').format(timeValue);
    } else if (timeValue is String) {
      return timeValue;
    }
    return 'Binnenkort';
  }

  Widget _buildFullMapView(String location, DateTime? startTime) {
    return FullShiftMapView(
      location: location,
      startTime: startTime,
      shiftData: widget.nextShift,
    );
  }
}