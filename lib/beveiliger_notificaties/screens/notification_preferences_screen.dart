import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:securyflex_app/company_dashboard/services/analytics_service.dart';
import 'package:securyflex_app/company_dashboard/models/analytics_data_models.dart';
import '../models/notification_preferences.dart';
import '../widgets/notification_preference_section.dart';
import '../services/notification_preferences_service.dart';
import 'package:go_router/go_router.dart';

/// Comprehensive notification preferences screen for SecuryFlex guards
/// 
/// VERPLICHT gebruik van:
/// - UnifiedHeader.simple met UserRole.guard theming
/// - DesignTokens.spacingM, DesignTokens.spacingL voor alle spacing
/// - UnifiedCard.standard voor preference sections
/// - Switch widgets met guard kleuren voor toggles
/// - Existing SettingsBloc integration for preference persistence
/// 
/// Features:
/// - Granular notification preferences per category (Jobs, Certificates, Payments, System)
/// - Multiple delivery methods per category (push, email, in-app)
/// - Quiet hours configuration with time pickers
/// - Real-time preference validation and saving
/// - Analytics tracking for preference changes
/// - Dutch localization throughout
class NotificationPreferencesScreen extends StatefulWidget {
  final AnimationController? animationController;
  
  const NotificationPreferencesScreen({
    super.key,
    this.animationController,
  });

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  late ScrollController _scrollController;
  late NotificationPreferencesService _preferencesService;
  late AnalyticsService _analyticsService;
  
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _preferencesService = NotificationPreferencesService();
    _analyticsService = AnalyticsService.instance;
    _loadPreferences();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load notification preferences from SettingsService
  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final preferences = await _preferencesService.loadPreferences();
      
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
      
      // Track screen view
      await _analyticsService.trackEvent(
        jobId: 'notification_preferences',
        eventType: JobEventType.view,
        userId: 'current_user',
        metadata: {
          'screen': 'notification_preferences',
          'action': 'view',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _preferences = const NotificationPreferences(); // Default fallback
      });
      
