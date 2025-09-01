import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import '../unified_design_tokens.dart';
import '../routing/app_routes.dart';

/// Enhanced Login Screen with Glassmorphism Phase 1
/// Basic glass effects with excellent performance
class EnhancedGlassmorphicLoginScreen extends StatefulWidget {
  const EnhancedGlassmorphicLoginScreen({super.key});

  @override
  State<EnhancedGlassmorphicLoginScreen> createState() => _EnhancedGlassmorphicLoginScreenState();
}

class _EnhancedGlassmorphicLoginScreenState extends State<EnhancedGlassmorphicLoginScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium gradient background
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
          // Subtle overlay for depth
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
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
                child: Column(
                  children: [
                    _buildGlassHeader(),
                    _buildGlassLoginForm(),
                    SizedBox(height: DesignTokens.spacingL),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader() {
    final slideAnimation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: SizedBox(
          height: 300,
          child: Image.asset(
            'assets/images/gruwelijk-logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Logo asset error: $error');
              return Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: DesignTokens.colorWhite.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                ),
                child: Icon(
                  Icons.security,
                  size: 80,
                  color: DesignTokens.colorWhite,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassLoginForm() {
    final formAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: formAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXL),
        child: _buildBasicGlassContainer(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassEmailField(),
                SizedBox(height: DesignTokens.spacingM),
                _buildGlassPasswordField(),
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildErrorMessage(),
                ],
                SizedBox(height: DesignTokens.spacingS),
                _buildForgotPasswordLink(),
                SizedBox(height: DesignTokens.spacingL),
                _buildGlassLoginButton(),
                SizedBox(height: DesignTokens.spacingXL),
                _buildRegistrationLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Basic glass container - Phase 1 implementation
  Widget _buildBasicGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // 2025 optimized for better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3), // 2025 optimized visibility
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
        color: DesignTokens.colorWhite.withValues(alpha: 0.75), // 2025 optimized for better contrast
        border: Border.all(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3), // 2025 optimized visibility
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
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
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFFF59E0B), // Professional amber accent
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
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
            return 'Wachtwoord moet minimaal 12 karakters bevatten met hoofdletters, kleine letters, cijfers en speciale tekens';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGlassLoginButton() {
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
          // Glass highlight
          BoxShadow(
            color: DesignTokens.colorWhite.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
          onTap: _isLoading ? null : _handleLogin,
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
                    'Inloggen',
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

  Widget _buildForgotPasswordLink() {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _showForgotPasswordDialog(),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          minimumSize: Size(44, 44),
          foregroundColor: DesignTokens.colorWhite,
          overlayColor: DesignTokens.colorWhite.withValues(alpha: 0.1),
        ),
        child: Text(
          'Wachtwoord vergeten?',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: Color(0xFFE2E8F0), // Professional slate 200 - high contrast
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF94A3B8), // Professional slate 400 - subtle underline
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationLink() {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
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
                onTap: () {
                  // Use GoRouter navigation
                  context.go(AppRoutes.register);
                },
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
                            text: 'Nog geen account? ',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0), // Professional slate 200 - secondary text
                              fontWeight: DesignTokens.fontWeightRegular,
                            ),
                          ),
                          TextSpan(
                            text: 'Registreer hier',
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.loginWithResult(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          // Use GoRouter navigation based on user role
          final userType = AuthService.currentUserType.toLowerCase();
          if (userType == 'company') {
            context.go(AppRoutes.companyDashboard);
          } else {
            context.go(AppRoutes.beveiligerDashboard);
          }
        } else {
          setState(() {
            _errorMessage = result.message;
            if (result.errorCode == 'email-not-verified') {
              _showEmailVerificationDialog();
            }
          });
        }
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

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('E-mail verificatie vereist'),
        content: Text(
          'Uw e-mail is nog niet geverifieerd. Controleer uw inbox en klik op de verificatielink.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final result = await AuthService.resendEmailVerification();
              context.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.isSuccess ? DesignTokens.statusConfirmed : DesignTokens.statusCancelled,
                ),
              );
            },
            child: Text('Opnieuw verzenden'),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wachtwoord vergeten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voer uw e-mailadres in om een wachtwoord reset link te ontvangen.',
            ),
            SizedBox(height: DesignTokens.spacingM),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mailadres',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final email = emailController.text.trim();

              if (email.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Voer een e-mailadres in'),
                    backgroundColor: DesignTokens.statusCancelled,
                  ),
                );
                return;
              }

              final result = await AuthService.sendPasswordResetEmail(email);
              context.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.isSuccess ? DesignTokens.statusConfirmed : DesignTokens.statusCancelled,
                ),
              );
            },
            child: Text('Verzenden'),
          ),
        ],
      ),
    );
  }
}