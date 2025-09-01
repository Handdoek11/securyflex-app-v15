import 'package:flutter/material.dart';
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/auth/services/certificate_management_service.dart';
import 'package:securyflex_app/auth/services/bsn_security_service.dart';

/// Certificate Card Widget voor certificate display
/// 
/// MANDATORY usage van:
/// - UnifiedCard.elevated with proper elevation
/// - DesignTokens for all spacing and typography
/// - Existing certificate icons from unified_design_tokens.dart
/// - Color-coded status indicators using existing color system
/// - Tap to view details using existing modal patterns
/// - Integration with existing certificate validation
class CertificateCardWidget extends StatelessWidget {
  final CertificateData certificate;
  final UserRole userRole;
  final bool showFullDetails;
  final VoidCallback? onTap;

  const CertificateCardWidget({
    super.key,
    required this.certificate,
    this.userRole = UserRole.guard,
    this.showFullDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    
    return UnifiedCard.standard(
      userRole: userRole,
      isClickable: onTap != null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Certificate icon
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  _getCertificateIcon(),
                  size: DesignTokens.iconSizeL,
                  color: colorScheme.primary,
                ),
              ),
              
              SizedBox(width: DesignTokens.spacingM),
              
              // Certificate details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Certificate type and number
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            certificate.type.displayName,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Status badge
                        _buildStatusBadge(statusColor, statusIcon),
                      ],
                    ),
                    
                    SizedBox(height: DesignTokens.spacingXS),
                    
                    // Certificate number
                    Text(
                      certificate.number,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    
                    SizedBox(height: DesignTokens.spacingS),
                    
                    // Expiry information
                    _buildExpiryInfo(colorScheme),
                  ],
                ),
              ),
            ],
          ),
          
          if (showFullDetails) ...[
            SizedBox(height: DesignTokens.spacingM),
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildFullDetails(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color statusColor, IconData statusIcon) {
    return Container(
      padding: EdgeInsets.symmetric(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: DesignTokens.iconSizeXS,
            color: statusColor,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            _getStatusText(),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: statusColor,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryInfo(ColorScheme colorScheme) {
    final daysUntilExpiry = certificate.daysUntilExpiration;
    
    String expiryText;
    Color expiryColor;
    IconData expiryIcon;
    
    if (certificate.isExpired) {
      expiryText = 'Verlopen op ${_formatDate(certificate.expirationDate)}';
      expiryColor = DesignTokens.colorError;
      expiryIcon = Icons.error;
    } else if (certificate.expiresSoon) {
      expiryText = 'Verloopt over $daysUntilExpiry dagen';
      expiryColor = DesignTokens.colorWarning;
      expiryIcon = Icons.schedule;
    } else {
      expiryText = 'Geldig tot ${_formatDate(certificate.expirationDate)}';
      expiryColor = DesignTokens.colorSuccess;
      expiryIcon = Icons.check_circle;
    }
    
    return Row(
      children: [
        Icon(
          expiryIcon,
          size: DesignTokens.iconSizeS,
          color: expiryColor,
        ),
        SizedBox(width: DesignTokens.spacingXS),
        Text(
          expiryText,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: expiryColor,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFullDetails(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Holder name
        _buildDetailRow(
          'Houder',
          certificate.holderName,
          Icons.person,
          colorScheme,
        ),
        
        // Issuing authority
        _buildDetailRow(
          'Uitgever',
          certificate.issuingAuthority,
          Icons.account_balance,
          colorScheme,
        ),
        
        // Issue date
        _buildDetailRow(
          'Uitgiftedatum',
          _formatDate(certificate.issueDate),
          Icons.calendar_today,
          colorScheme,
        ),
        
        // Expiry date
        _buildDetailRow(
          'Vervaldatum',
          _formatDate(certificate.expirationDate),
          Icons.event,
          colorScheme,
        ),
        
        // Last verified
        _buildDetailRow(
          'Laatst geverifieerd',
          _formatDate(certificate.lastVerified),
          Icons.verified,
          colorScheme,
        ),
        
        // Competencies
        if (certificate.competencies.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.stars,
                size: DesignTokens.iconSizeM,
                color: colorScheme.primary,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bevoegdheden',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Wrap(
                      spacing: DesignTokens.spacingS,
                      runSpacing: DesignTokens.spacingXS,
                      children: certificate.competencies.map((competency) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingS,
                            vertical: DesignTokens.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          ),
                          child: Text(
                            competency,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeCaption,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        
        // BSN (securely masked for GDPR compliance)
        if (certificate.holderBsn != null && certificate.holderBsn!.isNotEmpty) 
          _buildDetailRow(
            'BSN',
            _formatBsnSecure(certificate.holderBsn!),
            Icons.security,
            colorScheme,
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCertificateIcon() {
    switch (certificate.type) {
      case CertificateType.wpbr:
        return Icons.security;
      case CertificateType.vca:
        return Icons.engineering;
      case CertificateType.bhv:
        return Icons.medical_services;
      case CertificateType.ehbo:
        return Icons.local_hospital;
      }
  }

  Color _getStatusColor() {
    switch (certificate.currentStatus) {
      case CertificateStatus.valid:
        return certificate.expiresSoon 
            ? DesignTokens.colorWarning 
            : DesignTokens.colorSuccess;
      case CertificateStatus.expired:
      case CertificateStatus.revoked:
        return DesignTokens.colorError;
      case CertificateStatus.suspended:
        return DesignTokens.colorWarning;
      case CertificateStatus.pending:
        return DesignTokens.colorInfo;
      case CertificateStatus.expiringSoon:
        return DesignTokens.colorWarning;
      default:
        return DesignTokens.colorGray500;
    }
  }

  IconData _getStatusIcon() {
    switch (certificate.currentStatus) {
      case CertificateStatus.valid:
        return certificate.expiresSoon ? Icons.schedule : Icons.check_circle;
      case CertificateStatus.expired:
        return Icons.error;
      case CertificateStatus.revoked:
        return Icons.cancel;
      case CertificateStatus.suspended:
        return Icons.pause_circle;
      case CertificateStatus.pending:
        return Icons.hourglass_empty;
      case CertificateStatus.expiringSoon:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (certificate.currentStatus) {
      case CertificateStatus.valid:
        return certificate.expiresSoon ? 'Verloopt binnenkort' : 'Geldig';
      case CertificateStatus.expired:
        return 'Verlopen';
      case CertificateStatus.revoked:
        return 'Ingetrokken';
      case CertificateStatus.suspended:
        return 'Geschorst';
      case CertificateStatus.pending:
        return 'In behandeling';
      case CertificateStatus.expiringSoon:
        return 'Verloopt binnenkort';
      default:
        return 'Onbekend';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Securely format BSN for display with GDPR compliance
  String _formatBsnSecure(String bsn) {
    try {
      return BSNSecurityService.maskBSN(bsn);
    } catch (e) {
      // Fallback to safe masking if service unavailable
      return '***-**-****';
    }
  }
}