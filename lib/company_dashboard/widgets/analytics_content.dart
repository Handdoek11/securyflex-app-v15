import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../bloc/dashboard_state.dart';

/// Analytics Content Component
/// 
/// Displays comprehensive analytics dashboard with metrics,
/// charts, and data insights for the company.
class AnalyticsContent extends StatelessWidget {
  final DashboardState dashboardState;

  const AnalyticsContent({
    super.key,
    required this.dashboardState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme),
          SizedBox(height: DesignTokens.spacingXL),
          _buildMetricsGrid(colorScheme),
          SizedBox(height: DesignTokens.spacingXL),
          _buildChartSection(colorScheme),
          SizedBox(height: DesignTokens.spacingXL),
          _buildDataTable(colorScheme),
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
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Inzichten en prestatie-indicatoren',
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
                    label: Text('Periode'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.download, size: 18),
                    label: Text('Export'),
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
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Inzichten en prestatie-indicatoren',
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
                  label: Text('Periode'),
                ),
                SizedBox(width: DesignTokens.spacingM),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.download),
                  label: Text('Export'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricsGrid(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on available width
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: DesignTokens.spacingM,
          crossAxisSpacing: DesignTokens.spacingM,
          childAspectRatio: constraints.maxWidth < 600 ? 3.5 : 2.5,
      children: [
        _buildMetricCard(
          'Totale Omzet',
          '€125.4K',
          '+12.5%',
          Icons.euro,
          colorScheme.primary,
          colorScheme,
        ),
        _buildMetricCard(
          'Actieve Jobs',
          '48',
          '+8',
          Icons.work,
          DesignTokens.colorInfo,
          colorScheme,
        ),
        _buildMetricCard(
          'Conversie Rate',
          '34.2%',
          '+2.1%',
          Icons.trending_up,
          DesignTokens.colorSuccess,
          colorScheme,
        ),
        _buildMetricCard(
          'Gem. Response',
          '2.3u',
          '-0.5u',
          Icons.speed,
          DesignTokens.colorWarning,
          colorScheme,
        ),
      ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    final isPositive = change.startsWith('+');
    
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeSubtitle,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          change,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends & Patronen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            Container(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Grafiek wordt geladen...',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recente Activiteit',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Datum')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Waarde')),
                  DataColumn(label: Text('Status')),
                ],
                rows: List.generate(5, (index) => DataRow(
                  cells: [
                    DataCell(Text('${DateTime.now().subtract(Duration(days: index)).day}/12')),
                    DataCell(Text(index % 2 == 0 ? 'Job geplaatst' : 'Sollicitatie')),
                    DataCell(Text(index % 2 == 0 ? '€${1250 + index * 100}' : '${3 + index}')),
                    DataCell(_buildStatusChip(index % 3, colorScheme)),
                  ],
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int statusIndex, ColorScheme colorScheme) {
    final statuses = [
      {'color': DesignTokens.colorSuccess, 'text': 'Voltooid'},
      {'color': DesignTokens.colorWarning, 'text': 'In uitvoering'},
      {'color': DesignTokens.colorInfo, 'text': 'Gepland'},
    ];
    
    final status = statuses[statusIndex];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (status['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status['text'] as String,
        style: TextStyle(
          color: status['color'] as Color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}