import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../bloc/certificate_bloc.dart';
import '../bloc/certificate_event.dart';
import '../bloc/certificate_state.dart';
import '../services/certificate_management_service.dart';

/// Widget displaying certificate statistics and overview
class CertificateStatisticsWidget extends StatefulWidget {
  final String userId;
  final bool showDetailedStats;
  final Function(CertificateType)? onTypeSelected;

  const CertificateStatisticsWidget({
    super.key,
    required this.userId,
    this.showDetailedStats = true,
    this.onTypeSelected,
  });

  @override
  State<CertificateStatisticsWidget> createState() => _CertificateStatisticsWidgetState();
}

class _CertificateStatisticsWidgetState extends State<CertificateStatisticsWidget> {
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    context.read<CertificateBloc>().add(CertificateGetStatistics(
      userId: widget.userId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CertificateBloc, CertificateState>(
      builder: (context, state) {
        if (state is CertificateLoading) {
          return _buildLoadingState();
        }
        
        if (state is CertificateStatistics) {
          return _buildStatistics(state);
        }
        
        if (state is CertificatesLoaded) {
          return _buildStatisticsFromLoaded(state);
        }
        
        if (state is CertificateError) {
          return _buildErrorState(state);
        }
        
        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Statistieken laden...',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(CertificateStatistics stats) {
    return Column(
      children: [
        // Overview cards
        _buildOverviewCards(
          totalCertificates: stats.totalCertificates,
          validCertificates: stats.validCertificates,
          expiredCertificates: stats.expiredCertificates,
          expiringSoon: stats.expiringSoon,
          validityPercentage: stats.validityPercentage,
        ),
        
        if (widget.showDetailedStats) ...[
          SizedBox(height: DesignTokens.spacingM),
          
          // Certificate types breakdown
          _buildTypeBreakdown(stats.certificatesByType),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Status distribution
          _buildStatusDistribution(stats.certificatesByStatus),
        ],
      ],
    );
  }

  Widget _buildStatisticsFromLoaded(CertificatesLoaded state) {
    final totalCertificates = state.certificates.length;
    final validCertificates = state.validCertificates.length;
    final expiredCertificates = state.expiredCertificates.length;
    final expiringSoon = state.certificatesExpiringSoon.length;
    final validityPercentage = totalCertificates > 0 
        ? (validCertificates / totalCertificates) * 100 
        : 0.0;

    return Column(
      children: [
        _buildOverviewCards(
          totalCertificates: totalCertificates,
          validCertificates: validCertificates,
          expiredCertificates: expiredCertificates,
          expiringSoon: expiringSoon,
          validityPercentage: validityPercentage,
        ),
        
        if (widget.showDetailedStats) ...[
          SizedBox(height: DesignTokens.spacingM),
          _buildTypeBreakdown(state.certificateCount),
        ],
      ],
    );
  }

  Widget _buildOverviewCards({
    required int totalCertificates,
    required int validCertificates,
    required int expiredCertificates,
    required int expiringSoon,
    required double validityPercentage,
  }) {
    return Column(
      children: [
        // Main statistics row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Totaal',
                value: totalCertificates.toString(),
                icon: Icons.verified_user_outlined,
                color: DesignTokens.colorPrimaryBlue,
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: _buildStatCard(
                title: 'Geldig',
                value: validCertificates.toString(),
                icon: Icons.check_circle_outline,
                color: DesignTokens.colorSuccess,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Secondary statistics row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Verlopen',
                value: expiredCertificates.toString(),
                icon: Icons.error_outline,
                color: DesignTokens.colorError,
                isWarning: expiredCertificates > 0,
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: _buildStatCard(
                title: 'Verloopt binnenkort',
                value: expiringSoon.toString(),
                icon: Icons.warning_outlined,
                color: DesignTokens.colorWarning,
                isWarning: expiringSoon > 0,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        // Validity percentage indicator
        _buildValidityIndicator(validityPercentage),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWarning = false,
  }) {
    return UnifiedCard(
      variant: UnifiedCardVariant.compact,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: DesignTokens.iconSizeL,
              ),
              const Spacer(),
              if (isWarning && value != '0')
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXXL,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.darkText,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidityIndicator(double percentage) {
    Color indicatorColor;
    String statusText;
    
    if (percentage >= 80) {
      indicatorColor = DesignTokens.colorSuccess;
      statusText = 'Uitstekend';
    } else if (percentage >= 60) {
      indicatorColor = DesignTokens.colorWarning;
      statusText = 'Goed';
    } else {
      indicatorColor = DesignTokens.colorError;
      statusText = 'Aandacht vereist';
    }

    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: DesignTokens.colorPrimaryBlue,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Validiteitsstatus',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.darkText,
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: indicatorColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: DesignTokens.colorGray200,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% geldig',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdown(Map<CertificateType, int> certificatesByType) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: DesignTokens.colorPrimaryBlue,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Certificaattypes',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.darkText,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          ...certificatesByType.entries.map((entry) => 
            _buildTypeBreakdownItem(entry.key, entry.value)
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBreakdownItem(CertificateType type, int count) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: InkWell(
        onTap: widget.onTypeSelected != null && count > 0
            ? () => widget.onTypeSelected!(type)
            : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          child: Row(
            children: [
              Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.code,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.darkText,
                      ),
                    ),
                    Text(
                      type.dutchName,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: DesignTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: count > 0 
                      ? _getTypeColor(type).withValues(alpha: 0.1)
                      : DesignTokens.colorGray200,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: count > 0 
                        ? _getTypeColor(type)
                        : DesignTokens.mutedText,
                  ),
                ),
              ),
              if (widget.onTypeSelected != null && count > 0)
                Icon(
                  Icons.chevron_right,
                  color: DesignTokens.mutedText,
                  size: DesignTokens.iconSizeM,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, int> certificatesByStatus) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.donut_small_outlined,
                color: DesignTokens.colorPrimaryBlue,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Status verdeling',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.darkText,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          ...certificatesByStatus.entries.map((entry) => 
            _buildStatusItem(entry.key, entry.value)
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status, int count) {
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.darkText,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CertificateError state) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: DesignTokens.iconSizeXL,
            color: DesignTokens.colorError,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Fout bij laden statistieken',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.darkText,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            state.localizedErrorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: DesignTokens.iconSizeXL,
            color: DesignTokens.colorGray400,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geen statistieken beschikbaar',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.darkText,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getTypeIcon(CertificateType type) {
    switch (type) {
      case CertificateType.wpbr:
        return Icons.security;
      case CertificateType.vca:
        return Icons.verified;
      case CertificateType.bhv:
        return Icons.health_and_safety;
      case CertificateType.ehbo:
        return Icons.medical_services;
    }
  }

  Color _getTypeColor(CertificateType type) {
    switch (type) {
      case CertificateType.wpbr:
        return DesignTokens.colorPrimaryBlue;
      case CertificateType.vca:
        return DesignTokens.colorSecondaryTeal;
      case CertificateType.bhv:
        return DesignTokens.colorWarning;
      case CertificateType.ehbo:
        return DesignTokens.colorError;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return DesignTokens.colorSuccess;
      case 'expired':
        return DesignTokens.colorError;
      case 'expiring_soon':
        return DesignTokens.colorWarning;
      default:
        return DesignTokens.colorGray500;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return 'Geldig';
      case 'expired':
        return 'Verlopen';
      case 'expiring_soon':
        return 'Verloopt binnenkort';
      default:
        return status;
    }
  }
}