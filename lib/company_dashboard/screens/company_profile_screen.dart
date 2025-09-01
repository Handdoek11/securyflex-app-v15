import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/company_dashboard/widgets/company_profile_overview.dart';
import 'package:securyflex_app/profile/bloc/profile_bloc.dart';
import 'package:securyflex_app/profile/bloc/profile_event.dart';
import 'package:securyflex_app/auth/auth_service.dart';
// CompanyDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/company_dashboard/utils/company_layout_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/billing/screens/subscription_management_screen.dart';

/// Company Profile screen for profile and account management
/// Following template patterns with Company theming
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen>
    with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();

    // Create a new ProfileBloc instance for this screen to avoid state conflicts
    _profileBloc = ProfileBloc();

    // Initialize profile for current company user immediately
    final currentUserId = AuthService.currentUserType; // This should be actual user ID

    // Always initialize to ensure fresh data
    _profileBloc.add(ProfileInitialize(
      userId: currentUserId,
      userType: 'company',
    ));

    if (widget.animationController != null) {
      topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: widget.animationController!,
          curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn),
        ),
      );
    }

    // Add scroll listener for header opacity animation
    scrollController.addListener(() {
      if (scrollController.offset >= CompanyLayoutTokens.scrollThreshold) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <=
              CompanyLayoutTokens.scrollThreshold &&
          scrollController.offset >= 0) {
        if (topBarOpacity !=
            scrollController.offset / CompanyLayoutTokens.scrollThreshold) {
          setState(() {
            topBarOpacity =
                scrollController.offset / CompanyLayoutTokens.scrollThreshold;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // Close the ProfileBloc instance
    _profileBloc.close();
    scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return BlocProvider.value(
      value: _profileBloc,
      child: Container(
        color: companyColors.surfaceContainerHighest,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(AppBar().preferredSize.height),
            child: getAppBarUI(),
          ),
          body: getMainListViewUI(),
        ),
      ),
    );
  }

  Widget getMainListViewUI() {
    return RefreshIndicator(
      onRefresh: () async {
        _profileBloc.add(RefreshProfile());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: DesignTokens.spacingL,
          bottom: 62 + context.safeAreaResponsivePadding.bottom,
        ),
        child: CompanyProfileOverview(
          animation: null, // No animation to prevent layout issues
          animationController: null, // No animation to prevent layout issues
        ),
      ),
    );
  }

  Widget getAppBarUI() {
    return UnifiedHeader.companyGradient(
      title: 'Profiel',
      showNotifications: true,
      onNotificationPressed: () => _navigateToNotifications(),
      actions: [
        // Profile menu button
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: DesignTokens.colorWhite),
          onSelected: (value) {
            switch (value) {
              case 'subscription':
                _navigateToSubscriptionManagement();
                break;
              case 'logout':
                _showLogoutDialog();
                break;
              case 'help':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Ondersteuning - Binnenkort beschikbaar'),
                    duration: Duration(seconds: 2),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'subscription',
              child: Row(
                children: [
                  Icon(Icons.workspace_premium, size: 20),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Abonnement Beheer'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Help'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Uitloggen'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }



  /// Show standardized logout confirmation dialog
  void _showLogoutDialog() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: companyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Text(
          'Uitloggen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: companyColors.onSurface,
          ),
        ),
        content: Text(
          'Weet je zeker dat je wilt uitloggen?',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: companyColors.onSurface),
        ),
        actions: [
          UnifiedButton.text(
            text: 'Annuleren',
            onPressed: () => context.pop(),
          ),
          UnifiedButton.primary(
            text: 'Uitloggen',
            onPressed: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Uitloggen - Functionaliteit komt binnenkort',
                    style: TextStyle(color: companyColors.onPrimary),
                  ),
                  backgroundColor: companyColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        actionsPadding: EdgeInsets.all(DesignTokens.spacingM),
      ),
    );
  }



  /// Navigate to notifications screen
  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificaties - Binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to subscription management screen
  void _navigateToSubscriptionManagement() {
    final userId = AuthService.currentUserId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionManagementScreen(
          userId: userId.isNotEmpty ? userId : null,
        ),
      ),
    );
  }
}
