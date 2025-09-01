import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/core/unified_components.dart';
import '../models/notification_preferences.dart';

/// Notification preference section widget for categorized notification settings
/// 
/// VERPLICHT gebruik van:
/// - UnifiedCard.standard voor section containers
/// - Switch widgets met role-based theming
/// - DesignTokens voor consistent spacing en typography
/// - Dutch localization for all user-facing text
/// 
/// Features:
/// - Category-based preference management (Jobs, Certificates, Payments, System)
/// - Multiple delivery method toggles (push, email, in-app)
/// - Expandable/collapsible sections for clean UI
/// - Real-time preference updates with validation
/// - Visual feedback for disabled states
class NotificationPreferenceSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final NotificationPreferences preferences;
  final NotificationCategory category;
  final ValueChanged<NotificationPreferences> onPreferenceChanged;
  final UserRole userRole;
  final bool isExpandedInitially;
  final bool showDeliveryMethods;

  const NotificationPreferenceSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
    required this.onEnabledChanged,
    required this.preferences,
    required this.category,
    required this.onPreferenceChanged,
    this.userRole = UserRole.guard,
    this.isExpandedInitially = false,
    this.showDeliveryMethods = true,
  });

  @override
  State<NotificationPreferenceSection> createState() => _NotificationPreferenceSectionState();
}

