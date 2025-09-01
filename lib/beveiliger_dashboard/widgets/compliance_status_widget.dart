import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/unified_dashboard_card.dart';

import '../models/compliance_status.dart';

/// Compliance Status Widget for CAO arbeidsrecht monitoring
/// 
/// Features:
/// - Real-time CAO arbeidsrecht compliance tracking
/// - Visual indicators for violations and warnings
/// - Dutch legal compliance explanations
/// - Working time regulations (max 40h regular, 48h with overtime)
/// - Rest period monitoring (11h between shifts)
/// - Weekly/monthly hour limits tracking
/// - Compliance score with percentage
/// - Detailed violation explanations in Dutch
/// - Quick access to compliance documentation
class ComplianceStatusWidget extends StatelessWidget {
  final ComplianceStatus compliance;

  const ComplianceStatusWidget({
    super.key,
    required this.compliance,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final complianceColor = _getComplianceColor();
    
    return UnifiedDashboardCard(
      title: 'CAO Arbeidsrecht',
      subtitle: compliance.dutchComplianceSummary,
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall compliance status
          _buildComplianceHeader(complianceColor, colorScheme),
          
          const SizedBox(height: DesignTokens.spacingL),
          
          // Detailed compliance metrics
          _buildComplianceMetrics(colorScheme),
          
          if (compliance.hasViolations) ...[
            const SizedBox(height: DesignTokens.spacingL),
            _buildViolationsList(colorScheme),
          ],
          
          Builder(
            builder: (context) {
              final lowSeverityViolations = compliance.violations.where((v) => v.severity == ComplianceSeverity.low).toList();
              if (lowSeverityViolations.isNotEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: DesignTokens.spacingL),
                    _buildWarningsList(colorScheme, lowSeverityViolations),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: DesignTokens.spacingM),
          _buildComplianceActions(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildComplianceHeader(Color complianceColor, ColorScheme colorScheme) {
    final percentage = compliance.isCAOCompliant && !compliance.hasViolations ? 100 : (compliance.hasViolations ? 60 : 80);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Compliance score circle
            DecoratedBox(
              decoration: BoxDecoration(
                color: complianceColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: complianceColor,
                  width: 3,
                ),
              ),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontSize: DesignTokens.fontSizeBodyLarge,
                    color: complianceColor,
                  ),
                ),
                ),
              ),
            ),
            
            const SizedBox(width: DesignTokens.spacingM),
            
            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getComplianceStatusText(),
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeBodyLarge,
                      color: complianceColor,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    _getComplianceDescription(),
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status icon
            Icon(
              _getComplianceIcon(),
              color: complianceColor,
              size: DesignTokens.iconSizeL,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceMetrics(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildMetricRow(
          'Werkuren deze week',
          '${compliance.weeklyHours.toStringAsFixed(1)}u / ${compliance.maxWeeklyHours.toStringAsFixed(0)}u',
          compliance.weeklyHours <= compliance.maxWeeklyHours 
              ? DesignTokens.colorSuccess 
              : DesignTokens.colorError,
          colorScheme,
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildMetricRow(
          'Rusttijd laatste shift',
          '${compliance.restPeriod.inHours}u ${compliance.restPeriod.inMinutes % 60}m',
          compliance.restPeriod >= compliance.minRestPeriod 
              ? DesignTokens.colorSuccess 
              : DesignTokens.colorError,
          colorScheme,
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildMetricRow(
          'WPBR Certificaat',
          compliance.wpbrValid ? 'Geldig' : 'Verlopen',
          compliance.wpbrValid 
              ? DesignTokens.colorSuccess 
              : DesignTokens.colorError,
          colorScheme,
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        _buildMetricRow(
          'Gezondheidsverklaring',
          compliance.healthCertificateValid ? 'Geldig' : 'Verlopen',
          compliance.healthCertificateValid 
              ? DesignTokens.colorSuccess 
              : DesignTokens.colorError,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color statusColor, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightRegular,
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeCaption,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViolationsList(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'CAO Overtredingen (${compliance.violations.length})',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorError,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacingS),
          
          ...compliance.violations.take(3).map((violation) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: DesignTokens.colorError)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        violation.dutchDescription,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.colorError,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        violation.dutchRecommendation,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightRegular,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.colorError.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          
          if (compliance.violations.length > 3) ...[
            Text(
              'En ${compliance.violations.length - 3} andere overtredingen...',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorError,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningsList(ColorScheme colorScheme, List<ComplianceViolation> lowSeverityViolations) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorWarning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: DesignTokens.colorWarning,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Waarschuwingen (${lowSeverityViolations.length})',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorWarning,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacingS),
          
          ...lowSeverityViolations.take(2).map((violation) => Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: DesignTokens.colorWarning)),
                Expanded(
                  child: Text(
                    violation.dutchDescription,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.colorWarning,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          if (lowSeverityViolations.length > 2) ...[
            Text(
              'En ${lowSeverityViolations.length - 2} andere waarschuwingen...',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorWarning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showComplianceDetails(context);
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
            ),
          ),
        ),
        
        const SizedBox(width: DesignTokens.spacingS),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showComplianceGuide(context);
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('CAO Gids'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: DesignTokens.colorWhite,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
            ),
          ),
        ),
      ],
    );
  }

  Color _getComplianceColor() {
    if (compliance.isCAOCompliant && !compliance.hasViolations) {
      return DesignTokens.colorSuccess;
    } else if (compliance.hasViolations && compliance.violations.any((v) => v.severity == ComplianceSeverity.high || v.severity == ComplianceSeverity.critical)) {
      return DesignTokens.colorError;
    } else {
      return DesignTokens.colorWarning;
    }
  }

  IconData _getComplianceIcon() {
    if (compliance.isCAOCompliant && !compliance.hasViolations) {
      return Icons.check_circle;
    } else if (compliance.hasViolations && compliance.violations.any((v) => v.severity == ComplianceSeverity.high || v.severity == ComplianceSeverity.critical)) {
      return Icons.error;
    } else {
      return Icons.warning;
    }
  }

  String _getComplianceStatusText() {
    if (compliance.isCAOCompliant && !compliance.hasViolations) {
      return 'Volledig Conform';
    } else if (compliance.hasViolations && compliance.violations.any((v) => v.severity == ComplianceSeverity.high || v.severity == ComplianceSeverity.critical)) {
      return 'Niet Conform';
    } else {
      return 'Gedeeltelijk Conform';
    }
  }

  String _getComplianceDescription() {
    if (compliance.isCAOCompliant && !compliance.hasViolations) {
      return 'Alle CAO arbeidsrecht regels worden correct nageleefd.';
    } else if (compliance.hasViolations && compliance.violations.any((v) => v.severity == ComplianceSeverity.high || v.severity == ComplianceSeverity.critical)) {
      return 'Directe actie vereist om overtredingen te voorkomen.';
    } else {
      return 'Er zijn enkele aandachtspunten voor verbetering.';
    }
  }

  void _showComplianceDetails(BuildContext context) {
    final lowSeverityViolationsForDialog = compliance.violations.where((v) => v.severity == ComplianceSeverity.low).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CAO Arbeidsrecht Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Compliance Status: ${compliance.isCAOCompliant ? 'Conform' : 'Niet Conform'}'),
              const SizedBox(height: DesignTokens.spacingM),
              
              if (compliance.violations.isNotEmpty) ...[
                Text(
                  'Overtredingen:',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.colorError,
                  ),
                ),
                ...compliance.violations.map((v) => Padding(
                  padding: const EdgeInsets.only(left: DesignTokens.spacingM, top: DesignTokens.spacingS),
                  child: Text('• ${v.dutchDescription}'),
                )),
                const SizedBox(height: DesignTokens.spacingM),
              ],
              
              if (lowSeverityViolationsForDialog.isNotEmpty) ...[
                Text(
                  'Waarschuwingen:',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.colorWarning,
                  ),
                ),
                ...lowSeverityViolationsForDialog.map((v) => Padding(
                  padding: const EdgeInsets.only(left: DesignTokens.spacingM, top: DesignTokens.spacingS),
                  child: Text('• ${v.dutchDescription}'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showComplianceGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CAO Arbeidsrecht Gids'),
        content: const SingleChildScrollView(
          child: Text(
            'CAO Beveiligingsbranche Belangrijke Regels:\n\n'
            '• Maximaal 40 uur per week regulaire werktijd\n'
            '• Maximaal 8 uur overwerk per week (totaal 48u)\n'
            '• Minimaal 11 uur rust tussen diensten\n'
            '• Overwerk: 150% na 40u, 200% na 48u\n'
            '• Nachtwerk: 22:00-06:00 (toeslag 25%)\n'
            '• Vakantiegeld: 8% van brutoloon\n'
            '• ADV dagen: 5 per jaar\n\n'
            'Voor meer informatie, raadpleeg de volledige CAO tekst.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Begrepen'),
          ),
        ],
      ),
    );
  }
}