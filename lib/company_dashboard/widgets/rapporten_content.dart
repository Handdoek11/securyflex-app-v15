import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../bloc/dashboard_state.dart';

/// Rapporten (Reports) Content Component
/// 
/// Displays available reports, generates custom reports,
/// and provides export functionality for the company.
class RapportenContent extends StatelessWidget {
  final DashboardState dashboardState;

  const RapportenContent({
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
          _buildQuickReports(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildCustomReportBuilder(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildRecentReports(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildScheduledReports(colorScheme),
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
                    'Rapporten & Exports',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Genereer en download bedrijfsrapporten',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingM),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 18),
                label: Text('Nieuw Rapport'),
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
                    'Rapporten & Exports',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Genereer en download bedrijfsrapporten',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text('Nieuw Rapport'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickReports(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snel Rapporten',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive column count based on available width
            int crossAxisCount = 4;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
            }
            
            return GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: DesignTokens.spacingM,
              crossAxisSpacing: DesignTokens.spacingM,
              childAspectRatio: constraints.maxWidth < 600 ? 1.0 : 1.2,
          children: [
            _buildQuickReportCard(
              'Maandrapport',
              'December 2024',
              Icons.calendar_month,
              DesignTokens.colorInfo,
              colorScheme,
            ),
            _buildQuickReportCard(
              'Omzet Analyse',
              'Q4 2024',
              Icons.euro,
              colorScheme.primary,
              colorScheme,
            ),
            _buildQuickReportCard(
              'Team Prestaties',
              'Deze week',
              Icons.groups,
              DesignTokens.colorSuccess,
              colorScheme,
            ),
            _buildQuickReportCard(
              'Klant Rapport',
              'Top 10',
              Icons.business,
              DesignTokens.colorWarning,
              colorScheme,
            ),
          ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                title,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildCustomReportBuilder(ColorScheme colorScheme) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: colorScheme.primary),
                SizedBox(width: DesignTokens.spacingM),
                Text(
                  'Aangepast Rapport Maken',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildReportOption(
                    'Type',
                    'Financieel',
                    Icons.arrow_drop_down,
                    colorScheme,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: _buildReportOption(
                    'Periode',
                    'December 2024',
                    Icons.calendar_today,
                    colorScheme,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: _buildReportOption(
                    'Format',
                    'PDF',
                    Icons.arrow_drop_down,
                    colorScheme,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingL),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.preview),
                  label: Text('Voorbeeld'),
                ),
                SizedBox(width: DesignTokens.spacingM),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.download),
                  label: Text('Genereren'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReports(ColorScheme colorScheme) {
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
                  'Recente Rapporten',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Alles bekijken'),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            ...List.generate(4, (index) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
              child: _buildReportItem(
                index == 0 ? 'Maandrapport November 2024' :
                index == 1 ? 'Team Performance Q3 2024' :
                index == 2 ? 'Klantanalyse Oktober' : 'Financieel Overzicht 2024',
                index == 0 ? 'PDF • 2.4 MB' :
                index == 1 ? 'Excel • 1.8 MB' :
                index == 2 ? 'PDF • 892 KB' : 'PDF • 3.1 MB',
                DateTime.now().subtract(Duration(days: index * 3)),
                index == 0 ? Icons.picture_as_pdf :
                index == 1 ? Icons.table_chart :
                index == 2 ? Icons.picture_as_pdf : Icons.picture_as_pdf,
                index == 0 ? DesignTokens.colorError :
                index == 1 ? DesignTokens.colorSuccess :
                index == 2 ? DesignTokens.colorError : DesignTokens.colorError,
                colorScheme,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(
    String title,
    String subtitle,
    DateTime date,
    IconData icon,
    Color iconColor,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${date.day}/${date.month}',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.download, size: 18),
                  onPressed: () {},
                  tooltip: 'Download',
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.share, size: 18),
                  onPressed: () {},
                  tooltip: 'Delen',
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduledReports(ColorScheme colorScheme) {
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
                  'Geplande Rapporten',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Toevoegen'),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildScheduledItem(
              'Maandelijks Overzicht',
              'Elke 1e van de maand',
              true,
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildScheduledItem(
              'Wekelijkse Performance',
              'Elke maandag',
              true,
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildScheduledItem(
              'Kwartaal Analyse',
              'Elk kwartaal',
              false,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledItem(
    String title,
    String schedule,
    bool isActive,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: isActive 
          ? colorScheme.primaryContainer.withValues(alpha: 0.1)
          : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: isActive 
            ? colorScheme.primary.withValues(alpha: 0.3)
            : colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  schedule,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) {},
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}