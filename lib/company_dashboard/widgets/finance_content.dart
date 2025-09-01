import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';

/// Finance Content Component
/// 
/// Displays financial overview, revenue tracking, billing management,
/// and financial analytics for company operations.
class FinanceContent extends StatelessWidget {
  const FinanceContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Finance header
        _buildFinanceHeader(colorScheme),
        SizedBox(height: DesignTokens.spacingL),
        
        // Finance content
        Container(
          height: 600,
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingXL),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.euro,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: DesignTokens.spacingL),
                    Text(
                      'Financiën Dashboard',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSubtitle,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Beheer inkomsten, uitgaven en genereer\nfinanciële rapporten voor je bedrijf.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Generate report
                          },
                          icon: Icon(Icons.description),
                          label: Text('Rapport Genereren'),
                        ),
                        SizedBox(width: DesignTokens.spacingM),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to full finance view
                          },
                          icon: Icon(Icons.account_balance),
                          label: Text('Financiën Beheer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financiën',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Financieel overzicht en beheer',
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
                // Export financial data
              },
              icon: Icon(Icons.file_download),
              label: Text('Export'),
            ),
            SizedBox(width: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: () {
                // Create invoice
              },
              icon: Icon(Icons.receipt),
              label: Text('Factuur Maken'),
            ),
          ],
        ),
      ],
    );
  }
}