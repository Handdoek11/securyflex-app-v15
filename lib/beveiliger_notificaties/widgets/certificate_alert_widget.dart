import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../../auth/services/certificate_management_service.dart';
import '../models/certificate_alert.dart';

/// Certificate expiration alert widget using UnifiedCard design
/// 
/// Features:
/// - Role-based theming with guard colors
/// - Responsive design with proper spacing
/// - Action buttons for course booking and reminders
/// - Urgency-based visual indicators using existing color system
/// - Dutch localization throughout
/// 
/// Usage in dashboard:
/// ```dart
/// CertificateAlertWidget(
///   alert: certificateAlert,
///   onViewCourses: (courses) => _navigateToTraining(courses),
///   onDismiss: () => _dismissAlert(alert.id),
/// )
/// ```
class CertificateAlertWidget extends StatelessWidget {
  final CertificateAlert alert;
  final VoidCallback? onDismiss;
  final Function(List<RenewalCourse>)? onViewCourses;
  final VoidCallback? onRenewLater;
  final bool isCompact;
  final bool showActions;

  const CertificateAlertWidget({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onViewCourses,
    this.onRenewLater,
    this.isCompact = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard(
      variant: isCompact ? UnifiedCardVariant.compact : UnifiedCardVariant.standard,
      padding: isCompact 
          ? EdgeInsets.all(DesignTokens.spacingS) 
          : EdgeInsets.all(DesignTokens.spacingM),
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alert header with urgency indicator
          _buildAlertHeader(context),
          
          SizedBox(height: DesignTokens.spacingS),
          
          // Certificate details
          _buildCertificateInfo(context),
          
          if (!isCompact && alert.renewalCourses.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingM),
            _buildRenewalCoursesSection(context),
          ],
          
          if (showActions) ...[
            SizedBox(height: DesignTokens.spacingM),
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  /// Build alert header with urgency indicator and certificate type
  Widget _buildAlertHeader(BuildContext context) {
    final alertColor = _getAlertColor();
    
    return Row(
      children: [
        // Urgency indicator
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: alertColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        SizedBox(width: DesignTokens.spacingS),
        
        // Certificate icon
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: alertColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCertificateIcon(),
            color: alertColor,
            size: 24,
          ),
        ),
        
        SizedBox(width: DesignTokens.spacingS),
        
        // Alert title and type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.alertTitle,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.colorGray900,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              Text(
                alert.certificateType.dutchName,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
        ),
        
        // Dismiss button
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: DesignTokens.colorGray400,
              size: 20,
            ),
            constraints: BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  /// Build certificate information section
  Widget _buildCertificateInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: alert.isCritical 
            ? DesignTokens.statusExpired.withValues(alpha: 0.05)
            : DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(8),
        border: alert.isCritical 
            ? Border.all(color: DesignTokens.statusExpired.withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert message
          Text(
            alert.alertMessage,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: alert.isCritical ? DesignTokens.statusExpired : DesignTokens.colorGray700,
              fontWeight: alert.isCritical ? DesignTokens.fontWeightMedium : DesignTokens.fontWeightRegular,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXS),
          
          // Certificate details
          Row(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 16,
                color: DesignTokens.colorGray500,
              ),
              SizedBox(width: 4),
              Text(
                'Nr: ${alert.certificateNumber}',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: DesignTokens.colorGray500,
              ),
              SizedBox(width: 4),
              Text(
                alert.formattedExpiryDate,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
          
          // Time until expiry with colored indicator
          SizedBox(height: DesignTokens.spacingXS),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: alert.isExpired 
                      ? DesignTokens.statusExpired
                      : alert.isCritical 
                          ? DesignTokens.statusPending
                          : DesignTokens.statusConfirmed,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                alert.timeUntilExpiryText,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: alert.isExpired 
                      ? DesignTokens.statusExpired
                      : alert.isCritical 
                          ? DesignTokens.statusPending
                          : DesignTokens.statusConfirmed,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build renewal courses section
  Widget _buildRenewalCoursesSection(BuildContext context) {
    if (alert.renewalCourses.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 20,
              color: DesignTokens.guardPrimary,
            ),
            SizedBox(width: 8),
            Text(
              'Verlengingscursussen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorGray800,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Course recommendations
        ...alert.renewalCourses.take(2).map((course) => _buildCourseItem(context, course)),
        
        if (alert.renewalCourses.length > 2)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '+${alert.renewalCourses.length - 2} meer beschikbaar',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.guardPrimary,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
      ],
    );
  }

  /// Build individual course item
  Widget _buildCourseItem(BuildContext context, RenewalCourse course) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Course type indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: course.isOnline 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: course.isOnline 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              course.isOnline ? 'ONLINE' : 'LOCATIE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: DesignTokens.fontWeightMedium,
                color: course.isOnline ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Course details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.colorGray800,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      course.provider,
                      style: TextStyle(
                        fontSize: 10,
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: DesignTokens.colorGray400)),
                    Text(
                      course.formattedDuration,
                      style: TextStyle(
                        fontSize: 10,
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    if (course.isStartingSoon) ...[
                      Text(' • ', style: TextStyle(color: DesignTokens.colorGray400)),
                      Text(
                        'Start binnenkort',
                        style: TextStyle(
                          fontSize: 10,
                          color: DesignTokens.statusPending,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Price
          Text(
            course.formattedPrice,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.guardPrimary,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Primary action - View courses or renew
        if (alert.renewalCourses.isNotEmpty && onViewCourses != null)
          Expanded(
            child: UnifiedButton(
              text: 'Bekijk Cursussen',
              onPressed: () => onViewCourses!(alert.renewalCourses),
              type: UnifiedButtonType.primary,
              size: UnifiedButtonSize.small,
              backgroundColor: DesignTokens.guardPrimary,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
        if (alert.renewalCourses.isNotEmpty && onViewCourses != null && onRenewLater != null)
          SizedBox(width: DesignTokens.spacingS),
        
        // Secondary action - Remind later
        if (onRenewLater != null)
          Expanded(
            child: UnifiedButton(
              text: 'Herinner Later',
              onPressed: onRenewLater,
              type: UnifiedButtonType.secondary,
              size: UnifiedButtonSize.small,
              foregroundColor: DesignTokens.guardPrimary,
              borderColor: DesignTokens.guardPrimary,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }

  /// Get appropriate icon for certificate type
  IconData _getCertificateIcon() {
    switch (alert.certificateType) {
      case CertificateType.wpbr:
        return Icons.security;
      case CertificateType.vca:
        return Icons.construction;
      case CertificateType.bhv:
        return Icons.local_hospital;
      case CertificateType.ehbo:
        return Icons.medical_services;
    }
  }

  /// Safely parse alert color with fallback to guard primary
  Color _getAlertColor() {
    try {
      final hexColor = alert.alertType.colorHex;
      if (hexColor.isNotEmpty && hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      debugPrint('Warning: Failed to parse alert color ${alert.alertType.colorHex}: $e');
    }
    // Fallback to guard primary color
    return DesignTokens.guardPrimary;
  }
}

/// Compact version for dashboard overview
class CompactCertificateAlertWidget extends StatelessWidget {
  final CertificateAlert alert;
  final VoidCallback? onTap;

  const CompactCertificateAlertWidget({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Alert indicator
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: _getAlertColor(),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            
            SizedBox(width: DesignTokens.spacingS),
            
            // Certificate icon
            Icon(
              _getCertificateIcon(),
              size: 20,
              color: DesignTokens.guardPrimary,
            ),
            
            SizedBox(width: DesignTokens.spacingS),
            
            // Certificate info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alert.certificateType.code} verloopt',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.colorGray800,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    alert.timeUntilExpiryText,
                    style: TextStyle(
                      fontSize: 10,
                      color: alert.isCritical ? DesignTokens.statusExpired : DesignTokens.colorGray600,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            Icon(
              Icons.chevron_right,
              size: 16,
              color: DesignTokens.colorGray400,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCertificateIcon() {
    switch (alert.certificateType) {
      case CertificateType.wpbr:
        return Icons.security;
      case CertificateType.vca:
        return Icons.construction;
      case CertificateType.bhv:
        return Icons.local_hospital;
      case CertificateType.ehbo:
        return Icons.medical_services;
    }
  }

  /// Safely parse alert color with fallback to guard primary
  Color _getAlertColor() {
    try {
      final hexColor = alert.alertType.colorHex;
      if (hexColor.isNotEmpty && hexColor.startsWith('#') && hexColor.length == 7) {
        return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      debugPrint('Warning: Failed to parse alert color ${alert.alertType.colorHex}: $e');
    }
    // Fallback to guard primary color
    return DesignTokens.guardPrimary;
  }
}

/// Certificate alerts list widget for notification center
class CertificateAlertsListWidget extends StatelessWidget {
  final List<CertificateAlert> alerts;
  final Function(CertificateAlert)? onAlertTap;
  final Function(List<RenewalCourse>)? onViewCourses;
  final Function(String)? onDismissAlert;

  const CertificateAlertsListWidget({
    super.key,
    required this.alerts,
    this.onAlertTap,
    this.onViewCourses,
    this.onDismissAlert,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return UnifiedCard.standard(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.verified_user,
              size: 48,
              color: DesignTokens.guardPrimary.withValues(alpha: 0.5),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Alle certificaten zijn geldig',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.guardPrimary,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Je hebt momenteel geen certificaten die binnenkort verlopen.',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort alerts by urgency (expired first, then by days until expiry)
    final sortedAlerts = List<CertificateAlert>.from(alerts);
    sortedAlerts.sort((a, b) {
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      return a.daysUntilExpiry.compareTo(b.daysUntilExpiry);
    });

    return Column(
      children: sortedAlerts
          .map((alert) => CertificateAlertWidget(
                alert: alert,
                onViewCourses: onViewCourses,
                onDismiss: onDismissAlert != null ? () => onDismissAlert!(alert.id) : null,
                onRenewLater: () => onAlertTap?.call(alert),
              ))
          .toList(),
    );
  }
}