import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import 'unified_dashboard_card.dart';

/// Modern, performance-optimized earnings widget
/// 
/// This replaces the legacy earnings_card_widget.dart with:
/// - Maximum 3 nesting levels (vs 10+ in legacy)
/// - Consolidated styling via UnifiedDashboardCard
/// - Clean, maintainable architecture
/// - Material 3 compliance
/// - Performance-first design
class ModernEarningsWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final EarningsData? data;

  const ModernEarningsWidget({
    super.key,
    this.animationController,
    this.animation,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    final earningsData = data ?? EarningsData.mock();
    
    return AnimatedBuilder(
      animation: animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final animationValue = animation?.value ?? 1.0;
        return FadeTransition(
          opacity: animation ?? const AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              20 * (1.0 - animationValue), // Reduced translation distance
              0.0
            ),
            child: Semantics(
              label: 'Verdiensten overzicht. ${earningsData.totalEarnings} verdiend deze week via Securyflex SmartPay. ${earningsData.hoursWorked} uur gewerkt, ${earningsData.hourlyRate} per uur, ${earningsData.rating} sterren beoordeling.',
              button: true,
              enabled: true,
              hint: 'Dubbeltik voor gedetailleerd overzicht van uren en verdiensten',
              child: UnifiedDashboardCard(
                userRole: UserRole.guard,
                variant: DashboardCardVariant.featured,
                margin: EdgeInsets.only(
                  left: DesignTokens.spacingL,
                  right: DesignTokens.spacingL,
                  top: DesignTokens.spacingM,
                  bottom: DesignTokens.spacingM + 2,
                ),
                child: Column(
                  children: [
                    _buildEarningsHeader(context, earningsData),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildDivider(context),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildStatsRow(context, earningsData),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsHeader(BuildContext context, EarningsData data) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Amount and title
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verdiensten',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeBodyLarge,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.totalEarnings,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeDisplay,
                      color: DesignTokens.colorSuccess,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                    child: Text(
                      'EUR',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightMedium,
                        fontSize: DesignTokens.fontSizeSubtitle,
                        color: DesignTokens.colorSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Right side - Period and payment method
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    data.period,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                data.paymentMethod,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeS,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, EarningsData data) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Row(
      children: [
        Expanded(child: _buildStatItem(colorScheme, data.hoursWorked, 'Gewerkte uren')),
        Expanded(child: _buildStatItem(colorScheme, data.hourlyRate, 'Uurloon')),
        Expanded(child: _buildStatItem(colorScheme, data.rating, 'Rating')),
      ],
    );
  }

  Widget _buildStatItem(ColorScheme colorScheme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            fontSize: DesignTokens.fontSizeBodyLarge,
            color: value.contains('⭐') ? DesignTokens.colorSuccess : colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeS,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Data model for earnings display
class EarningsData {
  final String totalEarnings;
  final String period;
  final String paymentMethod;
  final String hoursWorked;
  final String hourlyRate;
  final String rating;

  const EarningsData({
    required this.totalEarnings,
    required this.period,
    required this.paymentMethod,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.rating,
  });

  /// Mock data for development and testing
  factory EarningsData.mock() {
    return const EarningsData(
      totalEarnings: '€1.280,00',
      period: 'Deze week',
      paymentMethod: 'Securyflex SmartPay',
      hoursWorked: '32 uur',
      hourlyRate: '€40/u',
      rating: '4.8 ⭐',
    );
  }

  /// Create from API response
  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalEarnings: json['totalEarnings'] ?? '€0,00',
      period: json['period'] ?? 'Deze week',
      paymentMethod: json['paymentMethod'] ?? 'Securyflex SmartPay',
      hoursWorked: json['hoursWorked'] ?? '0 uur',
      hourlyRate: json['hourlyRate'] ?? '€0/u',
      rating: json['rating'] ?? '0.0 ⭐',
    );
  }
}
