import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../beveiliger_profiel/models/profile_completion_data.dart';

/// Dashboard header section for guards dashboard
/// 
/// Features:
/// - Profile completion prompts with progress indicators
/// - Motivational messaging based on completion percentage
/// - Dutch localization for completion states
/// - Guard role theming with gradient backgrounds
/// - Navigation to profile completion screens
/// 
/// Extracted from ModernBeveiligerDashboard to improve maintainability
class DashboardHeaderSection extends StatelessWidget {
  final ProfileCompletionData? profileCompletion;
  final VoidCallback onNavigateToProfile;

  const DashboardHeaderSection({
    super.key,
    required this.profileCompletion,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 DashboardHeaderSection: profileCompletion=${profileCompletion?.completionPercentage ?? "null"}');
    
    // TEMPORARY: Show always for debugging
    // Only show if completion is less than 80%
    // if (profileCompletion == null || profileCompletion!.completionPercentage >= 80) {
    //   debugPrint('🚫 DashboardHeaderSection: Hidden (completion >= 80% or null)');
    //   return const SizedBox.shrink();
    // }
    
    debugPrint('✅ DashboardHeaderSection: Showing (completion < 80%)');

    // Handle null profileCompletion
    if (profileCompletion == null) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: SecuryFlexTheme.getColorScheme(UserRole.guard).surfaceContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Text(
          'Profiel gegevens laden...',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeBody,
            color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
          ),
        ),
      );
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final completionPercentage = profileCompletion!.completionPercentage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
          child: Text(
              'Voltooi je profiel',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Premium glass card with content (optimized intensity)
          PremiumGlassContainer(
            intensity: GlassIntensity.subtle,  // Reduced intensity for better performance
            elevation: GlassElevation.surface,  // Less elevation for subtlety
            tintColor: DesignTokens.guardPrimary,  // Blue color for profile
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            padding: EdgeInsets.all(DesignTokens.spacingL),
            enableTrustBorder: true,
            onTap: onNavigateToProfile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(DesignTokens.spacingXS),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        _getCompletionPromptMessage(profileCompletion!.completionPercentage),
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingM),
                _buildProgressSection(colorScheme, completionPercentage),
                if (profileCompletion!.missingElements.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildMissingElementsHint(colorScheme),
                ],
              ],
            ),
          ),
        ],
      );
  }



  Widget _buildProgressSection(ColorScheme colorScheme, double completionPercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${completionPercentage.round()}% compleet',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: _getCompletionStatusColor(completionPercentage).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                _getCompletionStatusText(completionPercentage),
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _getCompletionStatusColor(completionPercentage),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingElementsHint(ColorScheme colorScheme) {
    return Text(
      'Nog te doen: ${profileCompletion!.missingElements.take(2).map((e) => e.title).join(", ")}',
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeCaption,
        color: colorScheme.onSurfaceVariant,
        fontWeight: DesignTokens.fontWeightRegular,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Helper methods for completion prompts
  String _getCompletionPromptMessage(double percentage) {
    if (percentage < 25) {
      return 'Vul je profiel aan om meer opdrachten te krijgen.';
    } else if (percentage < 50) {
      return 'Je bent goed bezig! Nog even doorgaan.';
    } else if (percentage < 75) {
      return 'Bijna klaar! Nog een paar details.';
    } else {
      return 'Laatste details voor een compleet profiel.';
    }
  }

  String _getCompletionStatusText(double percentage) {
    if (percentage < 25) {
      return 'Net begonnen';
    } else if (percentage < 50) {
      return 'In uitvoering';
    } else if (percentage < 75) {
      return 'Bijna klaar';
    } else {
      return 'Laatste details';
    }
  }

  Color _getCompletionStatusColor(double percentage) {
    if (percentage < 25) {
      return DesignTokens.colorError;
    } else if (percentage < 50) {
      return DesignTokens.statusPending;
    } else if (percentage < 75) {
      return DesignTokens.guardPrimary;
    } else {
      return DesignTokens.statusCompleted;
    }
  }
}