import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';

import '../services/certificate_management_service.dart';
import '../services/bsn_security_service.dart';

/// Certificate display card widget with status indicators and actions
class CertificateCard extends StatelessWidget {
  final CertificateData certificate;
  final bool showActions;
  final bool showSecureInfo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onVerify;
  final Widget? customAction;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.showActions = true,
    this.showSecureInfo = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDownload,
    this.onVerify,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final isExpired = certificate.isExpired;
    final expiresSoon = certificate.expiresSoon;
    
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      isClickable: onTap != null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with certificate number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.certificateNumber,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.darkText,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      _getCertificateTypeDescription(),
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        color: DesignTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Certificate holder information
          _buildInfoRow(
            'Houder',
            certificate.holderName,
            Icons.person_outline,
          ),
          
          if (showSecureInfo && certificate.decryptedBsn.isNotEmpty)
            _buildInfoRow(
              'BSN',
              BSNSecurityService.maskBSN(certificate.decryptedBsn),
              Icons.badge_outlined,
            ),
          
          _buildInfoRow(
            'Uitgiftedatum',
            dateFormat.format(certificate.issueDate),
            Icons.calendar_today_outlined,
          ),
          
          _buildInfoRow(
            'Vervaldatum',
            dateFormat.format(certificate.expirationDate),
            Icons.schedule_outlined,
            textColor: isExpired ? DesignTokens.colorError : 
                     expiresSoon ? DesignTokens.colorWarning : null,
          ),
          
          _buildInfoRow(
            'Autoriteit',
            certificate.issuingAuthority,
            Icons.verified_outlined,
          ),
          
          if (certificate.authorizations.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            _buildAuthorizationsChips(),
          ],
          
          // Expiration warning
          if (expiresSoon || isExpired) ...[
            SizedBox(height: DesignTokens.spacingM),
            _buildExpirationWarning(),
          ],
          
          // Actions
          if (showActions) ...[
            SizedBox(height: DesignTokens.spacingM),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (certificate.isExpired) {
      badgeColor = DesignTokens.colorError;
      statusText = 'Verlopen';
      statusIcon = Icons.error_outline;
    } else if (certificate.expiresSoon) {
      badgeColor = DesignTokens.colorWarning;
      statusText = 'Verloopt binnenkort';
      statusIcon = Icons.warning_outlined;
    } else if (certificate.isCurrentlyValid) {
      badgeColor = DesignTokens.colorSuccess;
      statusText = 'Geldig';
      statusIcon = Icons.check_circle_outline;
    } else {
      badgeColor = DesignTokens.colorGray500;
      statusText = certificate.status.name;
      statusIcon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: DesignTokens.iconSizeS,
            color: badgeColor,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            statusText,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? textColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: DesignTokens.mutedText,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
            ),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: textColor ?? DesignTokens.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizationsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.security_outlined,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.mutedText,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Text(
              'Bevoegdheden:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Wrap(
          spacing: DesignTokens.spacingXS,
          runSpacing: DesignTokens.spacingXS,
          children: certificate.authorizations.map((auth) => Chip(
            label: Text(
              auth,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.colorWhite,
              ),
            ),
            backgroundColor: DesignTokens.colorPrimaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildExpirationWarning() {
    final isExpired = certificate.isExpired;
    final daysUntilExpiration = certificate.daysUntilExpiration;
    
    String warningText;
    Color warningColor;
    IconData warningIcon;

    if (isExpired) {
      warningText = 'Dit certificaat is ${-daysUntilExpiration} dagen geleden verlopen';
      warningColor = DesignTokens.colorError;
      warningIcon = Icons.error_outline;
    } else {
      warningText = 'Dit certificaat verloopt over $daysUntilExpiration dagen';
      warningColor = DesignTokens.colorWarning;
      warningIcon = Icons.warning_outlined;
    }

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: warningColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            warningIcon,
            color: warningColor,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = <Widget>[];

    if (onVerify != null) {
      actions.add(
        UnifiedButton.secondary(
          text: 'Verifiëren',
          onPressed: onVerify!,
          size: UnifiedButtonSize.small,
        ),
      );
    }

    if (onDownload != null) {
      actions.add(
        UnifiedButton.text(
          text: 'Download',
          onPressed: onDownload!,
          size: UnifiedButtonSize.small,
        ),
      );
    }

    if (onEdit != null) {
      actions.add(
        UnifiedButton.text(
          text: 'Bewerken',
          onPressed: onEdit!,
          size: UnifiedButtonSize.small,
        ),
      );
    }

    if (onDelete != null) {
      actions.add(
        UnifiedButton.text(
          text: 'Verwijderen',
          onPressed: onDelete!,
          size: UnifiedButtonSize.small,
        ),
      );
    }

    if (customAction != null) {
      actions.add(customAction!);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: DesignTokens.spacingS,
      runSpacing: DesignTokens.spacingXS,
      children: actions,
    );
  }

  String _getCertificateTypeDescription() {
    final certificateNumber = certificate.certificateNumber;
    
    if (certificateNumber.startsWith('WPBR')) {
      return 'Wet Particuliere Beveiligingsorganisaties';
    } else if (certificateNumber.startsWith('VCA')) {
      return 'Veiligheid Checklist Aannemers';
    } else if (certificateNumber.startsWith('BHV')) {
      return 'Bedrijfshulpverlening';
    } else if (certificateNumber.startsWith('EHBO')) {
      return 'Eerste Hulp Bij Ongelukken';
    }
    
    return 'Certificaat';
  }

  // Removed _formatBsn - now using BSNSecurityService.maskBSN for GDPR compliance
}