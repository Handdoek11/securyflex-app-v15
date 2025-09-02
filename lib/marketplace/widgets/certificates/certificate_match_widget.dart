import 'package:flutter/material.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_components/premium_glass_system.dart';
import '../../../models/certificates/matching_result_models.dart';
import '../../../models/certificates/certificate_models.dart';

/// Certificate Match Widget
/// 
/// Displays certificate matching results with visual indicators using
/// UnifiedComponents design system and role-based theming. Shows match
/// percentage, eligibility status, and detailed breakdown.

class CertificateMatchWidget extends StatelessWidget {
  final CertificateMatchResult matchResult;
  final Color? primaryColor;
  final bool showDetails;
  final VoidCallback? onTapDetails;
  final VoidCallback? onTapRecommendations;

  const CertificateMatchWidget({
    super.key,
    required this.matchResult,
    this.primaryColor,
    this.showDetails = true,
    this.onTapDetails,
    this.onTapRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimaryColor = primaryColor ?? DesignTokens.guardPrimary;
    final matchType = MatchType.fromScore(matchResult.overallScore);
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: PremiumGlassContainer(
        intensity: GlassIntensity.standard,
      elevation: GlassElevation.raised,
      tintColor: _getMatchBorderColor(matchType),
      enableTrustBorder: true,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: Column(
        children: [
          // Header with match score
          _buildMatchHeader(matchType, effectivePrimaryColor),
          
          // Match details
          if (showDetails) ...[
            _buildMatchDetails(),
            _buildRequirementsBreakdown(),
          ],
          
          // Action buttons
          _buildActionButtons(effectivePrimaryColor),
        ],
      ),
      ),
    );
  }

