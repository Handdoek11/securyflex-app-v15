import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../core/shared_animation_controller.dart';

/// Enhanced Emergency Shift Alert Widget for Dashboard
/// 
/// Features:
/// - Prominent visual alerts for urgent shift coverage needs
/// - Real-time updates with animated indicators
/// - Quick response actions for emergency shifts
/// - Priority-based color coding and urgency levels
/// - Distance-based shift suggestions
/// - One-tap application for emergency coverage
/// - Push notification integration
/// - Salary premium indicators for emergency shifts
class EmergencyShiftAlertWidget extends StatefulWidget {
  final List<EmergencyShift> emergencyShifts;
  final Function(String shiftId)? onApplyToShift;
  final Function(String shiftId)? onViewShiftDetails;
  final VoidCallback? onRefreshShifts;
  final bool isLoading;
  final String? currentLocation;

  const EmergencyShiftAlertWidget({
    super.key,
    required this.emergencyShifts,
    this.onApplyToShift,
    this.onViewShiftDetails,
    this.onRefreshShifts,
    this.isLoading = false,
    this.currentLocation,
  });

  @override
  State<EmergencyShiftAlertWidget> createState() => _EmergencyShiftAlertWidgetState();
}

class _EmergencyShiftAlertWidgetState extends State<EmergencyShiftAlertWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Use SharedAnimationController instance directly
    final subscriberId = '${widget.runtimeType}_$hashCode';
    
    _pulseController = SharedAnimationController.instance.getController(
      'alert_pulse',
      subscriberId,
      this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideController = SharedAnimationController.instance.getController(
      'alert_slide',
      subscriberId,
      this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    if (widget.emergencyShifts.isNotEmpty) {
      _pulseController.repeat(reverse: true);
      _slideController.forward();
    }
    
    debugPrint('🔧 EmergencyShiftAlert: Using shared animation controllers');
  }

  @override
  void didUpdateWidget(EmergencyShiftAlertWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.emergencyShifts.isNotEmpty && oldWidget.emergencyShifts.isEmpty) {
      _pulseController.repeat(reverse: true);
      _slideController.forward();
      
      // Trigger haptic feedback for new emergency
      HapticFeedback.heavyImpact();
    } else if (widget.emergencyShifts.isEmpty && oldWidget.emergencyShifts.isNotEmpty) {
      _pulseController.stop();
      _slideController.reverse();
    }
  }

  @override
  void dispose() {
    // Release shared controllers
    final subscriberId = '${widget.runtimeType}_$hashCode';
    SharedAnimationController.instance.releaseController('alert_pulse', subscriberId);
    SharedAnimationController.instance.releaseController('alert_slide', subscriberId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    if (widget.emergencyShifts.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    if (widget.isLoading) {
      return _buildLoadingState(colorScheme);
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          children: [
            _buildAlertHeader(colorScheme),
            const SizedBox(height: DesignTokens.spacingM),
            ...widget.emergencyShifts.map((shift) => _buildEmergencyShiftCard(shift, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacingM),
      child: PremiumGlassContainer(
        intensity: GlassIntensity.standard,
        elevation: GlassElevation.floating,
        tintColor: DesignTokens.colorInfo,
        enableTrustBorder: true,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.colorInfo),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Text(
              'Zoeken naar spoeddiensten...',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHeader(ColorScheme colorScheme) {
    final urgentCount = widget.emergencyShifts.where((s) => s.urgencyLevel == UrgencyLevel.critical).length;
    final mediumCount = widget.emergencyShifts.where((s) => s.urgencyLevel == UrgencyLevel.high).length;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.colorError,
                  DesignTokens.colorError.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.colorError.withValues(alpha: 0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    PremiumGlassContainer(
                      intensity: GlassIntensity.subtle,
                      elevation: GlassElevation.raised,
                      tintColor: DesignTokens.colorWhite,
                      borderRadius: BorderRadius.circular(50),
                      padding: const EdgeInsets.all(DesignTokens.spacingS),
                      child: Icon(
                        Icons.flash_on,
                        color: DesignTokens.colorWhite,
                        size: DesignTokens.iconSizeL,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPOEDDIENSTEN BESCHIKBAAR',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightBold,
                              fontSize: DesignTokens.fontSizeHeading,
                              color: DesignTokens.colorWhite,
                              letterSpacing: DesignTokens.letterSpacingWide,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacingXS),
                          Text(
                            'Directe inzet vereist • Premium vergoeding',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightMedium,
                              fontSize: DesignTokens.fontSizeBody,
                              color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PremiumGlassContainer(
                      intensity: GlassIntensity.standard,
                      elevation: GlassElevation.raised,
                      tintColor: DesignTokens.colorWhite,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingM,
                        vertical: DesignTokens.spacingS,
                      ),
                      child: Text(
                        '${widget.emergencyShifts.length}',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightBold,
                          fontSize: DesignTokens.fontSizeHeading,
                          color: DesignTokens.colorWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                if (urgentCount > 0 || mediumCount > 0) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  Row(
                    children: [
                      if (urgentCount > 0) ...[
                        _buildUrgencyBadge(
                          count: urgentCount,
                          label: 'KRITIEK',
                          color: DesignTokens.colorWhite,
                          backgroundColor: DesignTokens.colorWhite.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                      ],
                      if (mediumCount > 0) ...[
                        _buildUrgencyBadge(
                          count: mediumCount,
                          label: 'HOOG',
                          color: DesignTokens.colorWhite,
                          backgroundColor: DesignTokens.colorWhite.withValues(alpha: 0.2),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onRefreshShifts,
                        child: Container(
                          padding: const EdgeInsets.all(DesignTokens.spacingS),
                          child: Icon(
                            Icons.refresh,
                            color: DesignTokens.colorWhite.withValues(alpha: 0.8),
                            size: DesignTokens.iconSizeM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrgencyBadge({
    required int count,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return PremiumGlassContainer(
      intensity: GlassIntensity.subtle,
      elevation: GlassElevation.surface,
      tintColor: color,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeCaption,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeCaption,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyShiftCard(EmergencyShift shift, ColorScheme colorScheme) {
    final urgencyColor = _getUrgencyColor(shift.urgencyLevel);
    final distance = _calculateDistance(shift.location);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: PremiumGlassContainer(
        intensity: GlassIntensity.premium,
        elevation: GlassElevation.floating,
        tintColor: urgencyColor,
        enableTrustBorder: true,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header with urgency and time
          PremiumGlassContainer(
            intensity: GlassIntensity.subtle,
            elevation: GlassElevation.surface,
            tintColor: urgencyColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusL),
              topRight: Radius.circular(DesignTokens.radiusL),
            ),
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                PremiumGlassStatusBadge(
                  label: _getUrgencyLabel(shift.urgencyLevel),
                  color: DesignTokens.colorWhite,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    shift.companyName,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTimeRemaining(shift.startsAt),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontSize: DesignTokens.fontSizeBody,
                    color: urgencyColor,
                  ),
                ),
              ],
            ),
          ),

          // Shift details
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: urgencyColor,
                      size: DesignTokens.iconSizeS,
                    ),
                    const SizedBox(width: DesignTokens.spacingXS),
                    Expanded(
                      child: Text(
                        shift.location,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (distance != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.colorInfo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                        ),
                        child: Text(
                          '${distance}km',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightMedium,
                            fontSize: DesignTokens.fontSizeCaption,
                            color: DesignTokens.colorInfo,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: DesignTokens.spacingS),

                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: colorScheme.onSurfaceVariant,
                      size: DesignTokens.iconSizeS,
                    ),
                    const SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      '${_formatTime(shift.startsAt)} - ${_formatTime(shift.endsAt)}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.euro,
                            color: DesignTokens.colorSuccess,
                            size: 14,
                          ),
                          Text(
                            '${shift.hourlyRateWithPremium.toStringAsFixed(0)}/u',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightBold,
                              fontSize: DesignTokens.fontSizeCaption,
                              color: DesignTokens.colorSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (shift.premiumPercentage > 0) ...[
                  const SizedBox(height: DesignTokens.spacingXS),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: DesignTokens.colorSuccess,
                        size: DesignTokens.iconSizeS,
                      ),
                      const SizedBox(width: DesignTokens.spacingXS),
                      Text(
                        '+${shift.premiumPercentage}% spoedhoeslag',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.colorSuccess,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: DesignTokens.spacingM),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onViewShiftDetails?.call(shift.id),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: urgencyColor.withValues(alpha: 0.5)),
                          foregroundColor: urgencyColor,
                          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onApplyToShift?.call(shift.id);
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(urgencyColor),
                          foregroundColor: WidgetStateProperty.all(DesignTokens.colorWhite),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
                          ),
                          elevation: WidgetStateProperty.resolveWith<double>((states) {
                            if (states.contains(WidgetState.pressed)) return 6.0;
                            return 2.0;
                          }),
                          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: DesignTokens.iconSizeS,
                            ),
                            const SizedBox(width: DesignTokens.spacingXS),
                            Text(
                              'Direct Reageren',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
        return DesignTokens.colorError;
      case UrgencyLevel.high:
        return DesignTokens.colorWarning;
      case UrgencyLevel.medium:
        return DesignTokens.colorInfo;
      case UrgencyLevel.low:
        return DesignTokens.colorSuccess;
    }
  }

  String _getUrgencyLabel(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
        return 'KRITIEK';
      case UrgencyLevel.high:
        return 'HOOG';
      case UrgencyLevel.medium:
        return 'MEDIUM';
      case UrgencyLevel.low:
        return 'LAAG';
    }
  }

  String _formatTimeRemaining(DateTime startsAt) {
    final now = DateTime.now();
    final difference = startsAt.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}u';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'NU';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double? _calculateDistance(String shiftLocation) {
    // Mock distance calculation - in real app, use GPS coordinates
    if (widget.currentLocation == null) return null;
    
    // Simple mock calculation
    return (5 + (shiftLocation.length % 20)).toDouble();
  }
}

/// Emergency Shift Data Model
class EmergencyShift {
  final String id;
  final String companyName;
  final String location;
  final DateTime startsAt;
  final DateTime endsAt;
  final double hourlyRateWithPremium;
  final int premiumPercentage;
  final UrgencyLevel urgencyLevel;
  final String? description;

  const EmergencyShift({
    required this.id,
    required this.companyName,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.hourlyRateWithPremium,
    required this.premiumPercentage,
    required this.urgencyLevel,
    this.description,
  });
}

/// Urgency levels for emergency shifts
enum UrgencyLevel {
  low,
  medium,
  high,
  critical,
}