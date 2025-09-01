import 'package:flutter/material.dart';
import '../../../unified_design_tokens.dart';

/// GPS verification status types
enum GPSStatusType {
  verified,
  pending,
  failed,
  disabled,
  mockLocation,
  lowAccuracy,
  excellent,      // New: For very high accuracy
  outOfRange,     // New: For when outside job site
  improving,      // New: For when accuracy is getting better
}

/// GPSStatusIndicator - Visual indicator for GPS verification status
/// 
/// Features:
/// - Real-time GPS accuracy display
/// - Mock location detection warnings
/// - Nederlandse status messages
/// - Animated status changes
/// - Role-based theming
/// - CAO compliance indicators
class GPSStatusIndicator extends StatefulWidget {
  final UserRole userRole;
  final GPSStatusType status;
  final double? accuracy;
  final String? locationName;
  final DateTime? lastUpdate;
  final bool showDetails;
  final bool isAnimated;
  final VoidCallback? onTap;
  final bool isLargeMode;        // New: Large prominent display mode
  final bool showAccuracyMeter;  // New: Visual accuracy meter
  final String? jobSiteName;     // New: Job site context
  final int? satelliteCount;     // New: Satellite count for technical users

  const GPSStatusIndicator({
    super.key,
    required this.userRole,
    required this.status,
    this.accuracy,
    this.locationName,
    this.lastUpdate,
    this.showDetails = true,
    this.isAnimated = true,
    this.onTap,
    this.isLargeMode = false,
    this.showAccuracyMeter = false,
    this.jobSiteName,
    this.satelliteCount,
  });

  @override
  State<GPSStatusIndicator> createState() => _GPSStatusIndicatorState();
}

