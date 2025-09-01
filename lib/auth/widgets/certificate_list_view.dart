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

/// ListView widget for displaying certificates with filtering and sorting
class CertificateListView extends StatefulWidget {
  final String userId;
  final CertificateType? filterType;
  final String? searchQuery;
  final bool showActions;
  final bool showSecureInfo;
  final Function(CertificateData)? onCertificateTap;
  final Function(CertificateData)? onCertificateEdit;
  final Function(CertificateData)? onCertificateDelete;
  final Function(CertificateData)? onCertificateVerify;
  final Widget? emptyStateWidget;
  final Widget? errorWidget;

  const CertificateListView({
    super.key,
    required this.userId,
    this.filterType,
    this.searchQuery,
    this.showActions = true,
    this.showSecureInfo = false,
    this.onCertificateTap,
    this.onCertificateEdit,
    this.onCertificateDelete,
    this.onCertificateVerify,
    this.emptyStateWidget,
    this.errorWidget,
  });

  @override
  State<CertificateListView> createState() => _CertificateListViewState();
}

class _CertificateListViewState extends State<CertificateListView> {
  CertificateSortOption _sortOption = CertificateSortOption.expirationDate;
  bool _sortAscending = true;
  bool _showExpiredCertificates = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void didUpdateWidget(CertificateListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.filterType != widget.filterType ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadCertificates();
    }
  }

  void _loadCertificates() {
    if (widget.filterType != null) {
      context.read<CertificateBloc>().add(CertificateLoadByType(
        userId: widget.userId,
        type: widget.filterType!,
      ));
    } else {
      context.read<CertificateBloc>().add(CertificateLoadAll(
        userId: widget.userId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CertificateBloc, CertificateState>(
      builder: (context, state) {
        return Column(
          children: [
            // Controls and sorting
            _buildControlsSection(),
            SizedBox(height: DesignTokens.spacingM),
            
            // Certificate list
            Expanded(
              child: _buildCertificateList(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlsSection() {
    return UnifiedCard(
      variant: UnifiedCardVariant.compact,
      child: Column(
        children: [
          // Sort and filter controls
          Row(
            children: [
              Expanded(
                child: _buildSortDropdown(),
              ),
              SizedBox(width: DesignTokens.spacingM),
              _buildSortOrderButton(),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          
          // Filter toggles
          Row(
            children: [
              Expanded(
                child: _buildExpiredToggle(),
              ),
              SizedBox(width: DesignTokens.spacingM),
              UnifiedButton.secondary(
                text: 'Vernieuwen',
                onPressed: _loadCertificates,
                size: UnifiedButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.colorGray300),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CertificateSortOption>(
          value: _sortOption,
          isExpanded: true,
          items: CertificateSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option.displayName,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  color: DesignTokens.darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (CertificateSortOption? value) {
            if (value != null) {
              setState(() {
                _sortOption = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSortOrderButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _sortAscending = !_sortAscending;
        });
      },
      icon: Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        color: DesignTokens.colorPrimaryBlue,
      ),
      tooltip: _sortAscending ? 'Oplopend' : 'Aflopend',
    );
  }

  Widget _buildExpiredToggle() {
    return Row(
      children: [
        Switch(
          value: _showExpiredCertificates,
          onChanged: (value) {
            setState(() {
              _showExpiredCertificates = value;
            });
          },
          activeThumbColor: DesignTokens.colorPrimaryBlue,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            'Toon verlopen certificaten',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.darkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateList(CertificateState state) {
    if (state is CertificateLoading) {
      return _buildLoadingState(state);
    }
    
    if (state is CertificateError) {
      return widget.errorWidget ?? _buildErrorState(state);
    }
    
    if (state is CertificatesLoaded) {
      return _buildLoadedState(state);
    }

    if (state is CertificateSearchResults) {
      return _buildSearchResults(state);
    }
    
    return _buildEmptyState();
  }

  Widget _buildLoadingState(CertificateLoading state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            state.localizedLoadingMessage,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CertificateError state) {
    return Center(
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.iconSizeXXL,
              color: DesignTokens.colorError,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Fout bij laden certificaten',
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
            SizedBox(height: DesignTokens.spacingM),
            UnifiedButton.primary(
              text: 'Opnieuw proberen',
              onPressed: _loadCertificates,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(CertificatesLoaded state) {
    var filteredCertificates = state.certificates;
    
    // Apply search filter
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      filteredCertificates = filteredCertificates.where((cert) =>
        cert.certificateNumber.toLowerCase().contains(query) ||
        cert.holderName.toLowerCase().contains(query) ||
        cert.issuingAuthority.toLowerCase().contains(query)
      ).toList();
    }
    
    // Apply expired filter
    if (!_showExpiredCertificates) {
      filteredCertificates = filteredCertificates.where((cert) => 
        !cert.isExpired
      ).toList();
    }
    
    // Sort certificates
    _sortCertificates(filteredCertificates);
    
    if (filteredCertificates.isEmpty) {
      return widget.emptyStateWidget ?? _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadCertificates();
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(DesignTokens.spacingS),
        itemCount: filteredCertificates.length,
        separatorBuilder: (context, index) => SizedBox(height: DesignTokens.spacingS),
        itemBuilder: (context, index) {
          final certificate = filteredCertificates[index];
          return CertificateCard(
            certificate: certificate,
            showActions: widget.showActions,
            showSecureInfo: widget.showSecureInfo,
            onTap: widget.onCertificateTap != null
                ? () => widget.onCertificateTap!(certificate)
                : null,
            onEdit: widget.onCertificateEdit != null
                ? () => widget.onCertificateEdit!(certificate)
                : null,
            onDelete: widget.onCertificateDelete != null
                ? () => _showDeleteConfirmation(certificate)
                : null,
            onVerify: widget.onCertificateVerify != null
                ? () => widget.onCertificateVerify!(certificate)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(CertificateSearchResults state) {
    var filteredResults = state.results;
    
    // Apply expired filter
    if (!_showExpiredCertificates) {
      filteredResults = filteredResults.where((cert) => 
        !cert.isExpired
      ).toList();
    }
    
    // Sort certificates
    _sortCertificates(filteredResults);
    
    if (filteredResults.isEmpty) {
      return _buildEmptySearchState();
    }
    
    return Column(
      children: [
        // Search results header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Text(
            '${filteredResults.length} certificaten gevonden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.mutedText,
            ),
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            itemCount: filteredResults.length,
            separatorBuilder: (context, index) => SizedBox(height: DesignTokens.spacingS),
            itemBuilder: (context, index) {
              final certificate = filteredResults[index];
              return CertificateCard(
                certificate: certificate,
                showActions: widget.showActions,
                showSecureInfo: widget.showSecureInfo,
                onTap: widget.onCertificateTap != null
                    ? () => widget.onCertificateTap!(certificate)
                    : null,
                onEdit: widget.onCertificateEdit != null
                    ? () => widget.onCertificateEdit!(certificate)
                    : null,
                onDelete: widget.onCertificateDelete != null
                    ? () => _showDeleteConfirmation(certificate)
                    : null,
                onVerify: widget.onCertificateVerify != null
                    ? () => widget.onCertificateVerify!(certificate)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: DesignTokens.iconSizeXXL * 1.5,
              color: DesignTokens.colorGray400,
            ),
            SizedBox(height: DesignTokens.spacingM),
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
              widget.filterType != null
                  ? 'Je hebt nog geen ${widget.filterType!.dutchName} certificaten'
                  : 'Je hebt nog geen certificaten toegevoegd',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: DesignTokens.iconSizeXXL * 1.5,
              color: DesignTokens.colorGray400,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Geen resultaten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.darkText,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Geen certificaten gevonden die voldoen aan je zoekopdracht',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortCertificates(List<CertificateData> certificates) {
    certificates.sort((a, b) {
      int comparison = 0;
      
      switch (_sortOption) {
        case CertificateSortOption.certificateNumber:
          comparison = a.certificateNumber.compareTo(b.certificateNumber);
          break;
        case CertificateSortOption.holderName:
          comparison = a.holderName.compareTo(b.holderName);
          break;
        case CertificateSortOption.issueDate:
          comparison = a.issueDate.compareTo(b.issueDate);
          break;
        case CertificateSortOption.expirationDate:
          comparison = a.expirationDate.compareTo(b.expirationDate);
          break;
        case CertificateSortOption.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case CertificateSortOption.issuingAuthority:
          comparison = a.issuingAuthority.compareTo(b.issuingAuthority);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _showDeleteConfirmation(CertificateData certificate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificaat verwijderen'),
        content: Text(
          'Weet je zeker dat je certificaat ${certificate.certificateNumber} wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              widget.onCertificateDelete!(certificate);
            },
            style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
  }
}

/// Sort options for certificate list
enum CertificateSortOption {
  certificateNumber('Certificaatnummer'),
  holderName('Naam houder'),
  issueDate('Uitgiftedatum'),
  expirationDate('Vervaldatum'),
  status('Status'),
  issuingAuthority('Uitgevende instantie');

  const CertificateSortOption(this.displayName);
  final String displayName;
}