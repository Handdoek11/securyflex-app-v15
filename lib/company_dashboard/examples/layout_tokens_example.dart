import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/utils/company_layout_tokens.dart';

/// Example demonstrating CompanyLayoutTokens usage patterns
/// 
/// This file shows practical examples of how to use CompanyLayoutTokens
/// to create consistent layouts across company dashboard pages.
class CompanyLayoutTokensExample extends StatelessWidget {
  const CompanyLayoutTokensExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
      appBar: AppBar(
        title: const Text('CompanyLayoutTokens Examples'),
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
      ),
      body: ListView(
        children: [
          // Example 1: Standard section with title and action
          _buildExample1(context),
          
          // Example 2: Compact section for dense layouts
          _buildExample2(context),
          
          // Example 3: Content-only section
          _buildExample3(context),
          
          // Example 4: Custom padding and margins
          _buildExample4(context),
          
          // Example 5: Multiple sections with consistent spacing
          _buildExample5(context),
        ],
      ),
    );
  }

  /// Example 1: Standard section with title and action
  Widget _buildExample1(BuildContext context) {
    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Actieve Jobs',
      subtitle: 'Beheer Jobs',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to Jobs Management')),
        );
      },
      content: Column(
        children: [
          _buildJobStatRow(context, 'Openstaande Jobs', '5', Icons.work),
          CompanyLayoutTokens.standardSpacing,
          _buildJobStatRow(context, 'Actieve Sollicitaties', '12', Icons.people),
          CompanyLayoutTokens.standardSpacing,
          _buildJobStatRow(context, 'Voltooid Deze Maand', '8', Icons.check_circle),
        ],
      ),
    );
  }

  /// Example 2: Compact section for dense layouts
  Widget _buildExample2(BuildContext context) {
    return CompanyLayoutTokens.buildCompactSection(
      context: context,
      title: 'Quick Stats',
      subtitle: 'Vandaag',
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickStat(context, '€1,250', 'Omzet'),
          _buildQuickStat(context, '3', 'Nieuwe'),
          _buildQuickStat(context, '15', 'Actief'),
        ],
      ),
    );
  }

  /// Example 3: Content-only section without title
  Widget _buildExample3(BuildContext context) {
    return CompanyLayoutTokens.buildContentSection(
      content: Column(
        children: [
          Text(
            'Content-only Section',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          CompanyLayoutTokens.compactSpacing,
          Text(
            'This section uses buildContentSection() for layouts that don\'t need a title header.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Example 4: Custom padding and margins
  Widget _buildExample4(BuildContext context) {
    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Custom Spacing',
      subtitle: 'Aangepast',
      content: const Text('This section uses custom padding and margins.'),
      cardPadding: EdgeInsets.all(DesignTokens.spacingL), // 24px instead of default 16px
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXL, // 32px horizontal
        vertical: DesignTokens.spacingM,    // 16px vertical
      ),
    );
  }

  /// Example 5: Multiple sections with consistent spacing
  Widget _buildExample5(BuildContext context) {
    return Column(
      children: [
        // Section 1
        CompanyLayoutTokens.buildStandardSection(
          context: context,
          title: 'Sollicitaties',
          subtitle: 'Bekijk Alle',
          content: _buildApplicationsPreview(context),
        ),
        
        // Section 2
        CompanyLayoutTokens.buildStandardSection(
          context: context,
          title: 'Recente Activiteit',
          content: _buildRecentActivity(context),
        ),
        
        // Add spacing at the bottom
        CompanyLayoutTokens.largeSpacing,
      ],
    );
  }

  /// Helper: Build job stat row
  Widget _buildJobStatRow(BuildContext context, String label, String value, IconData icon) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Row(
      children: [
        Icon(
          icon,
          color: companyColors.primary,
          size: DesignTokens.iconSizeM,
        ),
        CompanyLayoutTokens.compactHorizontalSpacing,
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: companyColors.primary,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
      ],
    );
  }

  /// Helper: Build quick stat widget
  Widget _buildQuickStat(BuildContext context, String value, String label) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: companyColors.primary,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: companyColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Helper: Build applications preview
  Widget _buildApplicationsPreview(BuildContext context) {
    return Column(
      children: [
        _buildApplicationItem(context, 'Jan de Vries', 'Beveiliger', '2 uur geleden'),
        CompanyLayoutTokens.compactSpacing,
        _buildApplicationItem(context, 'Maria Janssen', 'Senior Beveiliger', '4 uur geleden'),
        CompanyLayoutTokens.compactSpacing,
        _buildApplicationItem(context, 'Peter van Dam', 'Beveiliger', '1 dag geleden'),
      ],
    );
  }

  /// Helper: Build application item
  Widget _buildApplicationItem(BuildContext context, String name, String role, String time) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: companyColors.primaryContainer,
          child: Text(
            name[0],
            style: TextStyle(
              color: companyColors.onPrimaryContainer,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
        CompanyLayoutTokens.compactHorizontalSpacing,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              Text(
                role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: companyColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: companyColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Helper: Build recent activity
  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      children: [
        _buildActivityItem(context, 'Nieuwe sollicitatie ontvangen', '10 min geleden', Icons.person_add),
        CompanyLayoutTokens.compactSpacing,
        _buildActivityItem(context, 'Job "Nachtdienst Amsterdam" gepubliceerd', '2 uur geleden', Icons.work),
        CompanyLayoutTokens.compactSpacing,
        _buildActivityItem(context, 'Beveiliger Jan de Vries geaccepteerd', '1 dag geleden', Icons.check_circle),
      ],
    );
  }

  /// Helper: Build activity item
  Widget _buildActivityItem(BuildContext context, String activity, String time, IconData icon) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Row(
      children: [
        Icon(
          icon,
          color: companyColors.primary,
          size: DesignTokens.iconSizeS,
        ),
        CompanyLayoutTokens.compactHorizontalSpacing,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: companyColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