class _GPSStatusIndicatorState extends State<GPSStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.durationSlow,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAnimated && _shouldAnimate()) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GPSStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.isAnimated && _shouldAnimate()) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _shouldAnimate() {
    return widget.status == GPSStatusType.pending || 
           widget.status == GPSStatusType.lowAccuracy ||
           widget.status == GPSStatusType.improving;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: widget.isLargeMode ? _buildLargeMode() : _buildCompactMode(),
    );
  }

  Widget _buildLargeMode() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withValues(alpha: 0.05),
            _getStatusColor().withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: _getStatusColor(),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isAnimated ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: EdgeInsets.all(DesignTokens.spacingM),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: DesignTokens.colorWhite,
                        size: DesignTokens.iconSizeL,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: _getStatusColor(),
                      ),
                    ),
                    if (widget.jobSiteName != null) ...[
                      const SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        'Werklocatie: ${widget.jobSiteName}',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: _getTextSecondaryColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.accuracy != null)
                _buildEnhancedAccuracyDisplay(),
            ],
          ),
          if (widget.showAccuracyMeter && widget.accuracy != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildAccuracyMeter(),
          ],
          if (widget.satelliteCount != null) ...[
            const SizedBox(height: DesignTokens.spacingS),
            _buildSatelliteInfo(),
          ],
          if (_shouldShowWarning()) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildWarningMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactMode() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: _getStatusColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isAnimated ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: DesignTokens.colorWhite,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
              );
            },
          ),
          if (widget.showDetails) ...[
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                      if (widget.accuracy != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingXS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getAccuracyColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                          ),
                          child: Text(
                            '±${widget.accuracy!.toStringAsFixed(0)}m',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.fontSizeXS,
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: _getAccuracyColor(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.locationName != null) ...[
                    const SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      widget.locationName!,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: _getTextSecondaryColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.lastUpdate != null) ...[
                    const SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      'Laatst bijgewerkt: ${_formatLastUpdate()}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeXS,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: _getTextSecondaryColor(),
                      ),
                    ),
                  ],
                  if (_shouldShowWarning())
                    _buildWarningMessage(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Enhanced accuracy display for large mode
  Widget _buildEnhancedAccuracyDisplay() {
    if (widget.accuracy == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: _getAccuracyColor(),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: _getAccuracyColor().withValues(alpha: 0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '±${widget.accuracy!.toStringAsFixed(0)}m',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.colorWhite,
                ),
              ),
              Text(
                'nauwkeurigheid',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        Text(
          _getAccuracyDescription(),
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeXS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getAccuracyColor(),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Visual accuracy meter widget
  Widget _buildAccuracyMeter() {
    if (widget.accuracy == null) return const SizedBox.shrink();
    
    double accuracyRatio = 1.0 - (widget.accuracy!.clamp(0, 100) / 100);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GPS Signaal Kwaliteit',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getTextSecondaryColor(),
              ),
            ),
            Text(
              _getAccuracyPercentage(),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getAccuracyColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: DesignTokens.colorGray200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: (accuracyRatio * 100).round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - accuracyRatio) * 100).round(),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Satellite information widget
  Widget _buildSatelliteInfo() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.satellite_alt,
            size: DesignTokens.iconSizeS,
            color: _getStatusColor(),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            '${widget.satelliteCount} satellieten verbonden',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    String warningText = '';
    
    switch (widget.status) {
      case GPSStatusType.mockLocation:
        warningText = 'Nep locatie gedetecteerd - Check-in niet mogelijk';
        break;
      case GPSStatusType.lowAccuracy:
        warningText = 'GPS signaal zwak - Wacht voor betere verbinding';
        break;
      case GPSStatusType.failed:
        warningText = 'GPS verificatie mislukt - Probeer opnieuw';
        break;
      case GPSStatusType.disabled:
        warningText = 'GPS is uitgeschakeld - Schakel in voor verificatie';
        break;
      case GPSStatusType.outOfRange:
        warningText = 'Buiten werklocatie bereik - Ga naar de juiste locatie';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: DesignTokens.colorWarning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: DesignTokens.colorWarning,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeXS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowWarning() {
    return widget.status == GPSStatusType.mockLocation ||
           widget.status == GPSStatusType.lowAccuracy ||
           widget.status == GPSStatusType.failed ||
           widget.status == GPSStatusType.disabled;
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case GPSStatusType.verified:
      case GPSStatusType.excellent:
        return DesignTokens.colorSuccess;
      case GPSStatusType.pending:
      case GPSStatusType.improving:
        return DesignTokens.colorInfo;
      case GPSStatusType.failed:
      case GPSStatusType.mockLocation:
      case GPSStatusType.outOfRange:
        return DesignTokens.colorError;
      case GPSStatusType.disabled:
        return DesignTokens.colorGray500;
      case GPSStatusType.lowAccuracy:
        return DesignTokens.colorWarning;
    }
  }

  Color _getAccuracyColor() {
    if (widget.accuracy == null) return DesignTokens.colorGray500;
    
    if (widget.accuracy! <= 10) {
      return DesignTokens.colorSuccess;
    } else if (widget.accuracy! <= 50) {
      return DesignTokens.colorWarning;
    } else {
      return DesignTokens.colorError;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case GPSStatusType.verified:
        return Icons.location_on;
      case GPSStatusType.excellent:
        return Icons.gps_fixed;
      case GPSStatusType.pending:
        return Icons.location_searching;
      case GPSStatusType.improving:
        return Icons.trending_up;
      case GPSStatusType.failed:
        return Icons.location_off;
      case GPSStatusType.mockLocation:
        return Icons.warning;
      case GPSStatusType.outOfRange:
        return Icons.wrong_location;
      case GPSStatusType.disabled:
        return Icons.location_disabled;
      case GPSStatusType.lowAccuracy:
        return Icons.location_searching;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case GPSStatusType.verified:
        return 'GPS Geverifieerd';
      case GPSStatusType.excellent:
        return 'GPS Uitstekend';
      case GPSStatusType.pending:
        return 'GPS Zoeken...';
      case GPSStatusType.improving:
        return 'GPS Verbetert...';
      case GPSStatusType.failed:
        return 'GPS Mislukt';
      case GPSStatusType.mockLocation:
        return 'Nep Locatie';
      case GPSStatusType.outOfRange:
        return 'Buiten Bereik';
      case GPSStatusType.disabled:
        return 'GPS Uitgeschakeld';
      case GPSStatusType.lowAccuracy:
        return 'GPS Signaal Zwak';
    }
  }

  String _formatLastUpdate() {
    if (widget.lastUpdate == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(widget.lastUpdate!);
    
    if (difference.inSeconds < 60) {
      return 'nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else {
      return '${difference.inDays}d geleden';
    }
  }

  String _getAccuracyDescription() {
    if (widget.accuracy == null) return '';
    
    if (widget.accuracy! <= 5) {
      return 'Uitstekende precisie';
    } else if (widget.accuracy! <= 10) {
      return 'Zeer goede precisie';
    } else if (widget.accuracy! <= 20) {
      return 'Goede precisie';
    } else if (widget.accuracy! <= 50) {
      return 'Matige precisie';
    } else {
      return 'Lage precisie';
    }
  }

  String _getAccuracyPercentage() {
    if (widget.accuracy == null) return '0%';
    
    // Convert accuracy to percentage (lower accuracy = higher percentage)
    double percentage = (1.0 - (widget.accuracy!.clamp(0, 100) / 100)) * 100;
    return '${percentage.round()}%';
  }

  Color _getTextSecondaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextSecondary;
      case UserRole.company:
        return DesignTokens.companyTextSecondary;
      case UserRole.admin:
        return DesignTokens.adminTextSecondary;
    }
  }
}

