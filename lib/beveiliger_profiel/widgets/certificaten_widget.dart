import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/beveiliger_profiel/bloc/beveiliger_profiel_bloc.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/certificate_card_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/screens/certificate_add_screen.dart';
import 'package:securyflex_app/auth/services/certificate_management_service.dart';

/// Certificaten Widget met comprehensive certificate display
/// 
/// MANDATORY usage van:
/// - UnifiedCard.standard voor certificate container
/// - Existing CertificateData model from certificate_management_service.dart
/// - DesignTokens.spacingS between certificate cards  
/// - Existing status colors (green/orange/red) from unified_design_tokens.dart
/// - Integration with existing WPBR verification service
/// - Certificate status badges using existing badge components
/// - "Certificaat toevoegen" button using UnifiedButton.secondary
class CertificatenWidget extends StatefulWidget {
  final String userId;
  final UserRole userRole;
  
  const CertificatenWidget({
    super.key,
    required this.userId,
    this.userRole = UserRole.guard,
  });

  @override
  State<CertificatenWidget> createState() => _CertificatenWidgetState();
}

class _CertificatenWidgetState extends State<CertificatenWidget> {
  final CertificateManagementService _certificateService = CertificateManagementService();
  List<CertificateData> _certificates = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final certificates = await _certificateService.getUserCertificates(widget.userId);
      
      if (mounted) {
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij laden certificaten: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddCertificate() async {
    final result = await context.push('/beveiliger/certificates/add');
    // Original: Navigator.of(context).push<bool>(
    //   MaterialPageRoute(
    //     builder: (context) => CertificateAddScreen(
    //       userId: widget.userId,
    //       userRole: widget.userRole,
    //     ),
    //   ),
    // );

    // Refresh certificates if new certificate was added
    if (result == true && mounted) {
      await _loadCertificates();
      
      // Trigger profile refresh in parent BLoC
      if (!context.mounted) return;
      context.read<BeveiligerProfielBloc>().add(const RefreshProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Certificaten',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content - full width
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
          // Content area
          if (_isLoading)
            _buildLoadingState(colorScheme)
          else if (_errorMessage != null)
            _buildErrorState(colorScheme)
          else if (_certificates.isEmpty)
            _buildEmptyState(colorScheme)
          else
            _buildCertificateList(),
        ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingL),
        child: Column(
          children: [
            SizedBox(
              width: DesignTokens.iconSizeL,
              height: DesignTokens.iconSizeL,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Certificaten laden...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: DesignTokens.iconSizeL,
              color: DesignTokens.colorWarning,
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              _errorMessage ?? 'Onbekende fout',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: DesignTokens.iconSizeXL,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Geen certificaten toegevoegd',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Voeg certificaten toe om je profiel te completeren',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingM),
            UnifiedButton.secondary(
              text: 'Certificaat toevoegen',
              onPressed: _navigateToAddCertificate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateList() {
    // Sort certificates: valid first, then by expiry date
    final sortedCertificates = List<CertificateData>.from(_certificates);
    sortedCertificates.sort((a, b) {
      // First sort by status (valid certificates first)
      if (a.isCurrentlyValid && !b.isCurrentlyValid) return -1;
      if (!a.isCurrentlyValid && b.isCurrentlyValid) return 1;
      
      // Then by expiry date (soonest expiry first for valid certs)
      return a.expirationDate.compareTo(b.expirationDate);
    });

    return Column(
      children: [
        // Certificate cards
        ...sortedCertificates.map((certificate) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: CertificateCardWidget(
              certificate: certificate,
              userRole: widget.userRole,
              onTap: () => _showCertificateDetails(certificate),
            ),
          );
        }),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Add certificate button
        SizedBox(
          width: double.infinity,
          child: UnifiedButton.secondary(
            text: 'Certificaat toevoegen',
                        onPressed: _navigateToAddCertificate,
          ),
        ),
        
        // Certificate statistics
        if (_certificates.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingM),
          _buildCertificateStatistics(),
        ],
      ],
    );
  }

  Widget _buildCertificateStatistics() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    final validCount = _certificates.where((cert) => cert.isCurrentlyValid).length;
    final expiringCount = _certificates.where((cert) => cert.expiresSoon && cert.isCurrentlyValid).length;
    final expiredCount = _certificates.where((cert) => cert.isExpired).length;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            validCount.toString(),
            'Geldig',
            DesignTokens.colorSuccess,
            Icons.check_circle_outline,
          ),
          _buildStatItem(
            expiringCount.toString(),
            'Verloopt binnenkort',
            DesignTokens.colorWarning,
            Icons.schedule,
          ),
          _buildStatItem(
            expiredCount.toString(),
            'Verlopen',
            DesignTokens.colorError,
            Icons.error_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeM,
          color: color,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: SecuryFlexTheme.getColorScheme(widget.userRole).onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showCertificateDetails(CertificateData certificate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
          
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusXL),
                topRight: Radius.circular(DesignTokens.radiusXL),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.only(top: DesignTokens.spacingS),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.all(DesignTokens.spacingL),
                    child: CertificateCardWidget(
                      certificate: certificate,
                      userRole: widget.userRole,
                      showFullDetails: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}