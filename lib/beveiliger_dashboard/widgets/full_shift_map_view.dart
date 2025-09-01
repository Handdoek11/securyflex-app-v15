import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/enhanced_glassmorphism_2025.dart';

/// Full screen map view for shift locations with navigation and location details
class FullShiftMapView extends StatefulWidget {
  final String location;
  final DateTime? startTime;
  final Map<String, dynamic>? shiftData;

  const FullShiftMapView({
    super.key,
    required this.location,
    this.startTime,
    this.shiftData,
  });

  @override
  State<FullShiftMapView> createState() => _FullShiftMapViewState();
}

class _FullShiftMapViewState extends State<FullShiftMapView> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _shiftLocation;
  final Set<Marker> _markers = {};
  bool _isLoadingLocation = true;
  String? _errorMessage;
  
  // Map styling
  static const String _mapStyle = '''[
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    }
  ]''';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      await _getCurrentLocation();
      
      // Geocode shift location
      await _geocodeShiftLocation();
      
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Kan locatie niet laden: ${e.toString()}';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Locatie toegang geweigerd');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Locatie toegang permanent geweigerd');
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Continue without current location
    }
  }

  Future<void> _geocodeShiftLocation() async {
    try {
      // For now, use known Dutch locations or coordinates if provided
      // This would normally use a geocoding service
      _shiftLocation = _getKnownLocationCoordinates(widget.location) ?? 
                      const LatLng(52.3676, 4.9041); // Amsterdam fallback
      
      // Create shift marker
      _markers.add(
        Marker(
          markerId: const MarkerId('shift_location'),
          position: _shiftLocation!,
          infoWindow: InfoWindow(
            title: 'Dienst Locatie',
            snippet: widget.location,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Add current location marker if available
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: const InfoWindow(
              title: 'Mijn Locatie',
              snippet: 'Huidige positie',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting up shift location: $e');
      // Use Amsterdam as ultimate fallback
      _shiftLocation = const LatLng(52.3676, 4.9041);
      _markers.add(
        Marker(
          markerId: const MarkerId('fallback_location'),
          position: _shiftLocation!,
          infoWindow: InfoWindow(
            title: widget.location,
            snippet: 'Geschatte locatie',
          ),
        ),
      );
    }
  }

  /// Get coordinates for known Dutch locations (simplified for now)
  LatLng? _getKnownLocationCoordinates(String location) {
    final locationLower = location.toLowerCase();
    
    // Major Dutch cities coordinates
    if (locationLower.contains('amsterdam')) {
      return const LatLng(52.3676, 4.9041);
    } else if (locationLower.contains('rotterdam')) {
      return const LatLng(51.9244, 4.4777);
    } else if (locationLower.contains('den haag') || locationLower.contains('the hague')) {
      return const LatLng(52.0705, 4.3007);
    } else if (locationLower.contains('utrecht')) {
      return const LatLng(52.0907, 5.1214);
    } else if (locationLower.contains('eindhoven')) {
      return const LatLng(51.4416, 5.4697);
    } else if (locationLower.contains('groningen')) {
      return const LatLng(53.2194, 6.5665);
    } else if (locationLower.contains('tilburg')) {
      return const LatLng(51.5556, 5.0919);
    } else if (locationLower.contains('almere')) {
      return const LatLng(52.3508, 5.2647);
    } else if (locationLower.contains('breda')) {
      return const LatLng(51.5719, 4.7683);
    } else if (locationLower.contains('nijmegen')) {
      return const LatLng(51.8126, 5.8372);
    }
    
    // Return null for unknown locations to use Amsterdam fallback
    return null;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Focus on shift location
    if (_shiftLocation != null) {
      _focusOnShiftLocation();
    }
  }

  void _focusOnShiftLocation() {
    if (_mapController != null && _shiftLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _shiftLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _showBothLocations() {
    if (_mapController != null && _shiftLocation != null && _currentPosition != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          [_shiftLocation!.latitude, _currentPosition!.latitude].reduce((a, b) => a < b ? a : b),
          [_shiftLocation!.longitude, _currentPosition!.longitude].reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          [_shiftLocation!.latitude, _currentPosition!.latitude].reduce((a, b) => a > b ? a : b),
          [_shiftLocation!.longitude, _currentPosition!.longitude].reduce((a, b) => a > b ? a : b),
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  String _calculateDistance() {
    if (_currentPosition != null && _shiftLocation != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _shiftLocation!.latitude,
        _shiftLocation!.longitude,
      );
      
      if (distance < 1000) {
        return '${distance.round()}m afstand';
      } else {
        return '${(distance / 1000).toStringAsFixed(1)}km afstand';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Dienst Locatie',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          if (_currentPosition != null && _shiftLocation != null)
            IconButton(
              onPressed: _showBothLocations,
              icon: Icon(Icons.zoom_out_map),
              tooltip: 'Toon beide locaties',
            ),
          IconButton(
            onPressed: _focusOnShiftLocation,
            icon: Icon(Icons.my_location),
            tooltip: 'Focus op dienst locatie',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          if (_isLoadingLocation)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Locatie wordt geladen...',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: DesignTokens.colorError,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingL),
                  ElevatedButton(
                    onPressed: _initializeMap,
                    child: Text('Opnieuw proberen'),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _shiftLocation ?? const LatLng(52.3676, 4.9041),
                zoom: 15.0,
              ),
              markers: _markers,
              myLocationEnabled: _currentPosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              trafficEnabled: true,
              buildingsEnabled: true,
              style: _mapStyle,
            ),

          // Location info overlay
          if (!_isLoadingLocation && _errorMessage == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer2025(
                enableAdaptiveBlur: true,
                enableGradientShift: false,
                enableDepthLayers: true,
                tintColor: colorScheme.surface,
                margin: EdgeInsets.all(DesignTokens.spacingM),
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            widget.location,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeSubtitle,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: colorScheme.onSurface,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.startTime != null) ...[
                      SizedBox(height: DesignTokens.spacingS),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: DesignTokens.spacingS),
                          Text(
                            'Start: ${DateFormat('EEEE d MMMM, HH:mm', 'nl_NL').format(widget.startTime!)}',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_calculateDistance().isNotEmpty) ...[
                      SizedBox(height: DesignTokens.spacingS),
                      Row(
                        children: [
                          Icon(
                            Icons.directions,
                            color: colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: DesignTokens.spacingS),
                          Text(
                            _calculateDistance(),
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: DesignTokens.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Open in external maps app
                              // This would integrate with maps_launcher package
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Navigatie openen in kaarten app...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(Icons.navigation),
                            label: Text('Navigeren'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                            ),
                          ),
                        ),
                        if (widget.shiftData?['company_phone'] != null) ...[
                          SizedBox(width: DesignTokens.spacingM),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Call company
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bellen naar bedrijf...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(Icons.phone),
                            label: Text('Bellen'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}