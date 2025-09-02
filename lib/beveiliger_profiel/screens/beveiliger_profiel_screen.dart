import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart' as premium;
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/beveiliger_profiel/bloc/beveiliger_profiel_bloc.dart';
import 'package:securyflex_app/beveiliger_profiel/bloc/profiel_edit_bloc.dart';
import 'package:securyflex_app/beveiliger_profiel/models/beveiliger_profiel_data.dart';
import 'package:securyflex_app/routing/app_routes.dart';
import 'package:securyflex_app/beveiliger_profiel/screens/profiel_edit_screen.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/certificaten_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/specialisaties_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/job_recommendations_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/profile_completion_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/profile_stats_widget.dart';
import 'package:securyflex_app/beveiliger_notificaties/screens/notification_preferences_screen.dart';
import 'package:securyflex_app/unified_components/smart_badge_overlay.dart';
import 'package:securyflex_app/beveiliger_notificaties/services/guard_notification_service.dart';
import 'package:securyflex_app/beveiliger_notificaties/screens/notification_center_screen.dart';
import 'package:securyflex_app/beveiliger_notificaties/bloc/notification_center_bloc.dart';
import 'package:securyflex_app/billing/screens/subscription_management_screen.dart';

/// Beveiliger Profiel Screen met unified components
/// 
/// VERPLICHT gebruik van:
/// - UnifiedHeader.simple met UserRole.guard theming
/// - DesignTokens.spacingM, DesignTokens.spacingL voor alle spacing
/// - SecuryFlexTheme.getColorScheme(UserRole.guard) voor colors
/// - UnifiedCard.standard voor alle content secties
/// - UnifiedButton.primary voor edit button
class BeveiligerProfielScreen extends StatefulWidget {
  final AnimationController? animationController;
  
  const BeveiligerProfielScreen({
    super.key,
    this.animationController,
  });

  @override
  State<BeveiligerProfielScreen> createState() => _BeveiligerProfielScreenState();
}

