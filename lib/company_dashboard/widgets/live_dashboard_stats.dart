import 'dart:async';
import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../services/shared_animation_manager.dart';

/// Live dashboard statistics with real-time updates
class LiveDashboardStats extends StatefulWidget {
  const LiveDashboardStats({super.key});

  @override
  State<LiveDashboardStats> createState() => _LiveDashboardStatsState();
}

class _LiveDashboardStatsState extends State<LiveDashboardStats> 
    with TickerProviderStateMixin, SharedAnimationMixin {
  
  // Animations using SharedAnimationManager
  late Animation<double> _countAnimation;
  late Animation<double> _pulseAnimation;
  
  // Live data
  int _activeGuards = 24;
  int _ongoingShifts = 8;
  double _todayRevenue = 5234.50;
  int _newApplications = 3;
  int _alertCount = 0;
  
  // Data update timer
  Timer? _updateTimer;
  Timer? _pulseTimer;
  

  @override
  void initState() {
    super.initState();
    
    // Initialize animations using SharedAnimationManager
    _countAnimation = animationManager.getAnimation(
      key: 'liveDashboardCount',
      begin: 0.0,
      end: 1.0,
    );
    
    _pulseAnimation = animationManager.getAnimation(
      key: 'liveDashboardPulse',
      begin: 0.7,
      end: 1.0,
    );
    
    // Pulse animation is already created above
    
    // Start pulse animation using SharedAnimationManager
    animationManager.forward();
    
    // Start real-time updates
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    // Simulate real-time data updates every 5 seconds
    _updateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Simulate data changes
          _activeGuards = _activeGuards + (DateTime.now().second % 3 - 1);
          _activeGuards = _activeGuards.clamp(20, 30);
          
          _ongoingShifts = _ongoingShifts + (DateTime.now().second % 2 == 0 ? 1 : -1);
          _ongoingShifts = _ongoingShifts.clamp(5, 12);
          
          _todayRevenue += (DateTime.now().second * 2.5);
          
          if (DateTime.now().second % 10 == 0) {
            _newApplications++;
            _alertCount++;
          }
        });
        
        // Trigger count animation update
        animationManager.reset();
        animationManager.forward();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseTimer?.cancel();
    // SharedAnimationManager handles animation disposal automatically
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLiveHeader(colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildStatsGrid(colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildRecentActivity(colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildQuickInsights(colorScheme),
      ],
    );
  }

  Widget _buildLiveHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          'Live Dashboard',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(width: DesignTokens.spacingS),
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.colorSuccess.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Spacer(),
        if (_alertCount > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.colorError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.colorError.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  size: 14,
                  color: DesignTokens.colorError,
                ),
                SizedBox(width: 4),
                Text(
                  '$_alertCount nieuwe meldingen',
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.colorError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: DesignTokens.spacingM,
      mainAxisSpacing: DesignTokens.spacingM,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard(
          icon: Icons.security,
          label: 'Actieve Guards',
          value: _activeGuards.toString(),
          color: DesignTokens.colorInfo,
          trend: '+2',
          colorScheme: colorScheme,
        ),
        _buildStatCard(
          icon: Icons.access_time,
          label: 'Lopende Shifts',
          value: _ongoingShifts.toString(),
          color: DesignTokens.colorSuccess,
          trend: 'Live',
          colorScheme: colorScheme,
        ),
        _buildStatCard(
          icon: Icons.euro,
          label: "Vandaag's Omzet",
          value: '€${_todayRevenue.toStringAsFixed(2)}',
          color: DesignTokens.colorWarning,
          trend: '+12%',
          colorScheme: colorScheme,
        ),
        _buildStatCard(
          icon: Icons.person_add,
          label: 'Nieuwe Sollicitaties',
          value: _newApplications.toString(),
          color: DesignTokens.colorPrimaryBlue,
          trend: 'Nieuw',
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String trend,
    required ColorScheme colorScheme,
  }) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 0.9 + (_countAnimation.value * 0.1),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(ColorScheme colorScheme) {
    final activities = [
      {'time': '2 min', 'text': 'Jan de Vries heeft ingecheckt', 'type': 'checkin'},
      {'time': '5 min', 'text': 'Nieuwe sollicitatie ontvangen', 'type': 'application'},
      {'time': '12 min', 'text': 'Shift #2451 voltooid', 'type': 'complete'},
      {'time': '18 min', 'text': 'Noodmelding: Centrum locatie', 'type': 'alert'},
    ];

    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recente Activiteit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ...activities.map((activity) => _buildActivityItem(
            activity['time'] as String,
            activity['text'] as String,
            activity['type'] as String,
            colorScheme,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String time, 
    String text, 
    String type,
    ColorScheme colorScheme,
  ) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'checkin':
        icon = Icons.login;
        color = DesignTokens.colorSuccess;
        break;
      case 'application':
        icon = Icons.person_add;
        color = DesignTokens.colorInfo;
        break;
      case 'complete':
        icon = Icons.check_circle;
        color = DesignTokens.colorSuccess;
        break;
      case 'alert':
        icon = Icons.warning;
        color = DesignTokens.colorError;
        break;
      default:
        icon = Icons.info;
        color = colorScheme.onSurfaceVariant;
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.colorPrimaryBlue.withValues(alpha: 0.05),
            DesignTokens.colorPrimaryBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorPrimaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: DesignTokens.colorPrimaryBlue,
            size: 24,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Insight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.colorPrimaryBlue,
                  ),
                ),
                Text(
                  'Response rate is 15% hoger dan vorige week!',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}