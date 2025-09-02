import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../services/notification_service.dart';
import 'package:go_router/go_router.dart';

/// Notification settings screen for SecuryFlex Chat
/// Allows users to configure push notification preferences with Dutch localization
class NotificationSettingsScreen extends StatefulWidget {
  final UserRole userRole;
  final AnimationController? animationController;

  const NotificationSettingsScreen({
    super.key,
    required this.userRole,
    this.animationController,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late ScrollController scrollController;
  
  // Notification preferences
  bool _notificationsEnabled = true;
  bool _messageNotifications = true;
  bool _fileNotifications = true;
  bool _systemNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showPreview = true;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _loadSettings();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  /// Load notification settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _messageNotifications = prefs.getBool('message_notifications') ?? true;
        _fileNotifications = prefs.getBool('file_notifications') ?? true;
        _systemNotifications = prefs.getBool('system_notifications') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _showPreview = prefs.getBool('show_preview') ?? true;
        _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
        
        // Load quiet hours
        final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
        final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
        final endHour = prefs.getInt('quiet_hours_end_hour') ?? 8;
        final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
        
        _quietHoursStart = TimeOfDay(hour: startHour, minute: startMinute);
        _quietHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save notification settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('message_notifications', _messageNotifications);
      await prefs.setBool('file_notifications', _fileNotifications);
      await prefs.setBool('system_notifications', _systemNotifications);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setBool('show_preview', _showPreview);
      await prefs.setBool('quiet_hours_enabled', _quietHoursEnabled);
      
      // Save quiet hours
      await prefs.setInt('quiet_hours_start_hour', _quietHoursStart.hour);
      await prefs.setInt('quiet_hours_start_minute', _quietHoursStart.minute);
      await prefs.setInt('quiet_hours_end_hour', _quietHoursEnd.hour);
      await prefs.setInt('quiet_hours_end_minute', _quietHoursEnd.minute);
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Instellingen opgeslagen'),
            backgroundColor: SecuryFlexTheme.getColorScheme(widget.userRole).primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan instellingen'),
            backgroundColor: SecuryFlexTheme.getColorScheme(widget.userRole).error,
          ),
        );
      }
    }
  }

  /// Check notification permissions
  Future<void> _checkPermissions() async {
    final hasPermission = await NotificationService.instance.areNotificationsEnabled();
    
    if (!hasPermission && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Notificaties uitgeschakeld'),
          content: Text(
            'Notificaties zijn uitgeschakeld in de systeeminstellingen. '
            'Ga naar Instellingen > Apps > SecuryFlex > Notificaties om ze in te schakelen.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Select time for quiet hours
  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _quietHoursStart : _quietHoursEnd;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: SecuryFlexTheme.getColorScheme(widget.userRole),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = selectedTime;
        } else {
          _quietHoursEnd = selectedTime;
        }
      });
      await _saveSettings();
    }
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    IconData? icon,
  }) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return UnifiedCard.standard(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(
                icon,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              )
            : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.primary,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return UnifiedCard.standard(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      isClickable: true,
      onTap: onTap,
      child: ListTile(
        leading: icon != null
            ? Icon(
                icon,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeL,
              )
            : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: DesignTokens.fontWeightSemiBold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: SecuryFlexTheme.getColorScheme(widget.userRole).surface,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.simple(
            title: 'Notificatie-instellingen',
            userRole: widget.userRole,
            leading: HeaderElements.backButton(
              onPressed: () => context.pop(),
              userRole: widget.userRole,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: SecuryFlexTheme.getColorScheme(widget.userRole).primary,
          ),
        ),
      );
    }

    return Container(
      color: SecuryFlexTheme.getColorScheme(widget.userRole).surface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.animated(
            title: 'Notificatie-instellingen',
            animationController: widget.animationController!,
            scrollController: scrollController,
            enableScrollAnimation: true,
            userRole: widget.userRole,
            titleAlignment: TextAlign.left,
            leading: HeaderElements.backButton(
              onPressed: () => context.pop(),
              userRole: widget.userRole,
            ),
            actions: [
              HeaderElements.actionButton(
                icon: Icons.help_outline,
                onPressed: _checkPermissions,
                userRole: widget.userRole,
              ),
            ],
          ),
        ),
        body: ListView(
          controller: scrollController,
          children: [
            SizedBox(height: DesignTokens.spacingM),
            
            // General Settings
            _buildSectionHeader('ALGEMEEN'),
            _buildSettingCard(
              title: 'Notificaties',
              subtitle: 'Ontvang push-notificaties voor nieuwe berichten',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
              icon: Icons.notifications,
            ),
            
            // Message Types
            _buildSectionHeader('BERICHTTYPEN'),
            _buildSettingCard(
              title: 'Chatberichten',
              subtitle: 'Notificaties voor nieuwe tekstberichten',
              value: _messageNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _messageNotifications = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.chat_bubble,
            ),
            _buildSettingCard(
              title: 'Bestanden',
              subtitle: 'Notificaties voor gedeelde bestanden en afbeeldingen',
              value: _fileNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _fileNotifications = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.attach_file,
            ),
            _buildSettingCard(
              title: 'Systeemupdates',
              subtitle: 'Belangrijke meldingen over opdrachten en updates',
              value: _systemNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _systemNotifications = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.system_update,
            ),
            
            // Notification Style
            _buildSectionHeader('NOTIFICATIESTIJL'),
            _buildSettingCard(
              title: 'Geluid',
              subtitle: 'Speel geluid af bij nieuwe notificaties',
              value: _soundEnabled && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.volume_up,
            ),
            _buildSettingCard(
              title: 'Trillen',
              subtitle: 'Laat telefoon trillen bij nieuwe notificaties',
              value: _vibrationEnabled && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.vibration,
            ),
            _buildSettingCard(
              title: 'Berichtvoorbeeld',
              subtitle: 'Toon berichtinhoud in notificaties',
              value: _showPreview && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _showPreview = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.preview,
            ),
            
            // Quiet Hours
            _buildSectionHeader('STILLE UREN'),
            _buildSettingCard(
              title: 'Stille uren',
              subtitle: 'Geen notificaties tijdens bepaalde uren',
              value: _quietHoursEnabled && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _quietHoursEnabled = value;
                });
                _saveSettings();
              } : null,
              icon: Icons.bedtime,
            ),
            
            if (_quietHoursEnabled && _notificationsEnabled) ...[
              _buildTimeCard(
                title: 'Begintijd',
                subtitle: 'Wanneer stille uren beginnen',
                time: _quietHoursStart,
                onTap: () => _selectTime(true),
                icon: Icons.schedule,
              ),
              _buildTimeCard(
                title: 'Eindtijd',
                subtitle: 'Wanneer stille uren eindigen',
                time: _quietHoursEnd,
                onTap: () => _selectTime(false),
                icon: Icons.schedule,
              ),
            ],
            
            SizedBox(height: DesignTokens.spacingXL),
          ],
        ),
      ),
    );
  }
}
