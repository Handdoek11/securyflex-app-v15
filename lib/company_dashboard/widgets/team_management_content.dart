import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';

/// Team Management Content Component
/// 
/// Displays team management interface with staff overview,
/// performance metrics, and team organization tools.
class TeamManagementContent extends StatelessWidget {
  const TeamManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Team header
        _buildTeamHeader(colorScheme),
        SizedBox(height: DesignTokens.spacingL),
        
        // Main team content
        Container(
          height: 500, // Fixed height for team content
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team overview card
              Expanded(
                flex: 2,
                child: _buildTeamOverviewCard(colorScheme),
              ),
              SizedBox(width: DesignTokens.spacingL),
              
              // Team stats and actions
              Expanded(
                child: Column(
                  children: [
                    _buildTeamStatsCard(colorScheme),
                    SizedBox(height: DesignTokens.spacingL),
                    _buildQuickActionsCard(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Beheer',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Beheer je beveiligingsteam en monitor prestaties',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // Export team data
              },
              icon: Icon(Icons.download),
              label: Text('Team Export'),
            ),
            SizedBox(width: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: () {
                // Add new team member
              },
              icon: Icon(Icons.person_add),
              label: Text('Lid Toevoegen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamOverviewCard(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: colorScheme.primary, size: 28),
                SizedBox(width: DesignTokens.spacingM),
                Text(
                  'Team Overzicht',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingL),
            
            // Team member list
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return _buildTeamMemberItem(index, colorScheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberItem(int index, ColorScheme colorScheme) {
    final names = ['John van der Berg', 'Maria de Vries', 'Ahmed Hassan', 'Lisa Johnson', 'Michael Chen', 'Sarah Weber'];
    final roles = ['Senior Beveiliger', 'Team Lead', 'Beveiliger', 'Beveiliger', 'Senior Beveiliger', 'Team Lead'];
    final statuses = ['Actief', 'Actief', 'Pauze', 'Actief', 'Offline', 'Actief'];
    final statusColors = [DesignTokens.colorSuccess, DesignTokens.colorSuccess, DesignTokens.colorWarning, DesignTokens.colorSuccess, DesignTokens.colorError, DesignTokens.colorSuccess];
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary,
            child: Text(
              names[index].substring(0, 1),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[index],
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Text(
                  roles[index],
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColors[index].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statuses[index],
              style: TextStyle(
                color: statusColors[index],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Statistieken',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            
            _buildStatItem('Totaal Teamleden', '18', Icons.people),
            SizedBox(height: DesignTokens.spacingM),
            _buildStatItem('Actief Nu', '14', Icons.online_prediction, DesignTokens.colorSuccess),
            SizedBox(height: DesignTokens.spacingM),
            _buildStatItem('Gemiddelde Rating', '4.7', Icons.star, DesignTokens.colorWarning),
            SizedBox(height: DesignTokens.spacingM),
            _buildStatItem('Certificeringen', '95%', Icons.verified, DesignTokens.colorInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final statColor = color ?? colorScheme.primary;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: statColor, size: 20),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSubtitle,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snelle Acties',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            
            _buildActionButton('Schema Planning', Icons.calendar_today, () {}),
            SizedBox(height: DesignTokens.spacingS),
            _buildActionButton('Performance Review', Icons.assessment, () {}),
            SizedBox(height: DesignTokens.spacingS),
            _buildActionButton('Training Beheer', Icons.school, () {}),
            SizedBox(height: DesignTokens.spacingS),
            _buildActionButton('Verlof Aanvragen', Icons.time_to_leave, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
      ),
    );
  }
}