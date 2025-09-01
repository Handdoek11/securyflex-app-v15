import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../../unified_input_system.dart';
import '../services/certificate_management_service.dart';

/// Form for uploading and adding new certificates
class CertificateUploadForm extends StatefulWidget {
  final CertificateType? initialType;
  final Function(CertificateFormData) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const CertificateUploadForm({
    super.key,
    this.initialType,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  State<CertificateUploadForm> createState() => _CertificateUploadFormState();
}

class _CertificateUploadFormState extends State<CertificateUploadForm> {
  final _formKey = GlobalKey<FormState>();
  final _certificateNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _holderBsnController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  
  CertificateType _selectedType = CertificateType.wpbr;
  DateTime _issueDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 1095)); // 3 years
  File? _selectedDocument;
  String? _documentError;
  
  final _imagePicker = ImagePicker();
  bool _isProcessingFile = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _updateFormFieldsForType();
  }

  @override
  void dispose() {
    _certificateNumberController.dispose();
    _holderNameController.dispose();
    _holderBsnController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  void _updateFormFieldsForType() {
    // Update default values based on certificate type
    switch (_selectedType) {
      case CertificateType.wpbr:
        _issuingAuthorityController.text = 'Politie Nederland';
        break;
      case CertificateType.vca:
        _issuingAuthorityController.text = 'VCA Nederland';
        break;
      case CertificateType.bhv:
        _issuingAuthorityController.text = 'NIBHV';
        break;
      case CertificateType.ehbo:
        _issuingAuthorityController.text = 'Oranje Kruis';
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  color: DesignTokens.colorPrimaryBlue,
                  size: DesignTokens.iconSizeL,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    'Certificaat toevoegen',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeXL,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.darkText,
                    ),
                  ),
                ),
                if (widget.onCancel != null)
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    iconSize: DesignTokens.iconSizeM,
                  ),
              ],
            ),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Certificate Type Selection
            _buildTypeSelector(),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Certificate Number Input
            _buildCertificateNumberInput(),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Holder Information
            _buildHolderNameInput(),
            
            SizedBox(height: DesignTokens.spacingM),
            
            _buildBsnInput(),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Dates
            Row(
              children: [
                Expanded(child: _buildIssueDatePicker()),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(child: _buildExpirationDatePicker()),
              ],
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Issuing Authority
            _buildIssuingAuthorityInput(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Document Upload Section
            _buildDocumentUploadSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
          decoration: BoxDecoration(
            border: Border.all(color: DesignTokens.colorGray300),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CertificateType>(
              value: _selectedType,
              isExpanded: true,
              items: CertificateType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        color: DesignTokens.colorPrimaryBlue,
                        size: DesignTokens.iconSizeM,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.code,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeM,
                              fontWeight: DesignTokens.fontWeightSemiBold,
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
                    ],
                  ),
                );
              }).toList(),
              onChanged: (CertificateType? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _updateFormFieldsForType();
                  });
                }
              },
            ),
          ),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Certificaatnummer is verplicht';
        }
        if (!_isValidCertificateFormat(value)) {
          return 'Ongeldig ${_selectedType.code} formaat';
        }
        return null;
      },
    );
  }

  Widget _buildHolderNameInput() {
    return UnifiedInput(
      variant: UnifiedInputVariant.outlined,
      controller: _holderNameController,
      label: 'Naam certificaathouder',
      hint: 'Voor- en achternaam',
      prefixIcon: Icons.person_outline,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Naam is verplicht';
        }
        if (value.trim().split(' ').length < 2) {
          return 'Voer voor- en achternaam in';
        }
        return null;
      },
    );
  }

  Widget _buildBsnInput() {
    return UnifiedInput(
      variant: UnifiedInputVariant.outlined,
      controller: _holderBsnController,
      label: 'BSN (optioneel)',
      hint: '123456789',
      prefixIcon: Icons.fingerprint_outlined,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value.length != 9) {
            return 'BSN moet 9 cijfers hebben';
          }
          if (!_isValidBsn(value)) {
            return 'Ongeldig BSN nummer';
          }
        }
        return null;
      },
    );
  }

  Widget _buildIssueDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uitgiftedatum',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        InkWell(
          onTap: () => _selectDate(context, true),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(color: DesignTokens.colorGray300),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: DesignTokens.mutedText,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  DateFormat('dd-MM-yyyy').format(_issueDate),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    color: DesignTokens.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vervaldatum',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        InkWell(
          onTap: () => _selectDate(context, false),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: _expirationDate.isBefore(DateTime.now())
                    ? DesignTokens.colorError
                    : DesignTokens.colorGray300,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: _expirationDate.isBefore(DateTime.now())
                      ? DesignTokens.colorError
                      : DesignTokens.mutedText,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  DateFormat('dd-MM-yyyy').format(_expirationDate),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    color: _expirationDate.isBefore(DateTime.now())
                        ? DesignTokens.colorError
                        : DesignTokens.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuingAuthorityInput() {
    return UnifiedInput(
      variant: UnifiedInputVariant.outlined,
      controller: _issuingAuthorityController,
      label: 'Uitgevende instantie',
      hint: 'Naam van de uitgevende organisatie',
      prefixIcon: Icons.verified_outlined,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Uitgevende instantie is verplicht';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_outlined,
              color: DesignTokens.colorPrimaryBlue,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Text(
              'Certificaatdocument (optioneel)',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.darkText,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        if (_selectedDocument != null) ...[
          _buildDocumentPreview(),
          SizedBox(height: DesignTokens.spacingS),
        ],
        
        Row(
          children: [
            Expanded(
              child: UnifiedButton(
                text: 'Camera',
                type: UnifiedButtonType.secondary,
                onPressed: _isProcessingFile ? null : () { _pickDocument(ImageSource.camera); },
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: UnifiedButton(
                text: 'Galerij',
                type: UnifiedButtonType.secondary,
                onPressed: _isProcessingFile ? null : () { _pickDocument(ImageSource.gallery); },
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: UnifiedButton(
                text: 'Bestanden',
                type: UnifiedButtonType.secondary,
                onPressed: _isProcessingFile ? null : () { _pickFileDocument(); },
              ),
            ),
          ],
        ),
        
        if (_documentError != null) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            _documentError!,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.colorError,
            ),
          ),
        ],
        
        SizedBox(height: DesignTokens.spacingS),
        Text(
          'Ondersteunde formaten: JPG, PNG, PDF (max 10MB)',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: DesignTokens.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPreview() {
    final fileName = _selectedDocument!.path.split('/').last;
    final fileSize = _selectedDocument!.lengthSync();
    final fileSizeText = _formatFileSize(fileSize);
    
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
            _getFileIcon(fileName),
            color: DesignTokens.colorSuccess,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(width: DesignTokens.spacingM),
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
                  fileSizeText,
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
                _selectedDocument = null;
                _documentError = null;
              });
            },
            icon: const Icon(Icons.close),
            iconSize: DesignTokens.iconSizeM,
            color: DesignTokens.mutedText,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.onCancel != null) ...[
          Expanded(
            child: UnifiedButton(
              text: 'Annuleren',
              type: UnifiedButtonType.secondary,
              onPressed: widget.isLoading || widget.onCancel == null ? null : widget.onCancel!,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
        ],
        Expanded(
          flex: 2,
          child: UnifiedButton(
            text: 'Certificaat toevoegen',
            type: UnifiedButtonType.primary,
            onPressed: widget.isLoading ? null : _submitForm,
            isLoading: widget.isLoading,
          ),
        ),
      ],
    );
  }

  // Event handlers
  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _expirationDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      helpText: isIssueDate ? 'Selecteer uitgiftedatum' : 'Selecteer vervaldatum',
      cancelText: 'Annuleren',
      confirmText: 'OK',
    );
    
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  Future<void> _pickDocument(ImageSource source) async {
    setState(() {
      _isProcessingFile = true;
      _documentError = null;
    });

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        
        if (fileSize > 10 * 1024 * 1024) { // 10MB limit
          setState(() {
            _documentError = 'Bestand is te groot (max 10MB)';
          });
        } else {
          setState(() {
            _selectedDocument = file;
          });
        }
      }
    } catch (e) {
      setState(() {
        _documentError = 'Fout bij het selecteren van het bestand';
      });
    } finally {
      setState(() {
        _isProcessingFile = false;
      });
    }
  }

  Future<void> _pickFileDocument() async {
    setState(() {
      _isProcessingFile = true;
      _documentError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        
        if (fileSize > 10 * 1024 * 1024) { // 10MB limit
          setState(() {
            _documentError = 'Bestand is te groot (max 10MB)';
          });
        } else {
          setState(() {
            _selectedDocument = file;
          });
        }
      }
    } catch (e) {
      setState(() {
        _documentError = 'Fout bij het selecteren van het bestand';
      });
    } finally {
      setState(() {
        _isProcessingFile = false;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate expiration date is in the future
      if (_expirationDate.isBefore(DateTime.now())) {
        setState(() {
          // Could add a snackbar or dialog here for better UX
        });
        return;
      }

      final formData = CertificateFormData(
        type: _selectedType,
        certificateNumber: _certificateNumberController.text.trim(),
        holderName: _holderNameController.text.trim(),
        holderBsn: _holderBsnController.text.trim(),
        issueDate: _issueDate,
        expirationDate: _expirationDate,
        issuingAuthority: _issuingAuthorityController.text.trim(),
        documentFile: _selectedDocument,
      );

      widget.onSubmit(formData);
    }
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

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool _isValidCertificateFormat(String value) {
    // Basic validation - in reality you'd use the regex from CertificateManagementService
    return value.startsWith(_selectedType.code) && value.length >= 6;
  }

  bool _isValidBsn(String bsn) {
    // Basic BSN validation using the Dutch BSN algorithm
    if (bsn.length != 9) return false;
    
    int sum = 0;
    for (int i = 0; i < 8; i++) {
      sum += int.parse(bsn[i]) * (9 - i);
    }
    sum -= int.parse(bsn[8]);
    
    return sum % 11 == 0;
  }
}

/// Data class for certificate form submission
class CertificateFormData {
  final CertificateType type;
  final String certificateNumber;
  final String holderName;
  final String holderBsn;
  final DateTime issueDate;
  final DateTime expirationDate;
  final String issuingAuthority;
  final File? documentFile;

  const CertificateFormData({
    required this.type,
    required this.certificateNumber,
    required this.holderName,
    required this.holderBsn,
    required this.issueDate,
    required this.expirationDate,
    required this.issuingAuthority,
    this.documentFile,
  });
}