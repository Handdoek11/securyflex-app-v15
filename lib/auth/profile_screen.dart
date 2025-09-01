import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/auth/enhanced_glassmorphic_login_screen.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import '../legal/terms_and_conditions.dart';
import '../legal/privacy_policy.dart';

/// Profile screen with logout functionality
/// Maintains template design consistency
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _animationController?.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Gebruik consistent dashboard surface kleur
    return Container(
      color: DesignTokens.guardSurface, // Lichtgrijs zoals dashboard
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            UnifiedHeader.simple(
              title: 'Profiel',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
              leading: HeaderElements.backButton(userRole: UserRole.guard),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: DesignTokens.spacingL - 4),
                    _buildProfileInfo(),
                    SizedBox(height: DesignTokens.spacingXL - 2),
                    _buildLegalSection(),
                    SizedBox(height: DesignTokens.spacingXL - 2),
                    _buildLogoutSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final slideAnimation =
        Tween<Offset>(begin: Offset(0, -0.5), end: Offset(0, 0)).animate(
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
            CircleAvatar(
              radius: 50,
              backgroundColor: DesignTokens.guardPrimary,
              child: Icon(_getUserIcon(), size: 50, color: DesignTokens.colorWhite),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              AuthService.currentUserName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: DesignTokens.guardPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AuthService.getUserRoleDisplayName(AuthService.currentUserType),
                style: TextStyle(
                  fontSize: 16,
                  color: DesignTokens.guardPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(DesignTokens.spacingL - 4),
        decoration: BoxDecoration(
          color: DesignTokens.colorWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Informatie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              Icons.person_outline,
              'Gebruikerstype',
              AuthService.getUserRoleDisplayName(AuthService.currentUserType),
            ),
            SizedBox(height: DesignTokens.spacingS + 4),
            _buildInfoRow(Icons.verified_user_outlined, 'Status', 'Actief'),
            SizedBox(height: DesignTokens.spacingS + 4),
            _buildInfoRow(
              Icons.access_time_outlined,
              'Laatste login',
              'Vandaag',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DesignTokens.colorGray600),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: DesignTokens.colorGray600),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    final slideUpAnimation =
        Tween<Offset>(begin: Offset(0, 0.5), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
          ),
        );

    return SlideTransition(
      position: slideUpAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingL - 4),
              decoration: BoxDecoration(
                color: DesignTokens.statusCancelled.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignTokens.statusCancelled.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.logout, size: 40, color: DesignTokens.statusCancelled.withValues(alpha: 0.6)),
                  SizedBox(height: DesignTokens.spacingS + 4),
                  Text(
                    'Uitloggen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.statusCancelled.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'U wordt uitgelogd en teruggebracht naar het inlogscherm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: DesignTokens.statusCancelled.withValues(alpha: 0.6)),
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  SizedBox(
                    width: double.infinity,
                    child: UnifiedButton.primary(
                      text: 'Uitloggen',
                      onPressed: _handleLogout,
                      backgroundColor: DesignTokens.statusCancelled.withValues(alpha: 0.6),
                      size: UnifiedButtonSize.large,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getUserIcon() {
    switch (AuthService.currentUserType.toLowerCase()) {
      case 'guard':
        return Icons.security;
      case 'company':
        return Icons.business;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Uitloggen'),
          content: Text('Weet u zeker dat u wilt uitloggen?'),
          actions: [
            UnifiedButton.text(
              text: 'Annuleren',
              onPressed: () => context.pop(),
            ),
            UnifiedButton.primary(
              text: 'Uitloggen',
              onPressed: () {
                context.pop();
                _performLogout();
              },
              backgroundColor: DesignTokens.statusCancelled.withValues(alpha: 0.6),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegalSection() {
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Interval(0.4, 0.9, curve: Curves.fastOutSlowIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(DesignTokens.spacingL - 4),
        decoration: BoxDecoration(
          color: DesignTokens.colorWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel_outlined,
                  size: 20,
                  color: DesignTokens.guardPrimary,
                ),
                SizedBox(width: 8),
                Text(
                  'Juridisch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildLegalLink(
              Icons.description_outlined,
              'Algemene Voorwaarden',
              'Versie ${TermsAndConditions.version}',
              () => _showTermsDialog(),
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildLegalLink(
              Icons.privacy_tip_outlined,
              'Privacybeleid',
              'Versie ${PrivacyPolicy.version}',
              () => _showPrivacyDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: DesignTokens.colorGray600),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: DesignTokens.guardPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: DesignTokens.colorGray600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: DesignTokens.colorGray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Algemene Voorwaarden',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      TermsAndConditions.getFullTermsNL(),
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),
                UnifiedButton.primary(
                  text: 'Sluiten',
                  onPressed: () => context.pop(),
                  size: UnifiedButtonSize.medium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacybeleid',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      PrivacyPolicy.getFullPolicyNL(),
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),
                UnifiedButton.primary(
                  text: 'Sluiten',
                  onPressed: () => context.pop(),
                  size: UnifiedButtonSize.medium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _performLogout() {
    AuthService.logout();

    // Navigate to login screen
    context.go('/login');
  }
}