  /// Build match header with score and status
  Widget _buildMatchHeader(MatchType matchType, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _getMatchBorderColor(matchType).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusL),
          topRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        children: [
          // Match score circle
          _buildMatchScoreCircle(matchType),
          const SizedBox(width: DesignTokens.spacingM),
          
          // Match info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchType.dutchName,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.darkText,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                Text(
                  matchResult.eligibilityStatusDutch,
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
          
          // Eligibility indicator
          _buildEligibilityIndicator(),
        ],
      ),
    );
  }

  /// Build match score circle indicator
  Widget _buildMatchScoreCircle(MatchType matchType) {
    final color = _getMatchBorderColor(matchType);
    final score = matchResult.overallScore;
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          '$score%',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Build eligibility indicator
  Widget _buildEligibilityIndicator() {
    final isEligible = matchResult.isEligible;
    final color = isEligible ? DesignTokens.colorSuccess : DesignTokens.colorError;
    final icon = isEligible ? Icons.check_circle : Icons.cancel;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeS),
          const SizedBox(width: DesignTokens.spacingXS),
          Text(
            isEligible ? 'Geschikt' : 'Niet Geschikt',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build match details section
  Widget _buildMatchDetails() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          // Summary text
          Text(
            matchResult.summaryDutch,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightRegular,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.darkText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          // Progress indicators
          _buildProgressIndicators(),
          
          // Expiry warnings if any
          if (matchResult.needsAttention.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildExpiryWarnings(),
          ],
        ],
      ),
    );
  }

  /// Build progress indicators for requirements
  Widget _buildProgressIndicators() {
    return Column(
      children: [
        // Mandatory requirements
        if (matchResult.mandatoryTotal > 0) ...[
          _buildRequirementProgress(
            'Verplichte Certificaten',
            matchResult.mandatoryMet,
            matchResult.mandatoryTotal,
            DesignTokens.colorError,
          ),
          const SizedBox(height: DesignTokens.spacingS),
        ],
        
        // Preferred requirements
        if (matchResult.preferredTotal > 0) ...[
          _buildRequirementProgress(
            'Gewenste Certificaten',
            matchResult.preferredMet,
            matchResult.preferredTotal,
            DesignTokens.colorInfo,
          ),
        ],
      ],
    );
  }

  /// Build individual requirement progress bar
  Widget _buildRequirementProgress(String title, int met, int total, Color color) {
    final percentage = total > 0 ? (met / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeMeta,
                fontWeight: DesignTokens.fontWeightMedium,
                fontFamily: DesignTokens.fontFamily,
                color: DesignTokens.darkText,
              ),
            ),
            Text(
              '$met/$total',
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeMeta,
                fontWeight: DesignTokens.fontWeightBold,
                fontFamily: DesignTokens.fontFamily,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: DesignTokens.colorGray200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Build requirements breakdown
  Widget _buildRequirementsBreakdown() {
    if (matchResult.matchDetails.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificaat Overzicht',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.darkText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          
          // Show first few certificate details
          ...matchResult.matchDetails.take(3).map((detail) => 
            _buildCertificateDetail(detail)
          ),
          
          // Show more indicator if there are more details
          if (matchResult.matchDetails.length > 3) ...[
            const SizedBox(height: DesignTokens.spacingS),
            GestureDetector(
              onTap: onTapDetails,
              child: Text(
                'Bekijk alle ${matchResult.matchDetails.length} certificaten...',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamily,
                  color: primaryColor ?? DesignTokens.guardPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build individual certificate detail
  Widget _buildCertificateDetail(CertificateMatchDetail detail) {
    final certificate = CertificateRegistry.getCertificateById(detail.certificateId);
    final statusColor = _getCertificateStatusColor(detail.status);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          
          // Certificate info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate?.name ?? detail.certificateId,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.darkText,
                  ),
                ),
                if (detail.reason.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingXXS),
                  Text(
                    detail.reason,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Status text
          Text(
            detail.status.dutchName,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build expiry warnings section
  Widget _buildExpiryWarnings() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: DesignTokens.colorWarning,
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingXS),
              const Text(
                'Let op: Certificaten vervallen binnenkort',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXS),
          
          ...matchResult.needsAttention.map((detail) {
            final daysUntilExpiry = detail.daysUntilExpiry ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXXS),
              child: Text(
                '• ${CertificateRegistry.getCertificateById(detail.certificateId)?.name} vervalt over $daysUntilExpiry dagen',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.darkText,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: DesignTokens.colorGray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Details button
          if (onTapDetails != null) ...[
            Expanded(
              child: _buildActionButton(
                'Details Bekijken',
                Icons.info_outline,
                onTapDetails!,
                isOutline: true,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),
          ],
          
          // Recommendations button
          if (onTapRecommendations != null) ...[
            Expanded(
              flex: onTapDetails != null ? 1 : 2,
              child: _buildActionButton(
                'Aanbevelingen',
                Icons.lightbulb_outline,
                onTapRecommendations!,
                color: primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build individual action button
  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isOutline = false,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: isOutline ? color : DesignTokens.colorWhite,
        ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            fontFamily: DesignTokens.fontFamily,
            color: isOutline ? color : DesignTokens.colorWhite,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutline ? DesignTokens.colorWhite : color,
          foregroundColor: isOutline ? color : DesignTokens.colorWhite,
          side: isOutline ? BorderSide(color: color) : null,
          elevation: isOutline ? 0 : DesignTokens.elevationLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      ),
    );
  }

  /// Get border color based on match type
  Color _getMatchBorderColor(MatchType matchType) {
    switch (matchType) {
      case MatchType.perfect:
        return DesignTokens.colorSuccess;
      case MatchType.excellent:
        return DesignTokens.colorSuccessLight;
      case MatchType.good:
        return DesignTokens.colorInfo;
      case MatchType.partial:
        return DesignTokens.colorWarning;
      case MatchType.insufficient:
        return DesignTokens.colorError;
      case MatchType.unqualified:
        return DesignTokens.colorGray500;
    }
  }

  /// Get certificate status color
  Color _getCertificateStatusColor(CertificateMatchStatus status) {
    switch (status) {
      case CertificateMatchStatus.exactMatch:
        return DesignTokens.colorSuccess;
      case CertificateMatchStatus.equivalentMatch:
        return DesignTokens.colorSuccessLight;
      case CertificateMatchStatus.higherLevelMatch:
        return DesignTokens.colorInfo;
      case CertificateMatchStatus.partialMatch:
        return DesignTokens.colorWarning;
      case CertificateMatchStatus.expired:
        return DesignTokens.colorError;
      case CertificateMatchStatus.missing:
        return DesignTokens.colorGray500;
    }
  }
}