/// User roles for theming
enum UserRole {
  guard,
  company,
  admin,
}

/// Factory methods for common GPS status scenarios
extension GPSStatusFactory on GPSStatusIndicator {
  /// Create indicator for successful GPS verification
  static GPSStatusIndicator verified({
    required UserRole userRole,
    required double accuracy,
    String? locationName,
    String? jobSiteName,
    DateTime? lastUpdate,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.verified,
      accuracy: accuracy,
      locationName: locationName,
      jobSiteName: jobSiteName,
      lastUpdate: lastUpdate,
      onTap: onTap,
    );
  }

  /// Create large prominent indicator for time tracking screen
  static GPSStatusIndicator timeTrackingLarge({
    required UserRole userRole,
    required GPSStatusType status,
    required double accuracy,
    String? jobSiteName,
    int? satelliteCount,
    DateTime? lastUpdate,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: status,
      accuracy: accuracy,
      jobSiteName: jobSiteName,
      satelliteCount: satelliteCount,
      lastUpdate: lastUpdate,
      isLargeMode: true,
      showAccuracyMeter: true,
      onTap: onTap,
    );
  }

  /// Create indicator for excellent GPS quality
  static GPSStatusIndicator excellent({
    required UserRole userRole,
    required double accuracy,
    String? locationName,
    String? jobSiteName,
    int? satelliteCount,
    DateTime? lastUpdate,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.excellent,
      accuracy: accuracy,
      locationName: locationName,
      jobSiteName: jobSiteName,
      satelliteCount: satelliteCount,
      lastUpdate: lastUpdate,
      onTap: onTap,
    );
  }

  /// Create indicator for GPS searching
  static GPSStatusIndicator searching({
    required UserRole userRole,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.pending,
      onTap: onTap,
    );
  }

  /// Create indicator for improving GPS signal
  static GPSStatusIndicator improving({
    required UserRole userRole,
    required double accuracy,
    String? locationName,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.improving,
      accuracy: accuracy,
      locationName: locationName,
      onTap: onTap,
    );
  }

  /// Create indicator for mock location detection
  static GPSStatusIndicator mockDetected({
    required UserRole userRole,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.mockLocation,
      onTap: onTap,
    );
  }

  /// Create indicator for out of range warning
  static GPSStatusIndicator outOfRange({
    required UserRole userRole,
    required double accuracy,
    String? jobSiteName,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.outOfRange,
      accuracy: accuracy,
      jobSiteName: jobSiteName,
      onTap: onTap,
    );
  }

  /// Create indicator for low accuracy warning
  static GPSStatusIndicator lowAccuracy({
    required UserRole userRole,
    required double accuracy,
    String? locationName,
    VoidCallback? onTap,
  }) {
    return GPSStatusIndicator(
      userRole: userRole,
      status: GPSStatusType.lowAccuracy,
      accuracy: accuracy,
      locationName: locationName,
      onTap: onTap,
    );
  }
}