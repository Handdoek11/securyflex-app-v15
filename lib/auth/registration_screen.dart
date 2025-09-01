import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'auth_service.dart';
import '../routing/app_routes.dart';
import 'services/wpbr_verification_service.dart';
import 'services/beveiligingspas_verification_service.dart';
import 'services/svpb_diploma_verification_service.dart';
import 'widgets/kvk_validation_widget.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../company_dashboard/company_dashboard_home.dart';
import '../beveiliger_dashboard/beveiliger_dashboard_home.dart';

/// User registration screen for SecuryFlex
/// Matches the login screen's glassmorphism design
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Dutch business validation controllers
  final _wpbrController = TextEditingController();
  final _beveiligingspaController = TextEditingController();
  final _svpbDiplomaController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  String _selectedUserType = 'guard';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';
  
  // Dutch business validation state
  final bool _isValidatingWPBR = false;
  final bool _isValidatingBeveiligingspas = false;
  final bool _isValidatingSVPBDiploma = false;
  AuthKvKValidation? _validatedKvKResult;
  WPBRData? _validatedWPBRData;
  BeveiligingspaData? _validatedBeveiligingspaData;
  SVPBDiplomaData? _validatedSVPBDiplomaData;
  File? _wpbrCertificateFile;
  File? _svpbDiplomaFile;
  String? _wpbrValidationError;
  String? _beveiligingspaValidationError;
  String? _svpbDiplomaValidationError;
  bool _kvkValidationComplete = false;
  
  // V-symbool uniform compliance
  final bool _uniformGoedkeuring = false;
  File? _uniformPhotoFile;
  
  // eHerkenning level verification
  final String _selectedEHerkenningLevel = 'eh3'; // Default to EH3+ as required from 2025

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animationController?.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _wpbrController.dispose();
    _beveiligingspaController.dispose();
    _svpbDiplomaController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(const AuthInitialize()),
      child: Scaffold(
        body: Stack(
          children: [
            // Premium gradient background - exact same as enhanced login
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Very dark slate - professional depth
                    Color(0xFF1E293B), // Medium slate - glassmorphism background
                    Color(0xFF334155), // Lighter slate - glass visibility
                    Color(0xFF1E293B), // Back to medium - depth
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Subtle overlay for depth - exact same as enhanced login
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            // Main content with glass effects - exact same structure as login
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildGlassHeader(),
                            Expanded(child: _buildGlassRegistrationForm()),
                            SizedBox(height: DesignTokens.spacingL),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    final slideAnimation =
        Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
          ),
        );

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
            children: [
              // Back button at top
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: DesignTokens.colorWhite),
                    onPressed: () {
                      // Use GoRouter navigation instead of Navigator.pop
                      // Check if we can pop, otherwise go to login
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                  Spacer(),
                ],
              ),
              // Logo with glass enhancement
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/gruwelijk-logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.security,
                      size: 70,
                      color: DesignTokens.colorWhite,
                    );
                  },
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Account Aanmaken',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeHeading,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.colorWhite,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Word onderdeel van SecuryFlex',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.colorWhite.withValues(alpha: 0.8),
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildGlassRegistrationForm() {
    final formAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
        .animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );

    return SlideTransition(
      position: formAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXL),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF334155).withValues(alpha: 0.35), // More visible professional glass
                    Color(0xFF475569).withValues(alpha: 0.25), // Better contrast
                  ],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                border: Border.all(
                  color: Color(0xFF64748B).withValues(alpha: 0.4), // More visible professional border
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(DesignTokens.spacingXL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUserTypeSelection(),
                SizedBox(height: DesignTokens.spacingL),
                _buildGlassNameField(),
                SizedBox(height: DesignTokens.spacingM),
                _buildGlassEmailField(),
                SizedBox(height: DesignTokens.spacingM),
                _buildGlassPasswordField(),
                SizedBox(height: DesignTokens.spacingM),
                _buildGlassConfirmPasswordField(),
                SizedBox(height: DesignTokens.spacingL),
                
                // Address fields
                _buildGlassAddressField(),
                SizedBox(height: DesignTokens.spacingM),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildGlassPostalCodeField(),
                    ),
                    SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      flex: 3,
                      child: _buildGlassCityField(),
                    ),
                  ],
                ),
                
                // Role-specific fields
                if (_selectedUserType == 'company') ...[
                  SizedBox(height: DesignTokens.spacingL),
                  _buildEnhancedKvKValidation(),
                ],
                
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildErrorMessage(),
                ],
                
                SizedBox(height: DesignTokens.spacingXL),
                _buildGlassRegisterButton(),
                SizedBox(height: DesignTokens.spacingXL),
                _buildGlassLoginLink(),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ik ben een:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.colorWhite,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeOption('guard', 'Beveiliger'),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildUserTypeOption('company', 'Bedrijf'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeOption(String value, String label) {
    final isSelected = _selectedUserType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedUserType = value),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    DesignTokens.colorPrimaryBlueDark,
                    DesignTokens.colorPrimaryBlue,
                  ],
                )
              : LinearGradient(
                  colors: [
                    DesignTokens.colorWhite.withValues(alpha: 0.1),
                    DesignTokens.colorWhite.withValues(alpha: 0.05),
                  ],
                ),
          border: Border.all(
            color: isSelected 
                ? DesignTokens.colorPrimaryBlue 
                : DesignTokens.colorWhite.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          boxShadow: isSelected ? [
            BoxShadow(
              color: DesignTokens.colorPrimaryBlueDark.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.colorWhite,
            fontWeight: isSelected ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: _selectedUserType == 'company' ? 'Bedrijfsnaam' : 'Volledige naam',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: _selectedUserType == 'company' ? 'Amsterdam Security BV' : 'Jan de Vries',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          prefixIcon: Icon(
            Icons.person_outline,
            color: Color(0xFFF59E0B), // Professional amber accent
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Naam is verplicht';
          }
          if (value.trim().length < 2) {
            return 'Naam moet minimaal 2 karakters bevatten';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'E-mailadres',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: 'voornaam@bedrijf.nl',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Color(0xFFF59E0B), // Professional amber accent
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Voer uw e-mailadres in';
          }
          if (!AuthService.isValidEmail(value)) {
            return 'Voer een geldig e-mailadres in';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'Wachtwoord',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: 'Minimaal 12 karakters',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Color(0xFFF59E0B), // Professional amber accent
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFFF59E0B), // Professional amber accent
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Voer uw wachtwoord in';
          }
          if (!AuthService.isValidPassword(value)) {
            return 'Wachtwoord moet minimaal 12 karakters bevatten';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'Bevestig wachtwoord',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: 'Herhaal je wachtwoord',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Color(0xFFF59E0B), // Professional amber accent
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFFF59E0B), // Professional amber accent
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Bevestig je wachtwoord';
          }
          if (value != _passwordController.text) {
            return 'Wachtwoorden komen niet overeen';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassAddressField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _addressController,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'Straat en huisnummer',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: 'Damrak 123',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          prefixIcon: Icon(
            Icons.home_outlined,
            color: Color(0xFFF59E0B), // Professional amber accent
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Adres is verplicht';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassPostalCodeField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _postalCodeController,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'Postcode',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: '1234 AB',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Verplicht';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassCityField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // Better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _cityController,
        style: TextStyle(
          color: DesignTokens.colorGray800,
          fontSize: DesignTokens.fontSizeBody,
        ),
        decoration: InputDecoration(
          labelText: 'Plaats',
          labelStyle: TextStyle(
            color: DesignTokens.colorGray600,
          ),
          hintText: 'Amsterdam',
          hintStyle: TextStyle(
            color: DesignTokens.colorGray500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingM,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Verplicht';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorWhite,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: DesignTokens.colorWhite,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        gradient: LinearGradient(
          colors: [
            Color(0xFFF59E0B), // Professional amber - authority and trust
            Color(0xFFD97706), // Darker amber for depth
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF59E0B).withValues(alpha: 0.4), // Professional amber shadow
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          onTap: _isLoading ? null : _handleRegister,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignTokens.colorWhite,
                      ),
                    ),
                  )
                : Text(
                    'Account aanmaken',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.colorWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassLoginLink() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: DesignTokens.spacingS),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF475569).withValues(alpha: 0.25), // More visible professional glass
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: Color(0xFF64748B).withValues(alpha: 0.4), // More visible professional border
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                onTap: () => context.go(AppRoutes.login),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingL,
                    vertical: DesignTokens.spacingM,
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                        children: [
                          TextSpan(
                            text: 'Heb je al een account? ',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0), // Professional slate 200 - secondary text
                              fontWeight: DesignTokens.fontWeightRegular,
                            ),
                          ),
                          TextSpan(
                            text: 'Inloggen',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF), // Professional pure white - primary accent text
                              fontWeight: DesignTokens.fontWeightBold,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFF59E0B), // Professional amber underline
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedKvKValidation() {
    return KvKValidationWidget(
      onValidationSuccess: (validation) {
        setState(() {
          _validatedKvKResult = validation;
          _kvkValidationComplete = true;
        });
      },
      onValidationError: (error) {
        setState(() {
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final additionalData = <String, dynamic>{
        'address': _addressController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'city': _cityController.text.trim(),
      };

      if (_selectedUserType == 'company' && _validatedKvKResult != null) {
        additionalData['kvkData'] = _validatedKvKResult!.kvkData;
      }

      final result = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: _selectedUserType,
        additionalData: additionalData,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Navigate to appropriate dashboard
        final route = _selectedUserType == 'company'
            ? '/company/dashboard'
            : '/beveiliger/dashboard';

        context.go(route);
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden. Probeer het opnieuw.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}