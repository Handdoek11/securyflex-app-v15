import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../bloc/dashboard_state.dart';

/// Performance Content Component
/// 
/// Displays performance metrics, KPIs, and efficiency analytics
/// for the company operations.
class PerformanceContent extends StatelessWidget {
  final DashboardState dashboardState;

  const PerformanceContent({
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
          _buildKPIGrid(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildPerformanceChart(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildTeamPerformance(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildEfficiencyMetrics(colorScheme),
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
                    'Performance Dashboard',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'KPIs en prestatie-indicatoren',
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
                    icon: Icon(Icons.tune, size: 18),
                    label: Text('Aanpassen'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text('Vernieuwen'),
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
                    'Performance Dashboard',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'KPIs en prestatie-indicatoren',
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
                  icon: Icon(Icons.tune),
                  label: Text('Aanpassen'),
                ),
                SizedBox(width: DesignTokens.spacingM),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.refresh),
                  label: Text('Vernieuwen'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPIGrid(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on available width
        int crossAxisCount = 3;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: DesignTokens.spacingM,
          crossAxisSpacing: DesignTokens.spacingM,
          childAspectRatio: constraints.maxWidth < 600 ? 2.5 : 1.5,
      children: [
        _buildKPICard(
          'Responstijd',
          '1.8 uur',
          -15.0,
          'Gem. tijd tot eerste reactie',
          Icons.timer,
          DesignTokens.colorSuccess,
          colorScheme,
        ),
        _buildKPICard(
          'Vulgraad',
          '87%',
          5.0,
          'Percentage ingevulde shifts',
          Icons.person_add,
          colorScheme.primary,
          colorScheme,
        ),
        _buildKPICard(
          'Klanttevredenheid',
          '4.6/5',
          2.0,
          'Gemiddelde beoordeling',
          Icons.star,
          DesignTokens.colorWarning,
          colorScheme,
        ),
        _buildKPICard(
          'Retentie',
          '92%',
          8.0,
          'Terugkerende klanten',
          Icons.replay,
          DesignTokens.colorInfo,
          colorScheme,
        ),
        _buildKPICard(
          'Efficiëntie',
          '78%',
          -3.0,
          'Operationele efficiëntie',
          Icons.speed,
          DesignTokens.colorError,
          colorScheme,
        ),
        _buildKPICard(
          'Groei',
          '+24%',
          12.0,
          'Jaar-op-jaar groei',
          Icons.trending_up,
          DesignTokens.colorSuccess,
          colorScheme,
        ),
      ],
        );
      },
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    double change,
    String description,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    final isPositive = change > 0;
    
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacingXS),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Spacer(),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError,
                    ),
                    Text(
                      '${change.abs()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? DesignTokens.colorSuccess : DesignTokens.colorError,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              description,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(ColorScheme colorScheme) {
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
                  'Performance Trends',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    _buildChartLegend('Target', colorScheme.outline),
                    SizedBox(width: DesignTokens.spacingM),
                    _buildChartLegend('Actueel', colorScheme.primary),
                  ],
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingL),
            Container(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Performance grafiek wordt geladen...',
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

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTeamPerformance(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Performance',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...List.generate(4, (index) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
              child: _buildTeamMemberPerformance(
                'Medewerker ${index + 1}',
                85 + index * 3,
                index % 2 == 0,
                colorScheme,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberPerformance(
    String name,
    int score,
    bool isImproving,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            name[0],
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
              Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Icon(
                    isImproving ? Icons.trending_up : Icons.trending_flat,
                    size: 16,
                    color: isImproving ? DesignTokens.colorSuccess : colorScheme.outline,
                  ),
                ],
              ),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: score / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 90 ? DesignTokens.colorSuccess
                    : score >= 70 ? colorScheme.primary
                    : DesignTokens.colorWarning,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Text(
          '$score%',
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyMetrics(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiëntie Metrics',
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
                  DataColumn(label: Text('Proces')),
                  DataColumn(label: Text('Tijd')),
                  DataColumn(label: Text('Target')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text('Sollicitatie verwerking')),
                    DataCell(Text('2.1 dagen')),
                    DataCell(Text('2 dagen')),
                    DataCell(_buildStatusIndicator(false, colorScheme)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Shift invulling')),
                    DataCell(Text('4.5 uur')),
                    DataCell(Text('6 uur')),
                    DataCell(_buildStatusIndicator(true, colorScheme)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Klant response')),
                    DataCell(Text('1.8 uur')),
                    DataCell(Text('2 uur')),
                    DataCell(_buildStatusIndicator(true, colorScheme)),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Facturatie')),
                    DataCell(Text('3 dagen')),
                    DataCell(Text('3 dagen')),
                    DataCell(_buildStatusIndicator(true, colorScheme)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isGood, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isGood ? DesignTokens.colorSuccess : DesignTokens.colorWarning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            size: 14,
            color: isGood ? DesignTokens.colorSuccess : DesignTokens.colorWarning,
          ),
          SizedBox(width: 4),
          Text(
            isGood ? 'Op schema' : 'Aandacht',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isGood ? DesignTokens.colorSuccess : DesignTokens.colorWarning,
            ),
          ),
        ],
      ),
    );
  }
}