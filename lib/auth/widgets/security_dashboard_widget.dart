import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import '../services/session_security_service.dart';
import '../auth_service.dart';
import '../../routing/app_routes.dart';

/// Security Dashboard Widget for SecuryFlex
/// 
/// Displays comprehensive security information including:
/// - Active sessions
/// - Recent security events
/// - Suspicious activity alerts
/// - Security recommendations
class SecurityDashboardWidget extends StatefulWidget {
  final String userId;
  
  const SecurityDashboardWidget({
    super.key,
    required this.userId,
  });
  
  @override
  State<SecurityDashboardWidget> createState() => _SecurityDashboardWidgetState();
}

class _SecurityDashboardWidgetState extends State<SecurityDashboardWidget> {
  SecurityDashboard? _securityDashboard;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }
  
  Future<void> _loadSecurityData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final dashboard = await SessionSecurityService.getSecurityDashboard(widget.userId);
      setState(() {
        _securityDashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij laden beveiligingsgegevens: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_securityDashboard == null) {
      return _buildEmptyState();
    }
    
    return _buildSecurityDashboard();
  }
  
  Widget _buildLoadingState() {
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Beveiligingsgegevens laden...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return UnifiedCard.standard(
      backgroundColor: DesignTokens.colorError.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: DesignTokens.colorError,
              size: DesignTokens.iconSizeL,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorError,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingM),
            UnifiedButton.secondary(
              text: 'Opnieuw proberen',
              onPressed: _loadSecurityData,
              size: UnifiedButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.security,
              color: DesignTokens.colorGray400,
              size: DesignTokens.iconSizeL,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Geen beveiligingsgegevens beschikbaar',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityDashboard() {
    final dashboard = _securityDashboard!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDashboardHeader(dashboard),
        SizedBox(height: DesignTokens.spacingM),
        
        if (dashboard.suspiciousActivity.isSuspicious)
          _buildSuspiciousActivityAlert(dashboard.suspiciousActivity),
        
        _buildActiveSessionsSection(dashboard.activeSessions),
        SizedBox(height: DesignTokens.spacingM),
        
        _buildRecentEventsSection(dashboard.recentSecurityEvents),
        SizedBox(height: DesignTokens.spacingM),
        
        _buildSecurityActionsSection(dashboard),
      ],
    );
  }
  
  Widget _buildDashboardHeader(SecurityDashboard dashboard) {
    final securityScore = _calculateSecurityScore(dashboard);
    final statusColor = _getSecurityStatusColor(securityScore);
    
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: statusColor,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Beveiligingsstatus',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Spacer(),
                Chip(
                  label: Text(_getSecurityStatusText(securityScore)),
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Actieve sessies',
                    dashboard.activeSessions.length.toString(),
                    Icons.devices,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Beveiligingsscore',
                    '$securityScore/100',
                    Icons.score,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Laatste controle',
                    _formatTime(dashboard.lastSecurityCheck),
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: DesignTokens.colorPrimaryBlue,
          size: DesignTokens.iconSizeS,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.colorGray900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: DesignTokens.colorGray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildSuspiciousActivityAlert(SuspiciousActivityResult suspiciousActivity) {
    final alertColor = suspiciousActivity.riskLevel == 'HIGH' 
        ? DesignTokens.colorError
        : DesignTokens.colorWarning;
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: UnifiedCard.standard(
        backgroundColor: alertColor.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: alertColor,
                    size: DesignTokens.iconSizeM,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Verdachte activiteit gedetecteerd',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: alertColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingS),
              
              ...suspiciousActivity.indicators.map((indicator) => Padding(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: alertColor,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        indicator,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: DesignTokens.colorGray800,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: DesignTokens.spacingM),
              _buildRecommendedAction(suspiciousActivity.recommendedAction),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendedAction(String recommendedAction) {
    switch (recommendedAction) {
      case 'TERMINATE_ALL_SESSIONS':
        return UnifiedButton.primary(
          text: 'Alle sessies beëindigen',
          onPressed: _terminateAllSessions,
          size: UnifiedButtonSize.small,
        );
      case 'REQUIRE_2FA':
        return UnifiedButton.secondary(
          text: 'Twee-factor authenticatie instellen',
          onPressed: _setup2FA,
          size: UnifiedButtonSize.small,
        );
      default:
        return UnifiedButton.text(
          text: 'Beveiligingsinstellingen bekijken',
          onPressed: _openSecuritySettings,
          size: UnifiedButtonSize.small,
        );
    }
  }
  
  Widget _buildActiveSessionsSection(List<UserSession> activeSessions) {
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actieve sessies (${activeSessions.length})',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeHeading,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            
            if (activeSessions.isEmpty)
              Text(
                'Geen actieve sessies gevonden',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorGray600,
                ),
              )
            else
              ...activeSessions.map((session) => _buildSessionItem(session)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionItem(UserSession session) {
    final isCurrentSession = session.sessionId == AuthService.currentUserId; // Simplified check
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: isCurrentSession 
            ? DesignTokens.colorPrimaryBlue.withValues(alpha: 0.1)
            : DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: isCurrentSession 
              ? DesignTokens.colorPrimaryBlue.withValues(alpha: 0.3)
              : DesignTokens.colorGray200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(session.deviceInfo),
            color: isCurrentSession ? DesignTokens.colorPrimaryBlue : DesignTokens.colorGray600,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDeviceDescription(session.deviceInfo),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: isCurrentSession ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
                  ),
                ),
                Text(
                  'Laatste activiteit: ${_formatTime(session.lastActivity)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorGray600,
                  ),
                ),
              ],
            ),
          ),
          
          if (isCurrentSession)
            Chip(
              label: Text('Huidige sessie'),
              backgroundColor: DesignTokens.colorPrimaryBlue.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: DesignTokens.colorPrimaryBlue,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.logout,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeS,
              ),
              onPressed: () => _terminateSession(session.sessionId),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRecentEventsSection(List<SecurityEvent> recentEvents) {
    final displayEvents = recentEvents.take(5).toList(); // Show last 5 events
    
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recente beveiligingsgebeurtenissen',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Spacer(),
                if (recentEvents.length > 5)
                  UnifiedButton.text(
                    text: 'Alles bekijken',
                    onPressed: _showAllEvents,
                    size: UnifiedButtonSize.small,
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            
            if (displayEvents.isEmpty)
              Text(
                'Geen recente gebeurtenissen',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorGray600,
                ),
              )
            else
              ...displayEvents.map((event) => _buildEventItem(event)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventItem(SecurityEvent event) {
    final eventIcon = _getEventIcon(event.eventType);
    final eventColor = _getEventColor(event.eventType);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            eventIcon,
            color: eventColor,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEventDescription(event.eventType),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightRegular,
                  ),
                ),
                Text(
                  _formatDateTime(event.timestamp),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorGray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityActionsSection(SecurityDashboard dashboard) {
    return UnifiedCard.standard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beveiligingsacties',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeHeading,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            
            Row(
              children: [
                Expanded(
                  child: UnifiedButton.secondary(
                    text: 'Alle sessies beëindigen',
                    onPressed: _terminateAllSessions,
                    size: UnifiedButtonSize.small,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: UnifiedButton.text(
                    text: 'Vernieuw gegevens',
                    onPressed: _loadSecurityData,
                    size: UnifiedButtonSize.small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  
  int _calculateSecurityScore(SecurityDashboard dashboard) {
    int score = 100;
    
    // Penalize for suspicious activity
    if (dashboard.suspiciousActivity.isSuspicious) {
      switch (dashboard.suspiciousActivity.riskLevel) {
        case 'HIGH':
          score -= 40;
          break;
        case 'MEDIUM':
          score -= 20;
          break;
        default:
          score -= 10;
      }
    }
    
    // Penalize for too many active sessions
    if (dashboard.activeSessions.length > 3) {
      score -= (dashboard.activeSessions.length - 3) * 5;
    }
    
    // Check for old sessions
    final now = DateTime.now();
    final oldSessions = dashboard.activeSessions
        .where((s) => now.difference(s.lastActivity).inHours > 24)
        .length;
    score -= oldSessions * 10;
    
    return score.clamp(0, 100);
  }
  
  Color _getSecurityStatusColor(int score) {
    if (score >= 80) return DesignTokens.colorSuccess;
    if (score >= 60) return DesignTokens.colorWarning;
    return DesignTokens.colorError;
  }
  
  String _getSecurityStatusText(int score) {
    if (score >= 80) return 'Uitstekend';
    if (score >= 60) return 'Goed';
    if (score >= 40) return 'Matig';
    return 'Zwak';
  }
  
  IconData _getDeviceIcon(Map<String, dynamic> deviceInfo) {
    // Simplified device detection
    return Icons.devices;
  }
  
  String _getDeviceDescription(Map<String, dynamic> deviceInfo) {
    return 'Onbekend apparaat'; // Could be enhanced with actual device detection
  }
  
  IconData _getEventIcon(String eventType) {
    if (eventType.contains('login') || eventType.contains('created')) {
      return Icons.login;
    } else if (eventType.contains('logout') || eventType.contains('terminated')) {
      return Icons.logout;
    } else if (eventType.contains('failed') || eventType.contains('denied')) {
      return Icons.error_outline;
    } else if (eventType.contains('suspicious') || eventType.contains('fraud')) {
      return Icons.warning;
    }
    return Icons.info_outline;
  }
  
  Color _getEventColor(String eventType) {
    if (eventType.contains('failed') || eventType.contains('denied') || 
        eventType.contains('suspicious') || eventType.contains('fraud')) {
      return DesignTokens.colorError;
    } else if (eventType.contains('warning') || eventType.contains('locked')) {
      return DesignTokens.colorWarning;
    } else if (eventType.contains('success') || eventType.contains('created')) {
      return DesignTokens.colorSuccess;
    }
    return DesignTokens.colorGray600;
  }
  
  String _getEventDescription(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'session created':
        return 'Nieuwe sessie aangemaakt';
      case 'session terminated':
        return 'Sessie beëindigd';
      case 'biometric authentication successful':
        return 'Biometrische authenticatie succesvol';
      case 'biometric authentication failed':
        return 'Biometrische authenticatie mislukt';
      case 'sms verification code sent':
        return 'SMS verificatiecode verzonden';
      case 'suspicious activity detected':
        return 'Verdachte activiteit gedetecteerd';
      default:
        return eventType;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else {
      return '${difference.inDays}d geleden';
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Action handlers
  
  Future<void> _terminateSession(String sessionId) async {
    try {
      await SessionSecurityService.terminateSession(
        userId: widget.userId,
        sessionId: sessionId,
        reason: 'user_terminated',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sessie succesvol beëindigd'),
            backgroundColor: DesignTokens.colorSuccess,
          ),
        );
      }
      
      await _loadSecurityData(); // Refresh data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij beëindigen sessie: $e'),
          backgroundColor: DesignTokens.colorError,
        ),
        );
      }
    }
  }
  
  Future<void> _terminateAllSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alle sessies beëindigen'),
        content: Text('Weet u zeker dat u alle actieve sessies wilt beëindigen? U wordt automatisch uitgelogd.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false), // 🚀 CONVERTED: Navigator.pop → context.pop
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => context.pop(true), // 🚀 CONVERTED: Navigator.pop → context.pop
            style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
            child: Text('Beëindigen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await SessionSecurityService.terminateAllSessions(
          widget.userId,
          reason: 'user_security_action',
        );
        
        // Logout user
        await AuthService.logout();
        
        if (mounted) {
          // 🚨 CRITICAL SECURITY: Navigator.pushNamedAndRemoveUntil → context.go (clears stack)
          context.go(AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij beëindigen sessies: $e'),
            backgroundColor: DesignTokens.colorError,
          ),
          );
        }
      }
    }
  }
  
  void _setup2FA() {
    // Navigate to 2FA setup screen
    // 🚀 CONVERTED: Navigator.pushNamed → context.push
    context.push('/auth/2fa-setup');
  }
  
  void _openSecuritySettings() {
    // Navigate to security settings
    // 🚀 CONVERTED: Navigator.pushNamed → context.push
    context.push('/auth/security-settings');
  }
  
  void _showAllEvents() {
    // Navigate to full events list
    // 🚀 CONVERTED: Navigator.pushNamed → context.push
    context.push('/auth/security-events');
  }
}