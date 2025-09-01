import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:securyflex_app/beveiliger_profiel/bloc/profiel_edit_bloc.dart';
import 'package:securyflex_app/beveiliger_profiel/models/beveiliger_profiel_data.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/profile_image_widget.dart';
import 'package:securyflex_app/auth/auth_service.dart';

/// Profiel Edit Screen met unified components
/// 
/// VERPLICHT gebruik van:
/// - UnifiedHeader.simple met back button en save action
/// - UnifiedInput voor alle form velden
/// - DesignTokens.spacingM tussen form velden
/// - UnifiedButton.primary voor save, UnifiedButton.secondary voor cancel
/// - SecuryFlexTheme.getColorScheme(UserRole.guard) throughout
class ProfielEditScreen extends StatefulWidget {
  final BeveiligerProfielData initialProfileData;

  const ProfielEditScreen({
    super.key,
    required this.initialProfileData,
  });

  @override
  State<ProfielEditScreen> createState() => _ProfielEditScreenState();
}

class _ProfielEditScreenState extends State<ProfielEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers voor alle form velden
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _kvkController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _wpbrController;

  // Focus nodes voor navigation
  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _phoneFocusNode;
  late final FocusNode _bioFocusNode;
  late final FocusNode _kvkFocusNode;
  late final FocusNode _postalCodeFocusNode;
  late final FocusNode _wpbrFocusNode;

  // Selected specialisaties en certificaten
  List<String> _selectedSpecialisaties = [];
  List<String> _selectedCertificaten = [];
  
  // Profile image
  String? _newProfileImageUrl;
  File? _selectedImageFile;

  // Dirty tracking
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFocusNodes();
    _loadInitialData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _kvkController = TextEditingController();
    _postalCodeController = TextEditingController();
    _wpbrController = TextEditingController();

    // Add listeners voor dirty tracking
    for (final controller in [
      _nameController, _emailController, _phoneController, _bioController,
      _kvkController, _postalCodeController, _wpbrController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _initializeFocusNodes() {
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _bioFocusNode = FocusNode();
    _kvkFocusNode = FocusNode();
    _postalCodeFocusNode = FocusNode();
    _wpbrFocusNode = FocusNode();
  }

  void _loadInitialData() {
    _nameController.text = widget.initialProfileData.name;
    _emailController.text = widget.initialProfileData.email;
    _phoneController.text = widget.initialProfileData.phone ?? '';
    _bioController.text = widget.initialProfileData.bio ?? '';
    _kvkController.text = widget.initialProfileData.kvkNumber ?? '';
    _postalCodeController.text = widget.initialProfileData.postalCode ?? '';
    _wpbrController.text = widget.initialProfileData.wpbrNumber ?? '';
    
    _selectedSpecialisaties = List.from(widget.initialProfileData.specialisaties);
    _selectedCertificaten = List.from(widget.initialProfileData.certificaten);
    _newProfileImageUrl = widget.initialProfileData.profileImageUrl;
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _kvkController.dispose();
    _postalCodeController.dispose();
    _wpbrController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _bioFocusNode.dispose();
    _kvkFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _wpbrFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges) {
          await _showUnsavedChangesDialog();
        }
      },
      child: SafeArea(
        child: UnifiedBackgroundService.guardMeshGradient(
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
              // VERPLICHT: UnifiedHeader.simple met back button en save action
              UnifiedHeader.simple(
                title: 'Profiel Bewerken',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.left,
                leading: HeaderElements.backButton(
                  userRole: UserRole.guard,
                  onPressed: () => _handleBackPressed(),
                ),
                actions: [
                  HeaderElements.actionButton(
                    icon: Icons.check,
                    onPressed: _hasUnsavedChanges ? () => _saveProfile() : () {},
                    userRole: UserRole.guard,
                  ),
                ],
              ),
              
              // Content area
              Expanded(
                child: BlocConsumer<ProfielEditBloc, ProfielEditState>(
                  listener: (context, state) {
                    if (state is EditError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error.localizedMessage),
                          backgroundColor: colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is EditSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.successMessage),
                          backgroundColor: DesignTokens.colorSuccess,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      // Navigate back na succesvol opslaan
                      context.pop(true);
                    } else if (state is ImageUploaded) {
                      setState(() {
                        _newProfileImageUrl = state.imageUrl;
                        _selectedImageFile = null;
                        _hasUnsavedChanges = true;
                      });
                    }
                  },
                  builder: (context, state) {
                    if (state is EditLoading) {
                      return _buildLoadingState(state);
                    }
                    return _buildEditForm();
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(EditLoading state) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3.0,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            state.loadingMessage ?? 'Bezig met laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image section
            _buildProfileImageSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Persoonlijke gegevens section
            _buildPersonalInfoSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Contact gegevens section
            _buildContactInfoSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Professionele gegevens section
            _buildProfessionalInfoSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Specialisaties section
            _buildSpecialisatiesSection(),
            
            SizedBox(height: DesignTokens.spacingL),
            
            // Certificaten section
            _buildCertificatenSection(),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            // Save/Cancel buttons
            _buildActionButtons(),
            
            SizedBox(height: DesignTokens.spacingL), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Profielfoto',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content
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
              child: Center(
                child: ProfileImageWidget(
                  imageUrl: _newProfileImageUrl,
                  imageFile: _selectedImageFile,
                  onImageSelected: _handleImageSelected,
                  userRole: UserRole.guard,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Persoonlijke Gegevens',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content
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
          
          // Naam field
          UnifiedInput.standard(
            label: 'Volledige Naam',
            controller: _nameController,
            hint: 'Voor- en achternaam',
            isRequired: true,
            validator: (value) => _validateRequired(value, 'Naam'),
            userRole: UserRole.guard,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Email field
          UnifiedInput.email(
            label: 'E-mailadres',
            controller: _emailController,
            isRequired: true,
            validator: _validateEmail,
            userRole: UserRole.guard,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Bio field
          UnifiedInput.multiline(
            label: 'Bio / Beschrijving',
            controller: _bioController,
            hint: 'Vertel kort over jezelf, je ervaring en specialiteiten...',
            maxLines: 4,
            maxLength: 500,
            validator: _validateBio,
            userRole: UserRole.guard,
          ),
        ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Contact Gegevens',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content
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
                  // Phone field
                  UnifiedInput(
                    variant: UnifiedInputVariant.phone,
                    label: 'Telefoonnummer',
                    controller: _phoneController,
                    hint: '+31 6 12 34 56 78',
                    validator: _validatePhone,
                    userRole: UserRole.guard,
                  ),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Postal code field
                  UnifiedInput.standard(
                    label: 'Postcode',
                    controller: _postalCodeController,
                    hint: '1234AB',
                    validator: _validatePostalCode,
                    userRole: UserRole.guard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Professionele Gegevens',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content
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
                  // KvK field
                  UnifiedInput.standard(
                    label: 'KvK Nummer (optioneel)',
                    controller: _kvkController,
                    hint: '12345678',
                    helperText: 'Alleen bij eigen bedrijf',
                    validator: _validateKvK,
                    userRole: UserRole.guard,
                  ),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // WPBR field
                  UnifiedInput.standard(
                    label: 'WPBR Certificaatnummer',
                    controller: _wpbrController,
                    hint: 'WPBR-123456',
                    helperText: 'Verplicht voor beveiligers',
                    validator: _validateWPBR,
                    userRole: UserRole.guard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialisatiesSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Specialisaties',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Glass container with content
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
                  // Header with counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Selecteer je specialiteiten',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedSpecialisaties.length >= 6
                              ? colorScheme.error.withValues(alpha: 0.1)
                              : colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Text(
                          '${_selectedSpecialisaties.length}/6 geselecteerd',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeCaption,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: _selectedSpecialisaties.length >= 6
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Organized chip grid
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 280, // Limit height to prevent excessive scrolling
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: DesignTokens.spacingXS,
                        runSpacing: DesignTokens.spacingXS,
                        children: BeveiligerSpecialisaties.available.map((specialisatie) {
                          final isSelected = _selectedSpecialisaties.contains(specialisatie);
                          final isDisabled = !isSelected && _selectedSpecialisaties.length >= 6;
                          
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            child: InkWell(
                              onTap: isDisabled ? null : () => _toggleSpecialisatie(specialisatie),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: DesignTokens.spacingM,
                                  vertical: DesignTokens.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary.withValues(alpha: 0.2)
                                      : isDisabled
                                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                          : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : isDisabled
                                            ? colorScheme.outline.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(
                                        Icons.check,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      SizedBox(width: DesignTokens.spacingXS),
                                    ],
                                    Text(
                                      specialisatie,
                                      style: TextStyle(
                                        fontSize: DesignTokens.fontSizeBody,
                                        fontWeight: isSelected ? DesignTokens.fontWeightMedium : DesignTokens.fontWeightRegular,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : isDisabled
                                                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                                : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  // Helper text
                  if (_selectedSpecialisaties.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: DesignTokens.spacingS),
                      child: Text(
                        'Kies minimaal 1 specialisatie om je profiel compleet te maken',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificatenSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        // Glass container with content
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
                  // Header with counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Selecteer je behaalde certificaten',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Text(
                          '${_selectedCertificaten.length} geselecteerd',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeCaption,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Organized certificate grid with categories
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 320, // Slightly larger for certificates
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Essential certificates (WPBR, BHV, EHBO)
                          _buildCertificateGroup(
                            'Essentiële Certificaten',
                            [
                              'WPBR Certificaat',
                              'BHV Diploma',
                              'EHBO Certificaat',
                              'AED Certificaat',
                            ],
                            colorScheme,
                            Icons.verified_user,
                          ),
                          SizedBox(height: DesignTokens.spacingM),
                          
                          // Safety certificates
                          _buildCertificateGroup(
                            'Veiligheid & Training',
                            [
                              'Security Awareness Training',
                              'VCA Veiligheid Certificaat',
                              'Fire Safety Certificate',
                              'Emergency Response Certificate',
                              'Risk Assessment Certificate',
                            ],
                            colorScheme,
                            Icons.security,
                          ),
                          SizedBox(height: DesignTokens.spacingM),
                          
                          // Specialized certificates
                          _buildCertificateGroup(
                            'Specialistische Certificaten',
                            [
                              'Crowd Management Certificate',
                              'Preventie Medewerker Certificaat',
                              'Surveillance Certificate',
                              'Access Control Training',
                              'Communication Skills Training',
                              'Conflict De-escalation Training',
                            ],
                            colorScheme,
                            Icons.workspace_premium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Helper text for WPBR requirement
                  if (!_selectedCertificaten.contains('WPBR Certificaat'))
                    Container(
                      margin: EdgeInsets.only(top: DesignTokens.spacingM),
                      padding: EdgeInsets.all(DesignTokens.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: colorScheme.error,
                          ),
                          SizedBox(width: DesignTokens.spacingXS),
                          Expanded(
                            child: Text(
                              'WPBR certificaat is verplicht voor beveiligers',
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeCaption,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: UnifiedButton.secondary(
            text: 'Annuleren',
            onPressed: _handleBackPressed,
            size: UnifiedButtonSize.large,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: UnifiedButton.primary(
            text: 'Opslaan',
            onPressed: _hasUnsavedChanges ? () => _saveProfile() : () {},
            size: UnifiedButtonSize.large,
          ),
        ),
      ],
    );
  }

  // Helper method for certificate groups
  Widget _buildCertificateGroup(
    String title,
    List<String> certificates,
    ColorScheme colorScheme,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        
        // Certificate chips
        Wrap(
          spacing: DesignTokens.spacingXS,
          runSpacing: DesignTokens.spacingXS,
          children: certificates.map((certificaat) {
            final isSelected = _selectedCertificaten.contains(certificaat);
            final isWPBR = certificaat == 'WPBR Certificaat';
            
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: InkWell(
                onTap: () => _toggleCertificaat(certificaat),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isWPBR ? colorScheme.tertiary : colorScheme.primary).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? (isWPBR ? colorScheme.tertiary : colorScheme.primary)
                          : Colors.white.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check,
                          size: 16,
                          color: isWPBR ? colorScheme.tertiary : colorScheme.primary,
                        ),
                        SizedBox(width: DesignTokens.spacingXS),
                      ],
                      if (isWPBR && !isSelected) ...[
                        Icon(
                          Icons.star_outline,
                          size: 16,
                          color: colorScheme.tertiary,
                        ),
                        SizedBox(width: DesignTokens.spacingXS),
                      ],
                      Text(
                        certificaat,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: isSelected ? DesignTokens.fontWeightMedium : DesignTokens.fontWeightRegular,
                          color: isSelected
                              ? (isWPBR ? colorScheme.tertiary : colorScheme.primary)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Event handlers

  void _handleImageSelected(File imageFile) {
    setState(() {
      _selectedImageFile = imageFile;
      _hasUnsavedChanges = true;
    });
    
    // Upload image immediately
    context.read<ProfielEditBloc>().add(UploadImage(imageFile));
  }

  void _toggleSpecialisatie(String specialisatie) {
    setState(() {
      if (_selectedSpecialisaties.contains(specialisatie)) {
        _selectedSpecialisaties.remove(specialisatie);
      } else if (_selectedSpecialisaties.length < 6) {
        _selectedSpecialisaties.add(specialisatie);
      } else {
        // Show warning for max 6 specialisaties
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximaal 6 specialisaties toegestaan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _markDirty();
    });
  }

  void _toggleCertificaat(String certificaat) {
    setState(() {
      if (_selectedCertificaten.contains(certificaat)) {
        _selectedCertificaten.remove(certificaat);
      } else {
        _selectedCertificaten.add(certificaat);
      }
      _markDirty();
    });
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create updated profile data
    final updatedProfile = widget.initialProfileData.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      kvkNumber: _kvkController.text.trim().isEmpty ? null : _kvkController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      wpbrNumber: _wpbrController.text.trim().isEmpty ? null : _wpbrController.text.trim(),
      specialisaties: _selectedSpecialisaties,
      certificaten: _selectedCertificaten,
      profileImageUrl: _newProfileImageUrl,
      lastUpdated: DateTime.now(),
    );

    // Send save event
    context.read<ProfielEditBloc>().add(SaveProfile(updatedProfile));
  }

  Future<void> _handleBackPressed() async {
    if (_hasUnsavedChanges) {
      await _showUnsavedChangesDialog();
    } else {
      context.pop();
    }
  }

  Future<void> _showUnsavedChangesDialog() async {
    final result = await UnifiedDialog.showConfirmation(
      context: context,
      title: 'Wijzigingen niet opgeslagen',
      message: 'Je hebt wijzigingen gemaakt die nog niet zijn opgeslagen. Weet je zeker dat je wilt weggaan?',
      confirmText: 'Weggaan',
      cancelText: 'Terug',
      userRole: UserRole.guard,
    );

    if (result == true && mounted) {
      context.pop();
    }
  }

  // Validation methods

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is verplicht';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mailadres is verplicht';
    }
    if (!AuthService.isValidEmail(value.trim())) {
      return 'Voer een geldig e-mailadres in';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Use validation from BeveiligerProfielData
    final tempProfile = widget.initialProfileData.copyWith(phone: value.trim());
    final errors = tempProfile.validationErrors;
    final phoneErrors = errors.where((error) => error.contains('telefoonnummer'));
    if (phoneErrors.isNotEmpty) {
      return phoneErrors.first;
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Postal code is optional
    }
    if (!AuthService.isValidDutchPostalCode(value.trim())) {
      return 'Voer een geldige Nederlandse postcode in (1234AB)';
    }
    return null;
  }

  String? _validateKvK(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // KvK is optional
    }
    if (!AuthService.isValidKvK(value.trim())) {
      return 'Voer een geldig KvK nummer in (8 cijfers)';
    }
    return null;
  }

  String? _validateWPBR(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WPBR certificaatnummer is verplicht';
    }
    if (!AuthService.isValidWPBRNumber(value.trim())) {
      return 'Voer een geldig WPBR nummer in (WPBR-123456)';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value != null && value.length > 500) {
      return 'Bio mag maximaal 500 karakters bevatten';
    }
    return null;
  }
}