class _NotificationPreferenceSectionState extends State<NotificationPreferenceSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpandedInitially;
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main category toggle
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isEnabled 
                        ? colorScheme.primary 
                        : colorScheme.outline,
                    size: DesignTokens.iconSizeL,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeSubtitle,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: widget.isEnabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingXS),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: widget.isEnabled,
                    onChanged: widget.preferences.masterNotificationsEnabled 
                        ? widget.onEnabledChanged 
                        : null,
                    activeThumbColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                    inactiveThumbColor: colorScheme.outline,
                    inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: DesignTokens.durationMedium,
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                      size: DesignTokens.iconSizeM,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: widget.isEnabled ? _buildExpandedContent() : null,
          ),
        ],
      ),
          ),
        ),
      );
  }

  Widget _buildExpandedContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
          child: Divider(color: colorScheme.outlineVariant),
        ),
        
        if (widget.showDeliveryMethods) ...[
          // Delivery methods section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
            child: Text(
              'Ontvangen via:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          
          // Push notification toggle
          _buildDeliveryMethodToggle(
            'Push Notificaties',
            'Direct op je apparaat',
            Icons.notifications,
            _getPushValue(),
            (value) => _updatePushPreference(value),
          ),
          
          // Email notification toggle
          _buildDeliveryMethodToggle(
            'E-mail',
            'Via e-mailadres',
            Icons.email,
            _getEmailValue(),
            (value) => _updateEmailPreference(value),
          ),
          
          // In-app notification toggle
          _buildDeliveryMethodToggle(
            'In-app',
            'Binnen de applicatie',
            Icons.app_registration,
            _getInAppValue(),
            (value) => _updateInAppPreference(value),
          ),
          
          SizedBox(height: DesignTokens.spacingM),
        ],
        
        // Category-specific options
        _buildCategorySpecificOptions(),
      ],
    );
  }

  Widget _buildDeliveryMethodToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingXS,
        horizontal: DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingXS),
            decoration: BoxDecoration(
              color: value
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.outline,
              size: DesignTokens.iconSizeS,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: colorScheme.outline,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySpecificOptions() {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        return _buildJobSpecificOptions();
      case NotificationCategory.certificateExpiry:
        return _buildCertificateSpecificOptions();
      case NotificationCategory.paymentUpdate:
        return _buildPaymentSpecificOptions();
      case NotificationCategory.systemAlert:
        return _buildSystemSpecificOptions();
    }
  }

  Widget _buildJobSpecificOptions() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            'Job specifieke opties:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        _buildSpecificToggle(
          'Passende opdrachten',
          'Alleen opdrachten die passen bij je specialisaties',
          Icons.work_outline,
          widget.preferences.jobMatchNotifications,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(jobMatchNotifications: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Shift herinneringen',
          'Herinneringen voor bevestigde shifts',
          Icons.schedule,
          widget.preferences.shiftReminders,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(shiftReminders: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Spoedopdrachten',
          'Dringende opdrachten met hoge prioriteit',
          Icons.priority_high,
          widget.preferences.emergencyJobAlerts,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(emergencyJobAlerts: value),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateSpecificOptions() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            'Certificaat specifieke opties:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        _buildSpecificToggle(
          'WPBR vervaldatum',
          'Waarschuwingen voor WPBR certificaat vervaldatum',
          Icons.card_membership,
          widget.preferences.wpbrExpiryAlerts,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(wpbrExpiryAlerts: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Verlengingscursussen',
          'Informatie over beschikbare verlengingscursussen',
          Icons.school,
          widget.preferences.renewalCourseNotifications,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(renewalCourseNotifications: value),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSpecificOptions() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            'Betaling specifieke opties:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        _buildSpecificToggle(
          'Betalingen voltooid',
          'Bevestiging van voltooide betalingen',
          Icons.check_circle,
          widget.preferences.paymentCompletedNotifications,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(paymentCompletedNotifications: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Facturen',
          'Nieuwe facturen en betalingsverzoeken',
          Icons.receipt,
          widget.preferences.invoiceNotifications,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(invoiceNotifications: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Loonstrook updates',
          'Nieuwe loonstroken en salariswijzigingen',
          Icons.account_balance_wallet,
          widget.preferences.payrollUpdates,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(payrollUpdates: value),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSpecificOptions() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
          child: Text(
            'Systeem specifieke opties:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        _buildSpecificToggle(
          'Beveiligingsmeldingen',
          'Belangrijke beveiligingswaarschuwingen',
          Icons.security,
          widget.preferences.securityAlerts,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(securityAlerts: value),
          ),
        ),
        
        _buildSpecificToggle(
          'Onderhoud meldingen',
          'Geplande onderhouds- en serviceperiodes',
          Icons.build,
          widget.preferences.maintenanceNotifications,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(maintenanceNotifications: value),
          ),
        ),
        
        _buildSpecificToggle(
          'App updates',
          'Nieuwe app-versies en functies',
          Icons.system_update,
          widget.preferences.appUpdates,
          (value) => widget.onPreferenceChanged(
            widget.preferences.copyWith(appUpdates: value),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingXS,
        horizontal: DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value 
                ? colorScheme.primary 
                : colorScheme.outline,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: colorScheme.outline,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  // Helper methods to get current preference values based on category
  bool _getPushValue() {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        return widget.preferences.jobAlertsPush;
      case NotificationCategory.certificateExpiry:
        return widget.preferences.certificateAlertsPush;
      case NotificationCategory.paymentUpdate:
        return widget.preferences.paymentAlertsPush;
      case NotificationCategory.systemAlert:
        return widget.preferences.systemAlertsPush;
    }
  }

  bool _getEmailValue() {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        return widget.preferences.jobAlertsEmail;
      case NotificationCategory.certificateExpiry:
        return widget.preferences.certificateAlertsEmail;
      case NotificationCategory.paymentUpdate:
        return widget.preferences.paymentAlertsEmail;
      case NotificationCategory.systemAlert:
        return widget.preferences.systemAlertsEmail;
    }
  }

  bool _getInAppValue() {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        return widget.preferences.jobAlertsInApp;
      case NotificationCategory.certificateExpiry:
        return widget.preferences.certificateAlertsInApp;
      case NotificationCategory.paymentUpdate:
        return widget.preferences.paymentAlertsInApp;
      case NotificationCategory.systemAlert:
        return widget.preferences.systemAlertsInApp;
    }
  }

  // Helper methods to update preference values based on category
  void _updatePushPreference(bool value) {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        widget.onPreferenceChanged(widget.preferences.copyWith(jobAlertsPush: value));
        break;
      case NotificationCategory.certificateExpiry:
        widget.onPreferenceChanged(widget.preferences.copyWith(certificateAlertsPush: value));
        break;
      case NotificationCategory.paymentUpdate:
        widget.onPreferenceChanged(widget.preferences.copyWith(paymentAlertsPush: value));
        break;
      case NotificationCategory.systemAlert:
        widget.onPreferenceChanged(widget.preferences.copyWith(systemAlertsPush: value));
        break;
    }
  }

  void _updateEmailPreference(bool value) {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        widget.onPreferenceChanged(widget.preferences.copyWith(jobAlertsEmail: value));
        break;
      case NotificationCategory.certificateExpiry:
        widget.onPreferenceChanged(widget.preferences.copyWith(certificateAlertsEmail: value));
        break;
      case NotificationCategory.paymentUpdate:
        widget.onPreferenceChanged(widget.preferences.copyWith(paymentAlertsEmail: value));
        break;
      case NotificationCategory.systemAlert:
        widget.onPreferenceChanged(widget.preferences.copyWith(systemAlertsEmail: value));
        break;
    }
  }

  void _updateInAppPreference(bool value) {
    switch (widget.category) {
      case NotificationCategory.jobOpportunity:
        widget.onPreferenceChanged(widget.preferences.copyWith(jobAlertsInApp: value));
        break;
      case NotificationCategory.certificateExpiry:
        widget.onPreferenceChanged(widget.preferences.copyWith(certificateAlertsInApp: value));
        break;
      case NotificationCategory.paymentUpdate:
        widget.onPreferenceChanged(widget.preferences.copyWith(paymentAlertsInApp: value));
        break;
      case NotificationCategory.systemAlert:
        widget.onPreferenceChanged(widget.preferences.copyWith(systemAlertsInApp: value));
        break;
    }
  }
}