class _BeveiligerProfielScreenState extends State<BeveiligerProfielScreen>
    with TickerProviderStateMixin {
  late AnimationController _localAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Notification state
  final GuardNotificationService _notificationService = GuardNotificationService.instance;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfile();
    _loadUnreadNotificationCount();
  }

  void _initializeAnimations() {
    _localAnimationController = widget.animationController ?? 
        AnimationController(
          duration: DesignTokens.durationMedium,
          vsync: this,
        );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _localAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _localAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _localAnimationController.forward();
  }

  void _loadProfile() {
    final userId = AuthService.currentUserId;
    context.read<BeveiligerProfielBloc>().add(const LoadProfile());
    
    // Load profile completion and stats data
    if (userId.isNotEmpty) {
      context.read<BeveiligerProfielBloc>().add(LoadProfileCompletion(userId));
      context.read<BeveiligerProfielBloc>().add(LoadProfileStats(userId));
    }
  }

  /// Load unread notification count
  void _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Navigate to notification center
  void _navigateToNotificationCenter() async {
    context.go(AppRoutes.beveiligerNotifications);
    
    // Refresh notification count when returning from notifications
    // Note: In GoRouter, we can't easily await navigation results
    // Consider using state management or listeners for notification count updates
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _localAnimationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
          children: [
            // ✅ FIXED: Converted to UnifiedHeader.animated for consistency
            UnifiedHeader.animated(
              title: 'Mijn Profiel',
              animationController: _localAnimationController,
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
              actions: [
                // Edit button first
                HeaderElements.actionButton(
                  icon: Icons.edit,
                  onPressed: () => _navigateToEditProfile(context),
                  userRole: UserRole.guard,
                ),
                // Refresh button second
                HeaderElements.actionButton(
                  icon: Icons.refresh,
                  onPressed: () {
                    context.read<BeveiligerProfielBloc>().add(const RefreshProfile());
                  },
                  userRole: UserRole.guard,
                ),
                // Notification bell last (rightmost)
                SmartBadgeOverlay(
                  badgeCount: _unreadNotificationCount,
                  child: HeaderElements.actionButton(
                    icon: Icons.notifications_outlined,
                    onPressed: _navigateToNotificationCenter,
                    userRole: UserRole.guard,
                  ),
                ),
              ],
            ),
            
            // Content area
            Expanded(
              child: BlocConsumer<BeveiligerProfielBloc, BeveiligerProfielState>(
                listener: (context, state) {
                  if (state is ProfielError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error.localizedMessage),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is ProfielUpdated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage),
                        backgroundColor: DesignTokens.colorSuccess,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ProfielLoading) {
                    return _buildLoadingState();
                  } else if (state is BeveiligerProfielLoaded) {
                    return _buildEnhancedProfileContent(state);
                  } else if (state is ProfielLoaded) {
                    return _buildProfileContent(state.profileData, state.statistics);
                  } else if (state is ProfielError) {
                    return _buildErrorState(state);
                  }
                  return _buildInitialState();
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
            'Profiel laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ProfielError state) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: premium.PremiumGlassContainer(
          intensity: premium.GlassIntensity.standard,
          elevation: premium.GlassElevation.floating,
          tintColor: colorScheme.error,
          enableTrustBorder: true,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          padding: EdgeInsets.all(DesignTokens.spacingL),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: DesignTokens.iconSizeXL * 2,
                color: colorScheme.error,
              ),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Fout bij laden profiel',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                state.error.localizedMessage,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spacingL),
              UnifiedButton.primary(
                text: 'Opnieuw proberen',
                onPressed: _loadProfile,
              ),
            ],
              ),
            ),
          ),
        );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Text('Initialiseren...'),
    );
  }

  Widget _buildEnhancedProfileContent(BeveiligerProfielLoaded state) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<BeveiligerProfielBloc>().add(const RefreshProfile());
                final userId = AuthService.currentUserId;
                if (userId.isNotEmpty) {
                  context.read<BeveiligerProfielBloc>().add(LoadProfileCompletion(userId));
                  context.read<BeveiligerProfielBloc>().add(LoadProfileStats(userId));
                }
              },
              color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(DesignTokens.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile completion widget (only show if not fully complete)
                    if (state.profileCompletionData != null)
                      ProfileCompletionWidget(
                        userId: AuthService.currentUserId,
                        onCompletionMilestone: () {
                          // Refresh data when milestone is reached
                          final userId = AuthService.currentUserId;
                          if (userId.isNotEmpty) {
                            context.read<BeveiligerProfielBloc>().add(LoadProfileCompletion(userId));
                          }
                        },
                      ),
                    
                    // Profile header card
                    _buildProfileHeaderCard(state.profileData),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Profile stats widget
                    if (state.profileStatsData != null)
                      ProfileStatsWidget(
                        userId: AuthService.currentUserId,
                        userRole: 'guard',
                        showDetailedStats: true,
                        onStatsTap: () {
                          // Could navigate to detailed analytics screen
                        },
                      ),
                    
                    if (state.profileStatsData == null)
                      // Fallback to original statistics card
                      _buildStatisticsCard(state.statistics),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Personal info card
                    _buildPersonalInfoCard(state.profileData),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Enhanced Specialisaties card with unified components
                    _buildEnhancedSpecialisatiesCard(state.profileData),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Job Recommendations based on specializations
                    if (state.profileData.specializations.isNotEmpty)
                      _buildJobRecommendationsCard(state.profileData),
                    
                    if (state.profileData.specializations.isNotEmpty)
                      SizedBox(height: DesignTokens.spacingM),
                    
                    // Certificaten card - Enhanced with comprehensive certificate display
                    _buildCertificatenCard(state.profileData),
                    
                    SizedBox(height: DesignTokens.spacingM),
                    
                    // Settings and preferences section
                    _buildSettingsSection(),
                    
                    SizedBox(height: DesignTokens.spacingL),
                    
                    // Edit button
                    _buildEditButton(state.profileData),
                    
                    SizedBox(height: DesignTokens.spacingL), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(BeveiligerProfielData profileData, Map<String, dynamic> statistics) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header card
                  _buildProfileHeaderCard(profileData),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Statistics card
                  _buildStatisticsCard(statistics),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Personal info card
                  _buildPersonalInfoCard(profileData),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Enhanced Specialisaties card with unified components
                  _buildEnhancedSpecialisatiesCard(profileData),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Job Recommendations based on specializations
                  if (profileData.specializations.isNotEmpty)
                    _buildJobRecommendationsCard(profileData),
                  
                  if (profileData.specializations.isNotEmpty)
                    SizedBox(height: DesignTokens.spacingM),
                  
                  // Certificaten card - Enhanced with comprehensive certificate display
                  _buildCertificatenCard(profileData),
                  
                  SizedBox(height: DesignTokens.spacingM),
                  
                  // Settings and preferences section
                  _buildSettingsSection(),
                  
                  SizedBox(height: DesignTokens.spacingL),
                  
                  // Edit button
                  _buildEditButton(profileData),
                  
                  SizedBox(height: DesignTokens.spacingL), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeaderCard(BeveiligerProfielData profileData) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.2),
                colorScheme.primary.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile image
              Container(
                width: DesignTokens.iconSizeXXL * 2,
                height: DesignTokens.iconSizeXXL * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.colorWhite.withValues(alpha: 0.2),
                  border: Border.all(
                    color: DesignTokens.colorWhite.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: profileData.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profileData.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              
              SizedBox(width: DesignTokens.spacingM),
              
              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileData.displayName,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeTitleLarge,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.colorBlack,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      profileData.email,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: DesignTokens.colorBlack,
                      ),
                    ),
                    if (profileData.isVerified) ...[
                      SizedBox(height: DesignTokens.spacingS),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: DesignTokens.iconSizeS,
                            color: DesignTokens.colorWhite,
                          ),
                          SizedBox(width: DesignTokens.spacingXS),
                          Text(
                            'Geverifieerd',
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeCaption,
                              color: DesignTokens.colorWhite,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: DesignTokens.iconSizeXL,
      color: DesignTokens.colorWhite.withValues(alpha: 0.7),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> statistics) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final completionPercentage = (statistics['completionPercentage'] as double) * 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Profiel Compleetheid',
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${completionPercentage.toStringAsFixed(0)}% compleet',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (statistics['isWpbrExpiringSoon'] == true)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        border: Border.all(
                          color: DesignTokens.colorWarning,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'WPBR verloopt binnenkort',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.colorWarning,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingS),
              LinearProgressIndicator(
                value: statistics['completionPercentage'] as double,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 6,
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Statistics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${statistics['specialisatieCount'] ?? 0}',
                'Specialisaties',
                Icons.work_outline,
                colorScheme,
              ),
              _buildStatItem(
                '${statistics['certificateCount'] ?? 0}',
                'Certificaten',
                Icons.card_membership,
                colorScheme,
              ),
              _buildStatItem(
                statistics['isVerified'] == true ? 'Ja' : 'Nee',
                'Geverifieerd',
                statistics['isVerified'] == true ? Icons.check_circle : Icons.pending,
                colorScheme,
              ),
            ],
          ),
        ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeL,
          color: colorScheme.primary,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BeveiligerProfielData profileData) {
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
          _buildInfoRow('Naam', profileData.name, Icons.person),
          _buildInfoRow('E-mail', profileData.email, Icons.email),
          if (profileData.phone != null && profileData.phone!.isNotEmpty)
            _buildInfoRow('Telefoon', profileData.formattedPhone ?? profileData.phone!, Icons.phone),
          if (profileData.postalCode != null && profileData.postalCode!.isNotEmpty)
            _buildInfoRow('Postcode', profileData.postalCode!, Icons.location_on),
          if (profileData.kvkNumber != null && profileData.kvkNumber!.isNotEmpty)
            _buildInfoRow('KvK Nummer', AuthService.formatKvKNumber(profileData.kvkNumber!), Icons.business),
          
          if (profileData.bio != null && profileData.bio!.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Bio',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              profileData.bio!,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
                height: DesignTokens.lineHeightRelaxed,
              ),
            ),
          ],
        ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEnhancedSpecialisatiesCard(BeveiligerProfielData profileData) {
    return SpecialisatiesWidget(
      userId: profileData.id,
      userRole: UserRole.guard,
      initialSpecializations: profileData.specializations,
      isEditable: false, // Read-only in view mode
      showSkillLevels: true,
      showCategoryGroups: false, // Simplified view for profile screen
      onSpecializationsChanged: (specializations) {
        // Handle specializations update
        context.read<BeveiligerProfielBloc>().add(const RefreshProfile());
      },
    );
  }

  Widget _buildJobRecommendationsCard(BeveiligerProfielData profileData) {
    return JobRecommendationsWidget(
      userId: profileData.id,
      userRole: UserRole.guard,
      specializations: profileData.specializations,
      userCertificates: profileData.certificaten,
      maxRecommendations: 3, // Show fewer on profile screen
      useSkillLevelFiltering: true,
      onJobTapped: (job) {
        // Handle navigation to job details
        _navigateToJobDetails(job);
      },
      onViewAllJobsTapped: () {
        // Handle navigation to marketplace
        _navigateToMarketplace(profileData.specializations);
      },
    );
  }

  Widget _buildCertificatenCard(BeveiligerProfielData profileData) {
    // Use comprehensive CertificatenWidget with full certificate management
    return CertificatenWidget(
      userId: profileData.id,
      userRole: UserRole.guard,
    );
  }

  Widget _buildSettingsSection() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title outside the container
        Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Instellingen & Voorkeuren',
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
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
          // Subscription management option
          _buildSettingsOption(
            'Abonnement Beheer',
            'Beheer je abonnement en betalingen',
            Icons.workspace_premium,
            () => _navigateToSubscriptionManagement(),
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          Divider(color: colorScheme.outlineVariant),
          SizedBox(height: DesignTokens.spacingS),

          // Notification preferences option
          _buildSettingsOption(
            'Notificatie Instellingen',
            'Beheer je notificatie voorkeuren',
            Icons.notifications,
            () => _navigateToNotificationPreferences(),
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          Divider(color: colorScheme.outlineVariant),
          SizedBox(height: DesignTokens.spacingS),
          
          // Privacy settings option
          _buildSettingsOption(
            'Privacy Instellingen',
            'Beheer je privacy voorkeuren',
            Icons.privacy_tip,
            () => _showComingSoonDialog('Privacy Instellingen'),
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          Divider(color: colorScheme.outlineVariant),
          SizedBox(height: DesignTokens.spacingS),
          
          // Account settings option
          _buildSettingsOption(
            'Account Instellingen',
            'Account beheer en beveiliging',
            Icons.account_circle,
            () => _showComingSoonDialog('Account Instellingen'),
          ),
        ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: DesignTokens.spacingS,
          horizontal: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: DesignTokens.iconSizeM,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(BeveiligerProfielData profileData) {
    return SizedBox(
      width: double.infinity,
      child: UnifiedButton.primary(
        text: 'Profiel Bewerken',
        onPressed: () => _navigateToEditProfile(context, profileData: profileData),
        size: UnifiedButtonSize.large,
      ),
    );
  }

  /// Navigate to edit profile screen met BLoC provider
  Future<void> _navigateToEditProfile(BuildContext context, {BeveiligerProfielData? profileData}) async {
    final blocState = context.read<BeveiligerProfielBloc>().state;
    final currentProfile = profileData ?? 
        (blocState is ProfielLoaded ? blocState.profileData : null);
    
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profiel niet geladen. Probeer opnieuw.'),
          backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await context.push('/beveiliger/certificates/add');
    // Original: Navigator.of(context).push<bool>(
    //   MaterialPageRoute(
    //     builder: (context) => BlocProvider(
    //       create: (context) => ProfielEditBloc(),
    //       child: ProfielEditScreen(
    //         initialProfileData: currentProfile,
    //       ),
    //     ),
    //   ),
    // );

    // Refresh profile na succesvol bewerken
    if (result == true && mounted) {
      if (!context.mounted) return;
      context.read<BeveiligerProfielBloc>().add(const RefreshProfile());
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profiel succesvol bijgewerkt'),
          backgroundColor: DesignTokens.colorSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Navigate to job details
  void _navigateToJobDetails(dynamic job) {
    // TODO: Implement navigation to job details screen
    // This would typically navigate to a JobDetailsScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigeren naar job details: ${job.jobTitle ?? 'Unknown Job'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to marketplace with specialization filters
  void _navigateToMarketplace(List<dynamic> specializations) {
    // TODO: Implement navigation to marketplace with pre-applied filters
    // This would typically navigate to MarketplaceScreen with filters
    final specializationNames = specializations.map((s) => s.type?.displayName ?? 'Unknown').toList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigeren naar marketplace met filters: ${specializationNames.join(", ")}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to notification preferences screen
  void _navigateToNotificationPreferences() {
    context.push('/notifications/preferences');
    // Original: context.push('/route-placeholder') => NotificationPreferencesScreen(
    //       animationController: widget.animationController,
    //     ),
    //   ),
    // );
  }

  /// Navigate to subscription management screen
  void _navigateToSubscriptionManagement() {
    final userId = AuthService.currentUserId;
    context.push('/subscription-management');
    // Original: context.push('/route-placeholder') => SubscriptionManagementScreen(
    //       userId: userId.isNotEmpty ? userId : null,
    //     ),
    //   ),
    // );
  }

  /// Show coming soon dialog for features not yet implemented
  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Binnenkort Beschikbaar'),
        content: Text(
          '$featureName wordt binnenkort toegevoegd. '
          'Houd de app bij voor updates!',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Begrepen'),
          ),
        ],
      ),
    );
  }
}