      if (mounted) {
        _showErrorSnackBar('Fout bij laden voorkeuren: ${e.toString()}');
      }
    }
  }

  /// Save preferences using existing SettingsBloc
  Future<void> _savePreferences() async {
    if (_preferences == null) return;
    
    try {
      // Validate preferences before saving
      if (!_preferences!.isValid) {
        _showErrorSnackBar('Ongeldige instellingen. Controleer alle velden.');
        return;
      }
      
      await _preferencesService.updatePreferences(_preferences!);
      
      setState(() {
        _hasUnsavedChanges = false;
      });
      
      // Track preference save
      await _analyticsService.trackEvent(
        jobId: 'notification_preferences',
        eventType: JobEventType.completion,
        userId: 'current_user',
        metadata: {
          'screen': 'notification_preferences',
          'action': 'save',
          'master_enabled': _preferences!.masterNotificationsEnabled,
          'jobs_enabled': _preferences!.jobAlertsEnabled,
          'certificates_enabled': _preferences!.certificateAlertsEnabled,
          'payments_enabled': _preferences!.paymentAlertsEnabled,
          'system_enabled': _preferences!.systemAlertsEnabled,
          'quiet_hours_enabled': _preferences!.quietHoursEnabled,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voorkeuren opgeslagen'),
            backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      _showErrorSnackBar('Fout bij opslaan: ${e.toString()}');
    }
  }

  /// Update specific preference and mark as changed
  void _updatePreference(NotificationPreferences updatedPreferences) {
    setState(() {
      _preferences = updatedPreferences;
      _hasUnsavedChanges = true;
    });
    
    // Auto-save after 2 seconds of inactivity
    _preferencesService.scheduleAutoSave(() => _savePreferences());
  }

  /// Show error message to user
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Sluiten',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Select time for quiet hours
  Future<void> _selectQuietHoursTime(bool isStartTime) async {
    if (_preferences == null) return;
    
    final initialTime = isStartTime 
        ? TimeOfDay(hour: _preferences!.quietHoursStartHour, minute: _preferences!.quietHoursStartMinute)
        : TimeOfDay(hour: _preferences!.quietHoursEndHour, minute: _preferences!.quietHoursEndMinute);
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: SecuryFlexTheme.getColorScheme(UserRole.guard),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      _updatePreference(
        _preferences!.copyWith(
          quietHoursStartHour: isStartTime ? selectedTime.hour : null,
          quietHoursStartMinute: isStartTime ? selectedTime.minute : null,
          quietHoursEndHour: isStartTime ? null : selectedTime.hour,
          quietHoursEndMinute: isStartTime ? null : selectedTime.minute,
        ),
      );
    }
  }

  /// Show unsaved changes dialog
  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Niet-opgeslagen wijzigingen'),
        content: Text('Je hebt niet-opgeslagen wijzigingen. Wil je deze opslaan?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text('Verwerpen'),
          ),
          TextButton(
            onPressed: () async {
              await _savePreferences();
              if (mounted) context.pop(true);
            },
            child: Text('Opslaan'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    if (_isLoading) {
      return SafeArea(
        child: UnifiedBackgroundService.guardMeshGradient(
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
              UnifiedHeader.simple(
                title: 'Notificatie Instellingen',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.center,
                leading: HeaderElements.backButton(
                  onPressed: () => context.pop(),
                  userRole: UserRole.guard,
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                        strokeWidth: 3.0,
                      ),
                      SizedBox(height: DesignTokens.spacingM),
                      Text(
                        'Voorkeuren laden...',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      );
    }

    if (_preferences == null) {
      return SafeArea(
        child: UnifiedBackgroundService.guardMeshGradient(
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
              UnifiedHeader.simple(
                title: 'Notificatie Instellingen',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.center,
                leading: HeaderElements.backButton(
                  onPressed: () => context.pop(),
                  userRole: UserRole.guard,
                ),
              ),
              Expanded(
                child: Center(
                  child: UnifiedCard.standard(
                    margin: EdgeInsets.all(DesignTokens.spacingL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: DesignTokens.iconSizeXL * 2,
                          color: colorScheme.error,
                        ),
                        SizedBox(height: DesignTokens.spacingM),
                        Text(
                          'Fout bij laden',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeTitle,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingS),
                        Text(
                          'Kon voorkeuren niet laden. Probeer opnieuw.',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: DesignTokens.spacingL),
                        UnifiedButton.primary(
                          text: 'Opnieuw proberen',
                          onPressed: _loadPreferences,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: SafeArea(
        child: UnifiedBackgroundService.guardMeshGradient(
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
              UnifiedHeader.simple(
                title: 'Notificatie Instellingen',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.center,
                leading: HeaderElements.backButton(
                  onPressed: () async {
                    final shouldPop = await _showUnsavedChangesDialog();
                    if (shouldPop && mounted) {
                      context.pop();
                    }
                  },
                  userRole: UserRole.guard,
                ),
            actions: [
              if (_hasUnsavedChanges)
                HeaderElements.actionButton(
                  icon: Icons.save,
                  onPressed: _savePreferences,
                  userRole: UserRole.guard,
                ),
                HeaderElements.actionButton(
                  icon: Icons.help_outline,
                  onPressed: () => _showHelpDialog(),
                  userRole: UserRole.guard,
                ),
              ],
            ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPreferences,
                  color: colorScheme.primary,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(DesignTokens.spacingM),
                    children: [
                      // Master toggle section
                      _buildMasterToggleSection(),
              
              SizedBox(height: DesignTokens.spacingL),
              
              // Job notifications section
              NotificationPreferenceSection(
                title: 'Jobs & Opdrachten',
                subtitle: 'Meldingen over nieuwe kansen en werkgelegenheid',
                icon: Icons.work,
                isEnabled: _preferences!.jobAlertsEnabled && _preferences!.masterNotificationsEnabled,
                onEnabledChanged: (enabled) {
                  _updatePreference(_preferences!.copyWith(jobAlertsEnabled: enabled));
                },
                preferences: _preferences!,
                category: NotificationCategory.jobOpportunity,
                onPreferenceChanged: _updatePreference,
                userRole: UserRole.guard,
              ),
              
              SizedBox(height: DesignTokens.spacingM),
              
              // Certificate notifications section
              NotificationPreferenceSection(
                title: 'Certificaten & WPBR',
                subtitle: 'Meldingen over vervaldatums en verlengingen',
                icon: Icons.card_membership,
                isEnabled: _preferences!.certificateAlertsEnabled && _preferences!.masterNotificationsEnabled,
                onEnabledChanged: (enabled) {
                  _updatePreference(_preferences!.copyWith(certificateAlertsEnabled: enabled));
                },
                preferences: _preferences!,
                category: NotificationCategory.certificateExpiry,
                onPreferenceChanged: _updatePreference,
                userRole: UserRole.guard,
              ),
              
              SizedBox(height: DesignTokens.spacingM),
              
              // Payment notifications section
              NotificationPreferenceSection(
                title: 'Betalingen & Uitbetalingen',
                subtitle: 'Meldingen over betalingen, facturen en loon',
                icon: Icons.payment,
                isEnabled: _preferences!.paymentAlertsEnabled && _preferences!.masterNotificationsEnabled,
                onEnabledChanged: (enabled) {
                  _updatePreference(_preferences!.copyWith(paymentAlertsEnabled: enabled));
                },
                preferences: _preferences!,
                category: NotificationCategory.paymentUpdate,
                onPreferenceChanged: _updatePreference,
                userRole: UserRole.guard,
              ),
              
              SizedBox(height: DesignTokens.spacingM),
              
              // System notifications section
              NotificationPreferenceSection(
                title: 'Systeem & Beveiliging',
                subtitle: 'Belangrijke systeemmeldingen en updates',
                icon: Icons.security,
                isEnabled: _preferences!.systemAlertsEnabled && _preferences!.masterNotificationsEnabled,
                onEnabledChanged: (enabled) {
                  _updatePreference(_preferences!.copyWith(systemAlertsEnabled: enabled));
                },
                preferences: _preferences!,
                category: NotificationCategory.systemAlert,
                onPreferenceChanged: _updatePreference,
                userRole: UserRole.guard,
              ),
              
              SizedBox(height: DesignTokens.spacingL),
              
              // Quiet hours section
              _buildQuietHoursSection(),
              
              SizedBox(height: DesignTokens.spacingL),
              
              // Notification behavior section
              _buildNotificationBehaviorSection(),
              
              SizedBox(height: DesignTokens.spacingL),
              
              // Advanced settings section
              _buildAdvancedSettingsSection(),
              
              SizedBox(height: DesignTokens.spacingXL),
            ],
          ),
        ),
      ),
      ],
    ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToggleSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.transparent,
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
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alle Notificaties',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSubtitle,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      'Hoofdschakelaar voor alle notificaties',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences!.masterNotificationsEnabled,
                onChanged: (value) {
                  _updatePreference(_preferences!.copyWith(masterNotificationsEnabled: value));
                },
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                inactiveThumbColor: colorScheme.outline,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          
          if (_preferences!.masterNotificationsEnabled) ...[
            SizedBox(height: DesignTokens.spacingM),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      _preferences!.notificationStatusDescription,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.transparent,
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
          Row(
            children: [
              Icon(
                Icons.bedtime,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stille Uren',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSubtitle,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      'Geen notificaties tijdens bepaalde uren',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences!.quietHoursEnabled && _preferences!.masterNotificationsEnabled,
                onChanged: _preferences!.masterNotificationsEnabled ? (value) {
                  _updatePreference(_preferences!.copyWith(quietHoursEnabled: value));
                } : null,
                activeThumbColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                inactiveThumbColor: colorScheme.outline,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          
          if (_preferences!.quietHoursEnabled && _preferences!.masterNotificationsEnabled) ...[
            SizedBox(height: DesignTokens.spacingM),
            Divider(color: colorScheme.outlineVariant),
            SizedBox(height: DesignTokens.spacingM),
            
            // Time selection buttons
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    'Van',
                    TimeOfDay(
                      hour: _preferences!.quietHoursStartHour,
                      minute: _preferences!.quietHoursStartMinute,
                    ),
                    () => _selectQuietHoursTime(true),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: _buildTimeSelector(
                    'Tot',
                    TimeOfDay(
                      hour: _preferences!.quietHoursEndHour,
                      minute: _preferences!.quietHoursEndMinute,
                    ),
                    () => _selectQuietHoursTime(false),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Allow urgent toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Spoedeisende meldingen toestaan',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _preferences!.quietHoursAllowUrgent,
                  onChanged: (value) {
                    _updatePreference(_preferences!.copyWith(quietHoursAllowUrgent: value));
                  },
                  activeThumbColor: colorScheme.primary,
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                  inactiveThumbColor: colorScheme.outline,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            
            if (_preferences!.isQuietHoursActive) ...[
              SizedBox(height: DesignTokens.spacingS),
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bedtime,
                      color: colorScheme.secondary,
                      size: DesignTokens.iconSizeS,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'Stille uren zijn nu actief',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.secondary,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      isClickable: true,
      onTap: onTap,
      userRole: UserRole.guard,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              color: colorScheme.primary,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBehaviorSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.transparent,
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
          Row(
            children: [
              Icon(
                Icons.settings,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Text(
                'Notificatie Gedrag',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          Divider(color: colorScheme.outlineVariant),
          
          _buildBehaviorToggle(
            'Geluid',
            'Speel geluid af bij nieuwe notificaties',
            Icons.volume_up,
            _preferences!.soundEnabled,
            (value) => _updatePreference(_preferences!.copyWith(soundEnabled: value)),
          ),
          
          _buildBehaviorToggle(
            'Trillen',
            'Laat telefoon trillen bij notificaties',
            Icons.vibration,
            _preferences!.vibrationEnabled,
            (value) => _updatePreference(_preferences!.copyWith(vibrationEnabled: value)),
          ),
          
          _buildBehaviorToggle(
            'Berichtvoorbeeld',
            'Toon berichtinhoud in notificaties',
            Icons.preview,
            _preferences!.showPreview,
            (value) => _updatePreference(_preferences!.copyWith(showPreview: value)),
          ),
          
          _buildBehaviorToggle(
            'LED-indicator',
            'Gebruik LED-lampje voor notificaties',
            Icons.lightbulb_outline,
            _preferences!.ledNotifications,
            (value) => _updatePreference(_preferences!.copyWith(ledNotifications: value)),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildBehaviorToggle(
    String title, 
    String subtitle, 
    IconData icon, 
    bool value, 
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary.withValues(alpha: 0.7),
            size: DesignTokens.iconSizeM,
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
            value: value && _preferences!.masterNotificationsEnabled,
            onChanged: _preferences!.masterNotificationsEnabled ? onChanged : null,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: colorScheme.outline,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.transparent,
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
          Row(
            children: [
              Icon(
                Icons.tune,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Text(
                'Geavanceerde Instellingen',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          Divider(color: colorScheme.outlineVariant),
          
          _buildBehaviorToggle(
            'Locatie-gebaseerde meldingen',
            'Alleen meldingen voor jobs in de buurt',
            Icons.location_on,
            _preferences!.locationBasedNotifications,
            (value) => _updatePreference(_preferences!.copyWith(locationBasedNotifications: value)),
          ),
          
          if (_preferences!.locationBasedNotifications) ...[
            SizedBox(height: DesignTokens.spacingS),
            Padding(
              padding: EdgeInsets.only(left: DesignTokens.iconSizeM + DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maximale afstand: ${_preferences!.maxDistanceForJobAlerts.round()} km',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Slider(
                    value: _preferences!.maxDistanceForJobAlerts,
                    min: 5.0,
                    max: 100.0,
                    divisions: 19,
                    label: '${_preferences!.maxDistanceForJobAlerts.round()} km',
                    onChanged: (value) {
                      _updatePreference(_preferences!.copyWith(maxDistanceForJobAlerts: value));
                    },
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ],
          
          _buildBehaviorToggle(
            'Samenvattingsmodus',
            'Bundel niet-urgente meldingen',
            Icons.format_list_bulleted,
            _preferences!.digestMode,
            (value) => _updatePreference(_preferences!.copyWith(digestMode: value)),
          ),
        ],
      ),
        ),
      ),
    );
  }

  /// Show help dialog with notification preferences information
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notificatie Instellingen'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('Jobs & Opdrachten', 
                'Meldingen over nieuwe beschikbare beveiligingsopdrachten, shiftherinnering en spoedopdrachten.'),
              _buildHelpSection('Certificaten & WPBR', 
                'Belangrijke meldingen over WPBR en andere certificaten die bijna verlopen, plus informatie over verlengingscursussen.'),
              _buildHelpSection('Betalingen & Uitbetalingen', 
                'Meldingen over voltooide betalingen, facturen en loonstrookjes.'),
              _buildHelpSection('Systeem & Beveiliging', 
                'Belangrijke beveiligingsmeldingen en app-updates.'),
              _buildHelpSection('Stille Uren', 
                'Configureer tijden waarop je geen meldingen wilt ontvangen, behalve spoedeisende.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Begrepen'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            description,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
        ],
      ),
    );
  }
}