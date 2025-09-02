import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';
import 'package:securyflex_app/profile/bloc/profile_bloc.dart';
import 'package:securyflex_app/profile/bloc/profile_event.dart';
import 'package:securyflex_app/profile/bloc/profile_state.dart';

import 'package:securyflex_app/company_dashboard/widgets/skeleton_loader.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Company profile overview widget for Company profile screen
/// Shows company profile and settings options organized under profile
class CompanyProfileOverview extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const CompanyProfileOverview({
    super.key,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Always build content directly without animation to prevent layout issues
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Profile Section
          _buildSectionTitle(context, CompanyNL.companyProfile),
          SizedBox(height: DesignTokens.spacingS),
          _buildCompanyProfileCard(context),
          SizedBox(height: DesignTokens.spacingL),

          // Settings Section
          _buildSectionTitle(context, CompanyNL.settings),
          SizedBox(height: DesignTokens.spacingS),
          _buildSettingsOptions(context),
          SizedBox(height: DesignTokens.spacingL),

          // Account Settings Section
          _buildSectionTitle(context, CompanyNL.accountSettings),
          SizedBox(height: DesignTokens.spacingS),
          _buildAccountActions(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: DesignTokens.fontSizeSection,
        fontWeight: DesignTokens.fontWeightSemiBold,
        fontFamily: DesignTokens.fontFamily,
      ),
    );
  }

  Widget _buildCompanyProfileCard(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          // Handle ProfileInitial state - show skeleton while initializing
          if (state is ProfileInitial) {
            return CompanyProfileSkeleton(userRole: UserRole.company);
          } else if (state is ProfileLoading) {
            // Show skeleton with reduced animation for faster perceived loading
            return CompanyProfileSkeleton(userRole: UserRole.company);
          } else if (state is ProfileError) {
            return _buildErrorState(context, state.error.message);
          } else if (state is ProfileLoaded && state.profileData.companyInfo != null) {
            final companyInfo = state.profileData.companyInfo!;
            return _buildCompanyInfoContent(context, companyInfo, companyColors);
          } else if (state is ProfileLoaded) {
            // Show default company info even if companyInfo is null
            return _buildCompanyInfoContent(context, _getDefaultCompanyInfo(), companyColors);
          } else {
            // Fallback: show skeleton for any unknown state
            return CompanyProfileSkeleton(userRole: UserRole.company);
          }
        },
      ),
    );
  }



  Widget _buildCompanyInfoContent(BuildContext context, CompanyInfo companyInfo, ColorScheme companyColors) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          // Company info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: companyColors.primaryContainer,
                child: Text(
                  companyInfo.companyName.isNotEmpty
                    ? companyInfo.companyName.substring(0, 1).toUpperCase()
                    : 'B',
                  style: TextStyle(
                    color: companyColors.onPrimaryContainer,
                    fontSize: DesignTokens.fontSizeHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyInfo.companyName.isNotEmpty
                        ? companyInfo.companyName
                        : 'Bedrijfsnaam niet ingesteld',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: companyColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyInfo.kvkNumber.isNotEmpty
                        ? 'KvK: ${companyInfo.kvkNumber}'
                        : 'KvK nummer niet ingesteld',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: companyColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyInfo.industry.isNotEmpty
                        ? companyInfo.industry
                        : 'Branche niet ingesteld',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: companyColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Company stats - using mock data for now
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Actieve Jobs',
                  '5',
                  Icons.work,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Totaal Uitgegeven',
                  '€2.100',
                  Icons.euro,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Beoordeling',
                  '4.8',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: companyColors.error,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Fout bij laden profiel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.error,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: companyColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedButton.secondary(
            text: 'Opnieuw proberen',
            onPressed: () {
              context.read<ProfileBloc>().add(RefreshProfile());
            },
          ),
        ],
      ),
    );
  }


  CompanyInfo _getDefaultCompanyInfo() {
    return const CompanyInfo(
      companyName: 'SecuryFlex Demo BV',
      kvkNumber: '12345678',
      vatNumber: 'NL123456789B01',
      industry: 'Beveiligingsdiensten',
      website: 'https://securyflex.nl',
      description: 'Professionele beveiligingsdiensten voor bedrijven en particulieren.',
      employeeCount: 25,
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      children: [
        Icon(
          icon,
          color: companyColors.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: companyColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: companyColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsOptions(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.business,
            title: CompanyNL.companyDetails,
            subtitle: 'Naam, adres, contactgegevens',
            onTap: () {
              _showEditCompanyDialog(context);
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: CompanyNL.notifications,
            subtitle: 'E-mail en push notificaties',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.payment,
            title: CompanyNL.billing,
            subtitle: 'Betalingsmethoden en facturen',
            onTap: () {
              // TODO: Navigate to billing
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: CompanyNL.securitySettings,
            subtitle: 'Wachtwoord en tweefactorauthenticatie',
            onTap: () {
              // TODO: Navigate to security settings
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: CompanyNL.support,
            subtitle: 'Veelgestelde vragen en contact',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'Over Securyflex',
            subtitle: 'Versie 1.0.0',
            onTap: () {
              // TODO: Show about dialog
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: CompanyNL.privacyPolicy,
            subtitle: 'Hoe we je gegevens beschermen',
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: CompanyNL.termsOfService,
            subtitle: 'Gebruiksvoorwaarden',
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: CompanyNL.logout,
            subtitle: 'Afmelden van je account',
            onTap: () => _showLogoutConfirmation(context),
            textColor: DesignTokens.colorError,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    final effectiveTextColor = textColor ?? companyColors.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: textColor != null
                    ? DesignTokens.colorError.withValues(alpha: 0.1)
                    : companyColors.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                icon,
                color: textColor ?? companyColors.primary,
                size: 20,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: effectiveTextColor,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: companyColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: companyColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Divider(
      height: 1,
      thickness: 1,
      color: companyColors.outline.withValues(alpha: 0.2),
      indent: DesignTokens.spacingM,
      endIndent: DesignTokens.spacingM,
    );
  }

  void _showEditCompanyDialog(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: companyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Text(
          'Bedrijfsgegevens bewerken',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: companyColors.onSurface,
          ),
        ),
        content: Text(
          'Deze functionaliteit komt binnenkort beschikbaar. Je kunt dan je bedrijfsgegevens direct bewerken.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: companyColors.onSurface,
          ),
        ),
        actions: [
          UnifiedButton.text(
            text: CompanyNL.close,
            onPressed: () => context.pop(),
          ),
          UnifiedButton.primary(
            text: 'Profiel verversen',
            onPressed: () {
              context.pop();
              context.read<ProfileBloc>().add(RefreshProfile());
            },
          ),
        ],
        actionsPadding: EdgeInsets.all(DesignTokens.spacingM),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(CompanyNL.logout),
        content: Text(CompanyNL.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(CompanyNL.cancel),
          ),
          TextButton(
            onPressed: () async {
              context.pop();

              // Perform logout
              await AuthService.logout();

              if (context.mounted) {
                // Navigate to login screen
                context.go('/login');
                // Original: Navigator.of(context).pushNamedAndRemoveUntil(
                //   '/login',
                //   (route) => false,
                // );
              }
            },
            child: Text(
              CompanyNL.logout,
              style: TextStyle(color: DesignTokens.colorError),
            ),
          ),
        ],
      ),
    );
  }
}
