import 'package:flutter/material.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_components/premium_glass_system.dart';
import '../../../models/certificates/certificate_models.dart';
import '../../../models/certificates/job_requirements_models.dart';

/// Missing Certificates Widget
/// 
/// Displays missing certificates with priority indicators, estimated costs,
/// and training provider information using role-based theming.

class MissingCertificatesWidget extends StatelessWidget {
  final List<CertificateGap> certificateGaps;
  final Color? primaryColor;
  final VoidCallback? onTapCertificate;
  final Function(String certificateId)? onSelectTrainingProvider;
  final bool showTrainingProviders;
  final bool showCostEstimates;

  const MissingCertificatesWidget({
    super.key,
    required this.certificateGaps,
    this.primaryColor,
    this.onTapCertificate,
    this.onSelectTrainingProvider,
    this.showTrainingProviders = true,
    this.showCostEstimates = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimaryColor = primaryColor ?? DesignTokens.guardPrimary;
    
    if (certificateGaps.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.colorGray200,
          width: 1,
        ),
        boxShadow: const [DesignTokens.shadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildCertificateGapsList(effectivePrimaryColor),
          if (showCostEstimates) _buildCostSummary(),
        ],
      ),
    );
  }

  /// Build header section
  Widget _buildHeader() {
    final criticalGaps = certificateGaps.where((gap) => 
        gap.priority == RequirementPriority.mandatory).length;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.colorGray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: DesignTokens.colorError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              Icons.warning_amber,
              color: DesignTokens.colorError,
              size: DesignTokens.iconSizeM,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ontbrekende Certificaten',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.darkText,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                Text(
                  '${certificateGaps.length} certificaten ontbreken${criticalGaps > 0 ? ', waarvan $criticalGaps verplicht' : ''}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeMeta,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build list of certificate gaps
  Widget _buildCertificateGapsList(Color primaryColor) {
    // Sort by priority and impact score
    final sortedGaps = List<CertificateGap>.from(certificateGaps);
    sortedGaps.sort((a, b) {
      // Mandatory first
      if (a.priority == RequirementPriority.mandatory && 
          b.priority != RequirementPriority.mandatory) {
        return -1;
      }
      if (b.priority == RequirementPriority.mandatory && 
          a.priority != RequirementPriority.mandatory) {
        return 1;
      }
      
      // Then by impact score
      return b.impactScore.compareTo(a.impactScore);
    });

    return Column(
      children: sortedGaps.asMap().entries.map((entry) {
        final index = entry.key;
        final gap = entry.value;
        final isLast = index == sortedGaps.length - 1;
        
        return _buildCertificateGapItem(gap, primaryColor, isLast);
      }).toList(),
    );
  }

  /// Build individual certificate gap item
  Widget _buildCertificateGapItem(CertificateGap gap, Color primaryColor, bool isLast) {
    final certificate = CertificateRegistry.getCertificateById(gap.certificateId);
    if (certificate == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(
            color: DesignTokens.colorGray100,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapCertificate,
          borderRadius: isLast ? const BorderRadius.only(
            bottomLeft: Radius.circular(DesignTokens.radiusL),
            bottomRight: Radius.circular(DesignTokens.radiusL),
          ) : null,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Certificate header
                _buildCertificateHeader(gap, certificate),
                const SizedBox(height: DesignTokens.spacingS),
                
                // Reason and recommendation
                _buildReasonAndRecommendation(gap),
                
                // Cost and time info
                if (showCostEstimates) ...[
                  const SizedBox(height: DesignTokens.spacingS),
                  _buildCostAndTimeInfo(gap),
                ],
                
                // Training providers
                if (showTrainingProviders && gap.trainingProviders.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingS),
                  _buildTrainingProviders(gap, primaryColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build certificate header with priority
  Widget _buildCertificateHeader(CertificateGap gap, DutchSecurityCertificate certificate) {
    return Row(
      children: [
        // Priority indicator
        _buildPriorityBadge(gap.priority),
        const SizedBox(width: DesignTokens.spacingS),
        
        // Certificate info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certificate.name,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeBodyLarge,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXXS),
              Text(
                'Certificaat vereist voor deze functie', // Description removed in optimized model
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        
        // Impact score
        _buildImpactScoreBadge(gap.impactScore),
      ],
    );
  }

  /// Build priority badge
  Widget _buildPriorityBadge(RequirementPriority priority) {
    Color color;
    String text;
    
    switch (priority) {
      case RequirementPriority.mandatory:
        color = DesignTokens.colorError;
        text = 'VERPLICHT';
        break;
      case RequirementPriority.preferred:
        color = DesignTokens.colorWarning;
        text = 'GEWENST';
        break;
      case RequirementPriority.advantageous:
        color = DesignTokens.colorInfo;
        text = 'VOORDELIG';
        break;
      case RequirementPriority.optional:
        color = DesignTokens.colorGray500;
        text = 'OPTIONEEL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeXS,
          fontWeight: DesignTokens.fontWeightBold,
          fontFamily: DesignTokens.fontFamily,
          color: color,
        ),
      ),
    );
  }

  /// Build impact score badge
  Widget _buildImpactScoreBadge(int impactScore) {
    final color = _getImpactScoreColor(impactScore);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: color,
            size: DesignTokens.iconSizeXS,
          ),
          const SizedBox(width: DesignTokens.spacingXXS),
          Text(
            '+$impactScore',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamily,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build reason and recommendation
  Widget _buildReasonAndRecommendation(CertificateGap gap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reason
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: DesignTokens.colorGray50,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: DesignTokens.mutedText,
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  gap.reason,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Recommendation if available
        if (gap.recommendation != null && gap.recommendation!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spacingS),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: DesignTokens.colorSuccess,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    gap.recommendation!,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build cost and time information
  Widget _buildCostAndTimeInfo(CertificateGap gap) {
    return Row(
      children: [
        // Time to obtain
        if (gap.timeToObtain != null) ...[
          Expanded(
            child: _buildInfoItem(
              Icons.schedule,
              'Tijd',
              _formatDuration(gap.timeToObtain!),
              DesignTokens.colorInfo,
            ),
          ),
        ],
        
        // Cost estimate
        if (gap.estimatedCost != null && gap.estimatedCost! > 0) ...[
          if (gap.timeToObtain != null) const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: _buildInfoItem(
              Icons.euro,
              'Kosten',
              '€${gap.estimatedCost!.toStringAsFixed(0)}',
              DesignTokens.colorWarning,
            ),
          ),
        ],
      ],
    );
  }

  /// Build info item
  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeS),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build training providers
  Widget _buildTrainingProviders(CertificateGap gap, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aanbieders:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
            color: DesignTokens.darkText,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        Wrap(
          spacing: DesignTokens.spacingXS,
          runSpacing: DesignTokens.spacingXS,
          children: gap.trainingProviders.take(3).map((provider) =>
            GestureDetector(
              onTap: () => onSelectTrainingProvider?.call(gap.certificateId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  provider,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  /// Build cost summary at the bottom
  Widget _buildCostSummary() {
    final totalCost = certificateGaps
        .where((gap) => gap.estimatedCost != null)
        .fold(0.0, (accumulator, gap) => accumulator + gap.estimatedCost!);

    final totalImpact = certificateGaps.fold(0, (accumulator, gap) => accumulator + gap.impactScore);

    if (totalCost <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusL),
          bottomRight: Radius.circular(DesignTokens.radiusL),
        ),
        border: const Border(
          top: BorderSide(
            color: DesignTokens.colorGray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Totale Investering',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                '€${totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Potentiële Impact',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                '+$totalImpact punten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.colorSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.colorSuccess.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.colorSuccess.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: DesignTokens.colorSuccess,
            size: DesignTokens.iconSizeXL,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Text(
            'Geen Ontbrekende Certificaten',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.darkText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          const Text(
            'Je hebt alle vereiste certificaten voor deze functie.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightRegular,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper methods

  Color _getImpactScoreColor(int score) {
    if (score >= 30) return DesignTokens.colorSuccess;
    if (score >= 20) return DesignTokens.colorInfo;
    if (score >= 10) return DesignTokens.colorWarning;
    return DesignTokens.colorGray500;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 365) {
      final years = (duration.inDays / 365).round();
      return '$years jaar';
    } else if (duration.inDays >= 30) {
      final months = (duration.inDays / 30).round();
      return '$months maanden';
    } else if (duration.inDays >= 7) {
      final weeks = (duration.inDays / 7).round();
      return '$weeks weken';
    } else {
      return '${duration.inDays} dagen';
    }
  }
}