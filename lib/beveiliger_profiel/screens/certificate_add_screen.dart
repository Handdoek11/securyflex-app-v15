import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:securyflex_app/auth/services/certificate_management_service.dart';
import 'package:securyflex_app/auth/services/wpbr_verification_service.dart';
import 'package:securyflex_app/auth/auth_service.dart';

/// Certificate Add Screen met WPBR verification flow
/// 
/// MANDATORY usage van:
/// - UnifiedHeader.simple with back navigation
/// - Existing WPBR verification flow
/// - UnifiedInput for certificate number input  
/// - Existing file picker for certificate upload
/// - Integration with WPBRVerificationService.verifyCertificate
/// - Dutch labels and validation messages
/// - Progress indicators during verification
class CertificateAddScreen extends StatefulWidget {
  final String userId;
  final UserRole userRole;
  
  const CertificateAddScreen({
    super.key,
    required this.userId,
    this.userRole = UserRole.guard,
  });

  @override
  State<CertificateAddScreen> createState() => _CertificateAddScreenState();
}

class _CertificateAddScreenState extends State<CertificateAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _certificateNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _holderBsnController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  final CertificateManagementService _certificateService = CertificateManagementService();
  
  CertificateType _selectedType = CertificateType.wpbr;
  DateTime _issueDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 1460)); // 4 years
  File? _documentFile;
  
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _verificationMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Pre-fill holder name if available
    if (AuthService.isLoggedIn && AuthService.currentUserType == 'GUARD') {
      // In real implementation, get from user profile
      _holderNameController.text = '';
    }
    
    // Set default dates based on certificate type
    _updateDatesForCertificateType();
  }

  void _updateDatesForCertificateType() {
    final now = DateTime.now();
    final validityYears = _selectedType.validityYears;
    
    setState(() {
      _issueDate = now.subtract(const Duration(days: 365));
      _expiryDate = now.add(Duration(days: validityYears * 365));
    });
  }

  @override
  void dispose() {
    _certificateNumberController.dispose();
    _holderNameController.dispose();
    _holderBsnController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
            // Header
            UnifiedHeader.simple(
              title: 'Certificaat Toevoegen',
              userRole: widget.userRole,
              titleAlignment: TextAlign.left,
              leading: HeaderElements.backButton(
                userRole: widget.userRole,
                onPressed: () => context.pop(),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Certificate type selection
                      _buildCertificateTypeSelector(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Certificate number input
                      _buildCertificateNumberField(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingM),
                      
                      // Verification status
                      if (_verificationMessage != null)
                        _buildVerificationStatus(colorScheme),
                      
                      if (_errorMessage != null)
                        _buildErrorMessage(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Holder information
                      _buildHolderInformation(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Date fields
                      _buildDateFields(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Document upload
                      _buildDocumentUpload(colorScheme),
                      
                      SizedBox(height: DesignTokens.spacingXL),
                      
                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCertificateTypeSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificaattype',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: CertificateType.values.map((type) {
            final isSelected = _selectedType == type;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                  _updateDatesForCertificateType();
                  _verificationMessage = null;
                  _errorMessage = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getCertificateIcon(type),
                      size: DesignTokens.iconSizeL,
                      color: isSelected 
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      type.code,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: isSelected 
                            ? DesignTokens.fontWeightSemiBold
                            : DesignTokens.fontWeightRegular,
                        color: isSelected 
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${type.validityYears} jaar geldig',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: colorScheme.onSurfaceVariant,
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

  Widget _buildCertificateNumberField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedInput(
          controller: _certificateNumberController,
          label: 'Certificaatnummer',
          hint: 'Bijv. ${_getExampleNumber()}',
          keyboardType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Voer het certificaatnummer in';
            }
            
            if (!_selectedType.validationPattern.hasMatch(value)) {
              return 'Ongeldig ${_selectedType.code} nummer format';
            }
            
            return null;
          },
          onChanged: (value) {
            // Auto-verify WPBR certificates on input
            if (_selectedType == CertificateType.wpbr && 
                value.length >= 10 && 
                _selectedType.validationPattern.hasMatch(value)) {
              _verifyWPBRCertificate(value);
            }
          },
          suffixIcon: _isVerifying
              ? Icons.hourglass_empty
              : (_selectedType == CertificateType.wpbr 
                  ? Icons.search
                  : null),
        ),
        
        if (_selectedType == CertificateType.wpbr)
          Padding(
            padding: EdgeInsets.only(top: DesignTokens.spacingS),
            child: Text(
              'WPBR certificaten worden automatisch geverifieerd',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerificationStatus(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
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
            Icons.check_circle,
            color: DesignTokens.colorSuccess,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              _verificationMessage!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorSuccess,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
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
            Icons.error,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeM,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorError,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolderInformation(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Houder Informatie',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        
        UnifiedInput(
          controller: _holderNameController,
          label: 'Naam houder',
          hint: 'Volledige naam zoals op certificaat',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Voer de naam van de houder in';
            }
            return null;
          },
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        UnifiedInput(
          controller: _holderBsnController,
          label: 'BSN (optioneel)',
          hint: 'Burgerservicenummer',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length != 9) {
              return 'BSN moet 9 cijfers bevatten';
            }
            return null;
          },
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        UnifiedInput(
          controller: _issuingAuthorityController,
          label: 'Uitgevende instantie',
          hint: 'Bijv. Politie Eenheid Amsterdam',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Voer de uitgevende instantie in';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateFields(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geldigheid',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Uitgiftedatum',
                _issueDate,
                (date) => setState(() => _issueDate = date),
                colorScheme,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildDateField(
                'Vervaldatum',
                _expiryDate,
                (date) => setState(() => _expiryDate = date),
                colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime) onChanged, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
        );
        
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: DesignTokens.iconSizeM,
                  color: colorScheme.primary,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Upload',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        
        GestureDetector(
          onTap: _pickDocument,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Column(
              children: [
                Icon(
                  _documentFile != null ? Icons.description : Icons.upload_file,
                  size: DesignTokens.iconSizeXL,
                  color: _documentFile != null 
                      ? DesignTokens.colorSuccess
                      : colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  _documentFile != null 
                      ? 'Document geselecteerd'
                      : 'Tik om certificaatdocument te uploaden',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: _documentFile != null 
                        ? DesignTokens.colorSuccess
                        : colorScheme.onSurfaceVariant,
                    fontWeight: _documentFile != null 
                        ? DesignTokens.fontWeightMedium
                        : DesignTokens.fontWeightRegular,
                  ),
                ),
                if (_documentFile != null) ...[
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    _documentFile!.path.split('/').last,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: UnifiedButton.primary(
            text: _isLoading ? 'Certificaat toevoegen...' : 'Certificaat toevoegen',
            onPressed: _handleAddCertificate,
            size: UnifiedButtonSize.large,
            isLoading: _isLoading,
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        SizedBox(
          width: double.infinity,
          child: UnifiedButton.secondary(
            text: 'Annuleren',
            onPressed: _handleCancel,
            size: UnifiedButtonSize.large,
          ),
        ),
      ],
    );
  }

  Future<void> _verifyWPBRCertificate(String certificateNumber) async {
    if (certificateNumber.isEmpty || _isVerifying) return;
    
    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
      _errorMessage = null;
    });

    try {
      final result = await WPBRVerificationService.verifyCertificate(
        certificateNumber,
        userId: widget.userId,
      );

      if (mounted) {
        if (result.isSuccess && result.data != null) {
          // Auto-fill form with verified data
          final wpbrData = result.data;
          _holderNameController.text = wpbrData.holderName ?? '';
          _issuingAuthorityController.text = wpbrData.issuingAuthority ?? '';
          
          if (wpbrData.issueDate != null) {
            _issueDate = wpbrData.issueDate;
          }
          if (wpbrData.expirationDate != null) {
            _expiryDate = wpbrData.expirationDate;
          }

          setState(() {
            _verificationMessage = 'WPBR certificaat succesvol geverifieerd';
            _isVerifying = false;
          });
        } else {
          setState(() {
            _errorMessage = result.message;
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verificatie mislukt: $e';
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file != null) {
        setState(() {
          _documentFile = File(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij selecteren document: $e'),
            backgroundColor: DesignTokens.colorError,
          ),
        );
      }
    }
  }

  void _handleAddCertificate() {
    if (!_isLoading) {
      _addCertificate();
    }
  }

  void _handleCancel() {
    if (!_isLoading) {
      context.pop();
    }
  }

  Future<void> _addCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _certificateService.addCertificate(
        userId: widget.userId,
        type: _selectedType,
        certificateNumber: _certificateNumberController.text.trim(),
        holderName: _holderNameController.text.trim(),
        holderBsn: _holderBsnController.text.trim(),
        issueDate: _issueDate,
        expirationDate: _expiryDate,
        issuingAuthority: _issuingAuthorityController.text.trim(),
        documentFile: _documentFile,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: DesignTokens.colorSuccess,
            ),
          );
          context.pop(true); // Return success
        } else {
          setState(() {
            _errorMessage = result.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij toevoegen certificaat: $e';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getCertificateIcon(CertificateType type) {
    switch (type) {
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

  String _getExampleNumber() {
    switch (_selectedType) {
      case CertificateType.wpbr:
        return 'WPBR-123456';
      case CertificateType.vca:
        return 'VCA-12345678';
      case CertificateType.bhv:
        return 'BHV-1234567';
      case CertificateType.ehbo:
        return 'EHBO-123456';
      }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}