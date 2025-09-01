import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../bloc/dashboard_state.dart';

/// Omzet (Revenue) Content Component
/// 
/// Displays comprehensive revenue analytics, financial metrics,
/// and income streams for the company.
class OmzetContent extends StatelessWidget {
  final DashboardState dashboardState;

  const OmzetContent({
    super.key,
    required this.dashboardState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme),
          SizedBox(height: DesignTokens.spacingXL),
          _buildRevenueOverview(colorScheme, currencyFormat),
          SizedBox(height: DesignTokens.spacingL),
          _buildIncomeStreams(colorScheme, currencyFormat),
          SizedBox(height: DesignTokens.spacingL),
          _buildMonthlyBreakdown(colorScheme, currencyFormat),
          SizedBox(height: DesignTokens.spacingL),
          _buildTopClients(colorScheme, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omzet Overzicht',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Financiële prestaties en inkomstenbronnen',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingM),
              Wrap(
                spacing: DesignTokens.spacingM,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.calendar_today, size: 18),
                    label: Text('December 2024'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.receipt_long, size: 18),
                    label: Text('Facturen'),
                  ),
                ],
              ),
            ],
          );
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Omzet Overzicht',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Financiële prestaties en inkomstenbronnen',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.calendar_today),
                  label: Text('December 2024'),
                ),
                SizedBox(width: DesignTokens.spacingM),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.receipt_long),
                  label: Text('Facturen'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueOverview(ColorScheme colorScheme, NumberFormat currencyFormat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        if (isNarrow) {
          return Column(
            children: [
              _buildRevenueCard(
                'Totale Omzet',
                125400.00,
                'Deze maand',
                Icons.account_balance_wallet,
                colorScheme.primary,
                colorScheme,
                currencyFormat,
                trend: '+12.5%',
              ),
              SizedBox(height: DesignTokens.spacingM),
              _buildRevenueCard(
                'Openstaand',
                28900.00,
                'Te ontvangen',
                Icons.pending_actions,
                DesignTokens.colorWarning,
                colorScheme,
                currencyFormat,
                trend: '8 facturen',
              ),
              SizedBox(height: DesignTokens.spacingM),
              _buildRevenueCard(
                'Betaald',
                96500.00,
                'Deze maand',
                Icons.check_circle,
                DesignTokens.colorSuccess,
                colorScheme,
                currencyFormat,
                trend: '42 facturen',
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                'Totale Omzet',
                125400.00,
                'Deze maand',
                Icons.account_balance_wallet,
                colorScheme.primary,
                colorScheme,
                currencyFormat,
                trend: '+12.5%',
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildRevenueCard(
            'Openstaand',
            18750.00,
            '5 facturen',
            Icons.pending_actions,
            DesignTokens.colorWarning,
            colorScheme,
            currencyFormat,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildRevenueCard(
            'Ontvangen',
            106650.00,
            'Deze maand',
            Icons.check_circle,
            DesignTokens.colorSuccess,
            colorScheme,
            currencyFormat,
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildRevenueCard(
    String title,
    double amount,
    String subtitle,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
    NumberFormat currencyFormat, {
    String? trend,
  }) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
                if (trend != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        color: DesignTokens.colorSuccess,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 24,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
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
    );
  }

  Widget _buildIncomeStreams(ColorScheme colorScheme, NumberFormat currencyFormat) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inkomstenbronnen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            _buildIncomeStreamItem('Beveiligingsdiensten', 85000.00, 0.68, colorScheme, currencyFormat),
            SizedBox(height: DesignTokens.spacingM),
            _buildIncomeStreamItem('Event Beveiliging', 25000.00, 0.20, colorScheme, currencyFormat),
            SizedBox(height: DesignTokens.spacingM),
            _buildIncomeStreamItem('Consultancy', 10000.00, 0.08, colorScheme, currencyFormat),
            SizedBox(height: DesignTokens.spacingM),
            _buildIncomeStreamItem('Training & Certificering', 5400.00, 0.04, colorScheme, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeStreamItem(
    String name,
    double amount,
    double percentage,
    ColorScheme colorScheme,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdown(ColorScheme colorScheme, NumberFormat currencyFormat) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maandelijkse Uitsplitsing',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text('Details'),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Container(
              height: 200,
              child: Center(
                child: Text(
                  'Grafiek wordt geladen...',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClients(ColorScheme colorScheme, NumberFormat currencyFormat) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Klanten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...List.generate(5, (index) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
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
                          'Bedrijf ${String.fromCharCode(65 + index)}',
                          style: TextStyle(
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${10 - index * 2} opdrachten',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeCaption,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(25000 - (index * 3000)),
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}