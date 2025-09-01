import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../../unified_input_system.dart';
import '../bloc/certificate_bloc.dart';
import '../bloc/certificate_event.dart';
import '../bloc/certificate_state.dart';
import '../services/certificate_management_service.dart';

/// Enhanced certificate verification widget with real-time validation,
/// document upload support, and job matching capabilities
class CertificateVerificationWidget extends StatefulWidget {
  final String? initialCertificateNumber;
  final CertificateType? initialType;
  final bool showDocumentUpload;
  final bool showJobMatching;
  final String? userId;
  final String? jobId;
  final Map<String, List<String>>? jobRequirements;
  final Function(CertificateData)? onVerificationSuccess;
  final Function(String)? onVerificationError;

  const CertificateVerificationWidget({
    super.key,
    this.initialCertificateNumber,
    this.initialType,
    this.showDocumentUpload = true,
    this.showJobMatching = false,
    this.userId,
    this.jobId,
    this.jobRequirements,
    this.onVerificationSuccess,
    this.onVerificationError,
  });

  @override
  State<CertificateVerificationWidget> createState() => _CertificateVerificationWidgetState();
}

class _CertificateVerificationWidgetState extends State<CertificateVerificationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _certificateNumberController = TextEditingController();
  
  CertificateType _selectedType = CertificateType.wpbr;
  File? _documentFile;
  bool _isVerifying = false;
  String? _verificationError;
  CertificateData? _verificationResult;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialCertificateNumber != null) {
      _certificateNumberController.text = widget.initialCertificateNumber!;
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _certificateNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateBloc, CertificateState>(
      listener: _handleBlocStateChange,
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: DesignTokens.spacingL),
              
              _buildTypeSelector(),
              SizedBox(height: DesignTokens.spacingM),
              
              _buildCertificateNumberInput(),
              SizedBox(height: DesignTokens.spacingM),
              
              if (widget.showDocumentUpload) ...[
                _buildDocumentUploadSection(),
                SizedBox(height: DesignTokens.spacingM),
              ],
              
              _buildVerificationButton(),
              
              if (_verificationResult != null) ...[
                SizedBox(height: DesignTokens.spacingL),
                _buildVerificationResult(),
              ],
              
              if (widget.showJobMatching && _verificationResult != null) ...[
                SizedBox(height: DesignTokens.spacingL),
                _buildJobMatchingSection(),
              ],
              
              if (_verificationError != null) ...[
                SizedBox(height: DesignTokens.spacingM),
                _buildErrorDisplay(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: DesignTokens.colorPrimaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.verified_outlined,
            color: DesignTokens.colorPrimaryBlue,
            size: DesignTokens.iconSizeL,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificaat Verificatie',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                'Controleer de geldigheid van beveiligingscertificaten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificaattype',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingXS,
          children: CertificateType.values.map((type) {
            final isSelected = _selectedType == type;
            
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedType = type;
                  _verificationResult = null;
                  _verificationError = null;
                });
              },
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? DesignTokens.colorPrimaryBlue
                    : DesignTokens.colorGray100,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: isSelected 
                      ? DesignTokens.colorPrimaryBlue
                      : DesignTokens.colorGray300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: DesignTokens.iconSizeS,
                      color: isSelected 
                        ? DesignTokens.colorWhite
                        : DesignTokens.colorPrimaryBlue,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      type.code,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: isSelected 
                          ? DesignTokens.colorWhite
                          : DesignTokens.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificateNumberInput() {
    return UnifiedInput(
      variant: UnifiedInputVariant.outlined,
      controller: _certificateNumberController,
      label: 'Certificaatnummer',
      hint: '${_selectedType.code}-123456',
      prefixIcon: Icons.badge_outlined,
      onChanged: (_) {
        setState(() {
          _verificationResult = null;
          _verificationError = null;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Certificaatnummer is verplicht';
        }
        if (!_selectedType.validationPattern.hasMatch(value.toUpperCase())) {
          return 'Ongeldig ${_selectedType.code} formaat';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document (optioneel)',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        if (_documentFile != null) 
          _buildDocumentPreview()
        else
          UnifiedButton(
            text: 'Document selecteren',
            type: UnifiedButtonType.secondary,
            size: UnifiedButtonSize.small,
            onPressed: _pickDocument,
          ),
      ],
    );
  }

  Widget _buildDocumentPreview() {
    final fileName = _documentFile!.path.split('/').last;
    final fileSize = _documentFile!.lengthSync();
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            color: DesignTokens.colorSuccess,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.darkText,
                  ),
                ),
                Text(
                  _formatFileSize(fileSize),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _documentFile = null;
              });
            },
            icon: const Icon(Icons.close),
            iconSize: DesignTokens.iconSizeS,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationButton() {
    return SizedBox(
      width: double.infinity,
      child: UnifiedButton(
        text: 'Certificaat Verifiëren',
        type: UnifiedButtonType.primary,
        onPressed: _isVerifying ? null : _verifyCertificate,
        isLoading: _isVerifying,
      ),
    );
  }

  Widget _buildVerificationResult() {
    if (_verificationResult == null) return const SizedBox.shrink();

    final isValid = _verificationResult!.isCurrentlyValid;
    final statusColor = isValid ? DesignTokens.colorSuccess : DesignTokens.colorError;
    final dateFormat = DateFormat('dd-MM-yyyy');

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: statusColor,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                isValid ? 'Certificaat Geldig' : 'Certificaat Ongeldig',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          _buildInfoRow('Nummer', _verificationResult!.certificateNumber),
          _buildInfoRow('Houder', _verificationResult!.holderName),
          _buildInfoRow('Autoriteit', _verificationResult!.issuingAuthority),
          _buildInfoRow('Uitgiftedatum', dateFormat.format(_verificationResult!.issueDate)),
          _buildInfoRow('Vervaldatum', dateFormat.format(_verificationResult!.expirationDate)),
          
          if (_verificationResult!.authorizations.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Bevoegdheden:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.darkText,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Wrap(
              spacing: DesignTokens.spacingXS,
              runSpacing: DesignTokens.spacingXS,
              children: _verificationResult!.authorizations.map((auth) => 
                Chip(
                  label: Text(
                    auth,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: DesignTokens.colorWhite,
                    ),
                  ),
                  backgroundColor: DesignTokens.colorPrimaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobMatchingSection() {
    if (widget.jobRequirements == null || widget.jobId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work_outline,
              color: DesignTokens.colorPrimaryBlue,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Text(
              'Job Geschiktheid',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.darkText,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        UnifiedButton(
          text: 'Controleer Geschiktheid',
          type: UnifiedButtonType.secondary,
          size: UnifiedButtonSize.small,
          onPressed: _checkJobEligibility,
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              _verificationError!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBlocStateChange(BuildContext context, CertificateState state) {
    setState(() {
      _isVerifying = state is CertificateLoading;
    });

    if (state is CertificateWPBRVerified) {
      setState(() {
        _verificationResult = CertificateData(
          id: 'verified_${DateTime.now().millisecondsSinceEpoch}',
          type: _selectedType,
          number: state.certificateNumber,
          holderName: 'Gecontroleerde gebruiker', // Would come from verification
          issueDate: DateTime.now().subtract(const Duration(days: 365)),
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          status: state.isValid ? CertificateStatus.valid : CertificateStatus.expired,
          issuingAuthority: state.issuingAuthority,
          competencies: state.authorizations,
          lastVerified: state.verifiedAt,
        );
        _verificationError = null;
      });
      
      widget.onVerificationSuccess?.call(_verificationResult!);
      
    } else if (state is CertificateError) {
      setState(() {
        _verificationError = state.localizedErrorMessage;
        _verificationResult = null;
      });
      
      widget.onVerificationError?.call(state.localizedErrorMessage);
    }
  }

  void _verifyCertificate() {
    if (_formKey.currentState?.validate() ?? false) {
      final certificateNumber = _certificateNumberController.text.trim().toUpperCase();
      
      if (widget.userId == null) {
        setState(() {
          _verificationError = 'Gebruiker moet ingelogd zijn voor verificatie';
        });
        return;
      }

      if (_selectedType == CertificateType.wpbr) {
        context.read<CertificateBloc>().add(
          CertificateVerifyWPBRWithDocument(
            userId: widget.userId!,
            certificateNumber: certificateNumber,
            documentFile: _documentFile,
          ),
        );
      } else {
        context.read<CertificateBloc>().add(
          CertificateVerify(
            certificateNumber: certificateNumber,
            type: _selectedType,
          ),
        );
      }
    }
  }

  void _checkJobEligibility() {
    if (widget.userId == null || widget.jobId == null || widget.jobRequirements == null) {
      return;
    }

    context.read<CertificateBloc>().add(
      CertificateCheckJobEligibility(
        userId: widget.userId!,
        jobId: widget.jobId!,
        jobRequirements: widget.jobRequirements!,
      ),
    );
  }

  void _pickDocument() {
    // This would open a file picker
    // For now, we'll simulate document selection
    setState(() {
      _documentFile = File('/path/to/mock/document.pdf');
    });
  }

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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}