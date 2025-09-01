import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Mini map preview widget for showing location information
/// Used in guard welcome widget to display shift locations
/// Now with real Google Maps integration
class MiniMapPreview extends StatefulWidget {
  final String? location;
  final String? address;
  final VoidCallback? onTap;
  final double? latitude;
  final double? longitude;
  
  const MiniMapPreview({
    super.key,
    this.location,
    this.address,
    this.onTap,
    this.latitude,
    this.longitude,
  });
  
  @override
  State<MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<MiniMapPreview> {
  GoogleMapController? _mapController;
  
  // Default to Amsterdam center if no coordinates provided
  late final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(
      widget.latitude ?? 52.3676, 
      widget.longitude ?? 4.9041
    ),
    zoom: 14.0,
  );

  // SecuryFlex themed map style (blue tones matching the app theme)
  static const String _mapStyle = '''[
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [
        {"color": "#e8f4f8"}
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#2c3e50"}
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [
        {"color": "#ffffff"},
        {"weight": 2}
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#c9e6f2"}
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {"color": "#5b8ba0"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {"color": "#ffffff"}
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#d6e4e8"},
        {"weight": 1}
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {"color": "#f0f8ff"}
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {"color": "#b8d4e3"},
        {"weight": 1}
      ]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [
        {"color": "#dff4f4"}
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {"color": "#c7e9c7"}
      ]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [
        {"color": "#e0f2f7"}
      ]
    }
  ]''';

  Set<Marker> get _markers {
    if (widget.latitude != null && widget.longitude != null) {
      return {
        Marker(
          markerId: const MarkerId('assignment_location'),
          position: LatLng(widget.latitude!, widget.longitude!),
          infoWindow: InfoWindow(
            title: widget.location ?? 'Opdracht Locatie',
            snippet: widget.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue, // SecuryFlex blue theme
          ),
        ),
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: theme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                style: _mapStyle, // Apply custom map style for SecuryFlex theme
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                liteModeEnabled: true, // Lite mode for preview - better performance
                compassEnabled: false,
                tiltGesturesEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
              
              // Location info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildLocationOverlay(context, theme),
              ),
              
              // Tap indicator
              if (widget.onTap != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      size: 20,
                      color: theme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationOverlay(BuildContext context, ColorScheme theme) {
    if (widget.location == null && widget.address == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusM),
          bottomRight: Radius.circular(DesignTokens.radiusM),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            theme.surface.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.location != null)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: theme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.location!,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: theme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (widget.address != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.address!,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeCaption - 1,
                color: theme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

/// Fallback widget for when Google Maps is not available
class MapFallbackWidget extends StatelessWidget {
  final String? location;
  final String? address;
  final ColorScheme theme;

  const MapFallbackWidget({
    super.key,
    this.location,
    this.address,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryContainer.withValues(alpha: 0.3),
            theme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: theme.onPrimaryContainer.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            if (location != null)
              Text(
                location!,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: theme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}