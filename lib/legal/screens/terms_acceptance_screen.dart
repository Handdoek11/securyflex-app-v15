import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../terms_and_conditions.dart';
import '../privacy_policy.dart';
import '../../auth/auth_service.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  final UserRole userRole;
  final String userId;
  final VoidCallback onAccepted;
  
  const TermsAcceptanceScreen({
    super.key,
    required this.userRole,
    required this.userId,
    required this.onAccepted,
  });

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> 
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  AnimationController? _animationController;
  bool _hasScrolledToEnd = false;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptCookies = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController?.forward();
  }
  
  void _checkScrollPosition() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _hasScrolledToEnd = true;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _handleAcceptance() async {
    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('U moet de voorwaarden en privacy policy accepteren'),
          backgroundColor: DesignTokens.colorError,
        ),
      );
      return;
    }
    
    // Get userId from widget or AuthService as fallback
    String userId = widget.userId.isNotEmpty ? widget.userId : AuthService.currentUserId;
    
    print('DEBUG: TermsAcceptance - widget.userId: "${widget.userId}"');
    print('DEBUG: TermsAcceptance - AuthService.currentUserId: "${AuthService.currentUserId}"');
    print('DEBUG: TermsAcceptance - final userId: "$userId"');
    
    // Check if userId is valid
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gebruikers-ID niet gevonden. Probeer opnieuw in te loggen.'),
          backgroundColor: DesignTokens.colorError,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Save acceptance to Firestore with all required fields
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'termsAccepted': true,
        'termsVersion': TermsAndConditions.version,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'privacyAccepted': true,
        'privacyVersion': PrivacyPolicy.version,
        'privacyAcceptedAt': FieldValue.serverTimestamp(),
        'cookieConsent': _acceptCookies,
        'cookieConsentAt': _acceptCookies ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      await prefs.setString('terms_version', TermsAndConditions.version);
      await prefs.setBool('cookie_consent', _acceptCookies);
      
      // Update AuthService cache immediately for route guards
      AuthService.updateTermsAcceptanceCache(userId, true);
      
      // Navigate to main app
      if (mounted) {
        widget.onAccepted();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Er ging iets mis: $e'),
            backgroundColor: DesignTokens.colorError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Scaffold(
      body: Stack(
        children: [
          // Premium gradient background (same as login)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Very dark slate
                  Color(0xFF1E293B), // Medium slate
                  Color(0xFF334155), // Lighter slate
                  Color(0xFF1E293B), // Back to medium
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
          SafeArea(
            child: Column(
              children: [
                // Glass Header with animation
                _buildGlassHeader(theme),
                
                // Terms content with glass effect
                Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingXL),
                child: _buildGlassContentContainer(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(DesignTokens.spacingXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Important notice with glass effect
                        _buildGlassInfoBox(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFFF59E0B), // Professional amber
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Lees deze voorwaarden zorgvuldig door. Ze zijn aangepast aan de Nederlandse wetgeving per 2025.',
                                  style: TextStyle(
                                    color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Summary points
                        Text(
                          'Belangrijkste punten:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.colorWhite,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        ...TermsAndConditions.getSummaryPoints().map((point) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: Color(0xFFF59E0B), // Professional amber
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(
                                      color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Divider(color: DesignTokens.colorWhite.withValues(alpha: 0.2)),
                        const SizedBox(height: 24),
                        
                        // Full terms
                        Text(
                          'Volledige voorwaarden:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.colorWhite,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        SelectableText(
                          TermsAndConditions.getFullTermsNL(),
                          style: TextStyle(
                            color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Scroll indicator
                        if (!_hasScrolledToEnd)
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Color(0xFFF59E0B),
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scroll naar beneden om door te gaan',
                                  style: TextStyle(
                                    color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                                    fontSize: 12,
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
            ),
                
                // Acceptance section with glass effect
                if (_hasScrolledToEnd)
                  _buildGlassAcceptanceSection(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glass container builder - same style as login
  Widget _buildGlassContainer({required Widget child}) {
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
                const Color(0xFF334155).withValues(alpha: 0.35),
                const Color(0xFF475569).withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            border: Border.all(
              color: const Color(0xFF64748B).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(DesignTokens.spacingXL),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassContentContainer({required Widget child}) {
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
                const Color(0xFF334155).withValues(alpha: 0.35),
                const Color(0xFF475569).withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            border: Border.all(
              color: const Color(0xFF64748B).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassHeader(ColorScheme theme) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), 
      end: const Offset(0, 0)
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: _buildGlassContainer(
          child: Row(
            children: [
              const Icon(
                Icons.gavel,
                color: Color(0xFFF59E0B), // Professional amber
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gebruikersvoorwaarden',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.colorWhite,
                      ),
                    ),
                    Text(
                      'Versie ${TermsAndConditions.version} - ${TermsAndConditions.lastUpdated}',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.colorWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInfoBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }

  Widget _buildGlassAcceptanceSection(ColorScheme theme) {
    final formAnimation = Tween<Offset>(
      begin: const Offset(0, 1), 
      end: const Offset(0, 0)
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: formAnimation,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: _buildGlassContainer(
          child: Column(
            children: [
              // Terms checkbox
              _buildGlassCheckbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                label: 'Ik accepteer de ',
                linkText: 'algemene voorwaarden',
                onLinkTap: _showTermsDialog,
              ),
              
              // Privacy checkbox
              _buildGlassCheckbox(
                value: _acceptPrivacy,
                onChanged: (value) {
                  setState(() {
                    _acceptPrivacy = value ?? false;
                  });
                },
                label: 'Ik accepteer het ',
                linkText: 'privacybeleid',
                onLinkTap: _showPrivacyDialog,
              ),
              
              // Cookie consent
              _buildGlassCheckbox(
                value: _acceptCookies,
                onChanged: (value) {
                  setState(() {
                    _acceptCookies = value ?? false;
                  });
                },
                label: 'Ik geef toestemming voor analytische cookies (optioneel)',
                linkText: '',
                onLinkTap: null,
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildGlassOutlinedButton(
                      onPressed: () => context.pop(),
                      label: 'Weigeren',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassElevatedButton(
                      onPressed: (_acceptTerms && _acceptPrivacy && !_isLoading) 
                          ? _handleAcceptance 
                          : null,
                      label: 'Accepteren & Doorgaan',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 14-day withdrawal notice
              Text(
                'U heeft 14 dagen bedenktijd na registratie',
                style: TextStyle(
                  color: DesignTokens.colorWhite.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String label,
    required String linkText,
    VoidCallback? onLinkTap,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFF59E0B);
            }
            return Colors.transparent;
          }),
          side: BorderSide(
            color: DesignTokens.colorWhite.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: linkText.isNotEmpty
            ? RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: label),
                    TextSpan(
                      text: linkText,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = onLinkTap,
                    ),
                  ],
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildGlassOutlinedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: DesignTokens.colorWhite.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DesignTokens.colorWhite.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildGlassElevatedButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
  
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Algemene Voorwaarden'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(TermsAndConditions.getFullTermsNL()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }
  
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacybeleid'),
        content: const SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text('Privacy policy inhoud hier...'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }
}