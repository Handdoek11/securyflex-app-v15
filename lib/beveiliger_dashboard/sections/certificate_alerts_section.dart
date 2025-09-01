import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../beveiliger_notificaties/models/certificate_alert.dart';
import '../../beveiliger_notificaties/widgets/certificate_alert_widget.dart';
import '../../auth/services/certificate_management_service.dart';

/// Certificate alerts section for guards dashboard
/// 
/// Features:
/// - Expiring certificate warnings with urgency indicators
/// - Compact display showing max 2 most urgent alerts
/// - Integration with certificate alert service
/// - Actions for course booking and reminder scheduling
/// 
/// Extracted from ModernBeveiligerDashboard to improve maintainability
class CertificateAlertsSection extends StatelessWidget {
  final List<CertificateAlert> certificateAlerts;
  final List<CertificateData> expiringCertificates;
  final bool isLoading;
  final VoidCallback onNavigateToCertificates;
  final Function(String) onDismissAlert;
  final Function(CertificateAlert) onScheduleReminder;

  const CertificateAlertsSection({
    super.key,
    required this.certificateAlerts,
    required this.expiringCertificates,
    required this.isLoading,
    required this.onNavigateToCertificates,
    required this.onDismissAlert,
    required this.onScheduleReminder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    debugPrint('🔍 CertificateAlertsSection: loading=$isLoading, alerts=${certificateAlerts.length}, expiring=${expiringCertificates.length}');
    
    // TEMPORARY: Show always for debugging
    // Don't show section if no certificates or alerts and not loading
    // if (!isLoading && 
    //     expiringCertificates.isEmpty && 
    //     certificateAlerts.isEmpty) {
    //   debugPrint('🚫 CertificateAlertsSection: Hidden (no data and not loading)');
    //   return const SizedBox.shrink();
    // }
    
    debugPrint('✅ CertificateAlertsSection: Showing');

    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title outside the container (same style as "Voltooi je profiel")
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Text(
              'Certificaten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Premium glass card with optimized performance
          PremiumGlassContainer(
            intensity: GlassIntensity.subtle,  // Reduced intensity for better performance
            elevation: GlassElevation.surface,  // Less elevation
            tintColor: DesignTokens.colorInfo,  // Info blue color for certificates
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            padding: EdgeInsets.all(DesignTokens.spacingL),
            enableTrustBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and message row (same layout as profile completion)
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(DesignTokens.spacingXS),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        _getCertificateStatusMessage(),
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,  // Full opacity for better readability
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLoading && (certificateAlerts.isNotEmpty || expiringCertificates.isNotEmpty)) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  if (certificateAlerts.isNotEmpty)
                    _buildCertificateAlertsList()
                  else if (expiringCertificates.isNotEmpty)
                    _buildExpiringCertificatesList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This method is kept for reference but no longer used
  // The header is now integrated in the build method
  String _getCertificateStatusMessage() {
    if (isLoading) {
      return 'Certificaten controleren...';
    } else if (certificateAlerts.isNotEmpty) {
      final count = certificateAlerts.length;
      return count == 1 
        ? '1 certificaat heeft aandacht nodig'
        : '$count certificaten hebben aandacht nodig';
    } else if (expiringCertificates.isNotEmpty) {
      final count = expiringCertificates.length;
      return count == 1
        ? '1 certificaat verloopt binnenkort'
        : '$count certificaten verlopen binnenkort';
    } else {
      return 'Alle certificaten zijn up-to-date';
    }
  }



  Widget _buildCertificateAlertsList() {
    // Show max 2 most urgent alerts on dashboard
    final displayAlerts = certificateAlerts.take(2).toList();
    
    return Column(
      children: displayAlerts.map((alert) {
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: CertificateAlertWidget(
            alert: alert,
            isCompact: true,
            onViewCourses: (courses) => _navigateToTrainingCourses(courses),
            onDismiss: () => onDismissAlert(alert.id),
            onRenewLater: () => onScheduleReminder(alert),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpiringCertificatesList() {
    // Show compact certificate expiry warnings
    final displayCerts = expiringCertificates.take(2).toList();
    
    return Column(
      children: displayCerts.map((cert) {
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: CompactCertificateAlertWidget(
            alert: CertificateAlert.createExpiryWarning(
              cert,
              cert.daysUntilExpiration <= 7 
                  ? AlertType.warning7
                  : cert.daysUntilExpiration <= 30
                      ? AlertType.warning30
                      : AlertType.warning60,
              cert.daysUntilExpiration,
              [], // No courses loaded for compact display
            ),
            onTap: onNavigateToCertificates,
          ),
        );
      }).toList(),
    );
  }

  // This method is no longer used since we handle empty state in the main build

  void _navigateToTrainingCourses(List<RenewalCourse> courses) {
    // This would typically navigate to training courses with pre-selected courses
    // Implementation depends on navigation context from parent widget
  }
}