import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../bloc/certificate_bloc.dart';
import '../bloc/certificate_event.dart';
import '../bloc/certificate_state.dart';
import '../services/certificate_management_service.dart';
import 'certificate_card.dart';
import 'certificate_upload_form.dart';
import 'certificate_verification_widget.dart';

/// Comprehensive certificate dashboard showing overview, statistics, and management options
class CertificateDashboard extends StatefulWidget {
  final String userId;
  final bool showActions;
  final bool showStatistics;
  final VoidCallback? onAddCertificate;
  final Function(CertificateData)? onEditCertificate;
  final Function(CertificateData)? onDeleteCertificate;
  final Function(CertificateData)? onVerifyCertificate;

  const CertificateDashboard({
    super.key,
    required this.userId,
    this.showActions = true,
    this.showStatistics = true,
    this.onAddCertificate,
    this.onEditCertificate,
    this.onDeleteCertificate,
    this.onVerifyCertificate,
  });

  @override
  State<CertificateDashboard> createState() => _CertificateDashboardState();
}

class _CertificateDashboardState extends State<CertificateDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<CertificateData> _certificates = [];
  CertificateStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadCertificates();
    if (widget.showStatistics) {
      _loadStatistics();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateBloc, CertificateState>(
      listener: _handleBlocStateChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: DesignTokens.spacingL),
          
          if (widget.showStatistics && _statistics != null) ...[
            _buildStatisticsOverview(),
            SizedBox(height: DesignTokens.spacingL),
          ],
          
          _buildTabBar(),
          SizedBox(height: DesignTokens.spacingM),
          
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorPrimaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
          child: Icon(
            Icons.verified_user,
            color: DesignTokens.colorPrimaryBlue,
            size: DesignTokens.iconSizeXL,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijn Certificaten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                'Beheer en controleer je beveiligingscertificaten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
        
        if (widget.showActions) ...[
          UnifiedButton(
            text: 'Nieuw Certificaat',
            type: UnifiedButtonType.primary,
            onPressed: widget.onAddCertificate ?? _showAddCertificateDialog,
          ),
        ],
      ],
    );
  }

  Widget _buildStatisticsOverview() {
    if (_statistics == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(child: _buildStatCard(
          'Totaal',
          _statistics!.totalCertificates.toString(),
          Icons.badge,
          DesignTokens.colorPrimaryBlue,
        )),
        SizedBox(width: DesignTokens.spacingM),
        
        Expanded(child: _buildStatCard(
          'Geldig',
          _statistics!.validCertificates.toString(),
          Icons.check_circle,
          DesignTokens.colorSuccess,
        )),
        SizedBox(width: DesignTokens.spacingM),
        
        Expanded(child: _buildStatCard(
          'Verloopt Binnenkort',
          _statistics!.expiringSoon.toString(),
          Icons.warning,
          DesignTokens.colorWarning,
        )),
        SizedBox(width: DesignTokens.spacingM),
        
        Expanded(child: _buildStatCard(
          'Verlopen',
          _statistics!.expiredCertificates.toString(),
          Icons.error,
          DesignTokens.colorError,
        )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: DesignTokens.iconSizeL,
              ),
              Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.colorGray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
        tabs: const [
          Tab(text: 'Alle'),
          Tab(text: 'WPBR'),
          Tab(text: 'VCA'),
          Tab(text: 'BHV'),
          Tab(text: 'EHBO'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: DesignTokens.colorPrimaryBlue,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Certificaten laden...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildCertificateList(_certificates),
        _buildCertificateList(_getCertificatesByType(CertificateType.wpbr)),
        _buildCertificateList(_getCertificatesByType(CertificateType.vca)),
        _buildCertificateList(_getCertificatesByType(CertificateType.bhv)),
        _buildCertificateList(_getCertificatesByType(CertificateType.ehbo)),
      ],
    );
  }

  Widget _buildCertificateList(List<CertificateData> certificates) {
    if (certificates.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
      itemCount: certificates.length,
      separatorBuilder: (context, index) => SizedBox(height: DesignTokens.spacingM),
      itemBuilder: (context, index) {
        final certificate = certificates[index];
        return CertificateCard(
          certificate: certificate,
          showActions: widget.showActions,
          onTap: () => _showCertificateDetails(certificate),
          onEdit: () => widget.onEditCertificate?.call(certificate),
          onDelete: () => _confirmDeleteCertificate(certificate),
          onVerify: () => _verifyCertificate(certificate),
          onDownload: certificate.documentUrl != null 
            ? () => _downloadCertificateDocument(certificate)
            : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: DesignTokens.iconSizeXXL * 2,
            color: DesignTokens.colorGray400,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Geen certificaten gevonden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.darkText,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Voeg je eerste certificaat toe om te beginnen',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingL),
          UnifiedButton(
            text: 'Certificaat Toevoegen',
            type: UnifiedButtonType.primary,
            onPressed: _showAddCertificateDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: DesignTokens.iconSizeXXL * 2,
            color: DesignTokens.colorError,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Er is een fout opgetreden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.colorError,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingL),
          UnifiedButton(
            text: 'Opnieuw Proberen',
            type: UnifiedButtonType.secondary,
            onPressed: _loadCertificates,
          ),
        ],
      ),
    );
  }

  void _handleBlocStateChange(BuildContext context, CertificateState state) {
    setState(() {
      _isLoading = state is CertificateLoading;
      _errorMessage = null;
    });

    if (state is CertificatesLoaded) {
      setState(() {
        _certificates = state.certificates;
      });
    } else if (state is CertificateStatistics) {
      setState(() {
        _statistics = state;
      });
    } else if (state is CertificateOperationSuccess) {
      _loadCertificates(); // Reload after successful operations
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.localizedSuccessMessage),
          backgroundColor: DesignTokens.colorSuccess,
        ),
      );
    } else if (state is CertificateError) {
      setState(() {
        _errorMessage = state.localizedErrorMessage;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.localizedErrorMessage),
          backgroundColor: DesignTokens.colorError,
        ),
      );
    }
  }

  void _loadCertificates() {
    context.read<CertificateBloc>().add(
      CertificateLoadAll(userId: widget.userId),
    );
  }

  void _loadStatistics() {
    context.read<CertificateBloc>().add(
      CertificateGetStatistics(userId: widget.userId),
    );
  }

  List<CertificateData> _getCertificatesByType(CertificateType type) {
    return _certificates.where((cert) => 
      cert.certificateNumber.toUpperCase().startsWith(type.code)).toList();
  }

  void _showAddCertificateDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: CertificateUploadForm(
            onSubmit: _addCertificate,
            onCancel: () => context.pop(),
          ),
        ),
      ),
    );
  }

  void _addCertificate(CertificateFormData formData) {
    context.read<CertificateBloc>().add(
      CertificateAdd(
        userId: widget.userId,
        type: formData.type,
        certificateNumber: formData.certificateNumber,
        holderName: formData.holderName,
        holderBsn: formData.holderBsn,
        issueDate: formData.issueDate,
        expirationDate: formData.expirationDate,
        issuingAuthority: formData.issuingAuthority,
        documentFile: formData.documentFile,
      ),
    );
    context.pop();
  }

  void _showCertificateDetails(CertificateData certificate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CertificateCard(
                certificate: certificate,
                showSecureInfo: true,
                showActions: false,
              ),
              SizedBox(height: DesignTokens.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  UnifiedButton(
                    text: 'Sluiten',
                    type: UnifiedButtonType.secondary,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCertificate(CertificateData certificate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Certificaat Verwijderen'),
        content: Text(
          'Weet je zeker dat je certificaat ${certificate.certificateNumber} wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.read<CertificateBloc>().add(
                CertificateDelete(
                  certificateId: certificate.id,
                  gdprCompliant: true,
                ),
              );
              context.pop();
            },
            child: Text(
              'Verwijderen',
              style: TextStyle(color: DesignTokens.colorError),
            ),
          ),
        ],
      ),
    );
  }

  void _verifyCertificate(CertificateData certificate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: CertificateVerificationWidget(
            initialCertificateNumber: certificate.certificateNumber,
            initialType: certificate.type,
            userId: widget.userId,
            onVerificationSuccess: (result) {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Certificaat succesvol geverifieerd'),
                  backgroundColor: DesignTokens.colorSuccess,
                ),
              );
            },
            onVerificationError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: DesignTokens.colorError,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _downloadCertificateDocument(CertificateData certificate) {
    context.read<CertificateBloc>().add(
      CertificateDownloadDocument(
        certificateId: certificate.id,
        documentPath: certificate.documentUrl!,
      ),
    );
  }
}