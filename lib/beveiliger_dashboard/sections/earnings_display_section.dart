import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_typography_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../models/enhanced_dashboard_data.dart' as dashboard_models;

/// Earnings display section for guards dashboard
/// 
/// Features:
/// - Today and monthly earnings display
/// - Dutch currency formatting with proper separators
/// - Premium typography and glass system integration
/// - Professional financial data presentation
/// - Responsive layout with trust-building design
/// 
/// Uses PremiumTypography.financialDisplay for earnings and
/// PremiumGlassContainer for professional appearance
class EarningsDisplaySection extends StatelessWidget {
  final dashboard_models.EnhancedEarningsData earnings;

  const EarningsDisplaySection({
    super.key,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 EarningsDisplaySection: today="${earnings.dutchFormattedToday}", month="${earnings.dutchFormattedMonth}"');
    
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    // Defensive programming: check for valid earnings data
    if (earnings.dutchFormattedToday.isEmpty || earnings.dutchFormattedMonth.isEmpty) {
      debugPrint('🚫 EarningsDisplaySection: Hidden (invalid earnings data)');
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title outside the container (same style as Certificaten)
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Text(
              'Verdiensten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          
          // Premium glass card with earnings data
          PremiumGlassContainer(
            intensity: GlassIntensity.standard,
            elevation: GlassElevation.floating,
            tintColor: DesignTokens.colorSuccess,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            padding: EdgeInsets.all(DesignTokens.spacingL),
            enableTrustBorder: true,
            child: Row(
              children: [
                _buildEarningsColumn(
                  context,
                  title: 'Vandaag',
                  amount: earnings.dutchFormattedToday,
                  isToday: true,
                ),
                Container(
                  width: 1,
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildEarningsColumn(
                  context,
                  title: 'Deze maand',
                  amount: earnings.dutchFormattedMonth,
                  isToday: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsColumn(
    BuildContext context, {
    required String title,
    required String amount,
    required bool isToday,
  }) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: PremiumTypography.professionalCaption(
              context,
              role: UserRole.guard,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            amount,
            style: PremiumTypography.financialDisplay(
              context,
              color: isToday ? DesignTokens.colorSuccess : colorScheme.onSurface,
              isLarge: isToday,
            ),
            textAlign: TextAlign.center,
          ),
          if (isToday) ...[
            SizedBox(height: 4),
            Text(
              '${earnings.hoursWorkedToday.toStringAsFixed(1)}u gewerkt',
              style: PremiumTypography.metadata(
                context,
                role: UserRole.guard,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}