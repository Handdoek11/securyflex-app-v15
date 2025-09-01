import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../unified_design_tokens.dart';
import '../core/responsive/responsive_provider.dart';
import '../unified_theme_system.dart';
import '../unified_header.dart';
import '../unified_components/smart_badge_overlay.dart';
import '../unified_components/unified_background_service.dart';
import '../core/performance_monitor.dart';
import '../auth/auth_service.dart';
import 'performance/mobile_performance_optimizer.dart';

// Controllers
import 'controllers/dashboard_animation_controller.dart';
import 'controllers/dashboard_data_controller.dart';
import 'controllers/dashboard_navigation_controller.dart';
import 'utils/responsive_breakpoints.dart';

// BLoC
import 'bloc/beveiliger_dashboard_bloc.dart';
import 'bloc/beveiliger_dashboard_event.dart';
import 'bloc/beveiliger_dashboard_state.dart';
import 'models/enhanced_dashboard_data.dart' as dashboard_models;

// Sections
import 'sections/dashboard_header_section.dart';
import 'sections/certificate_alerts_section.dart';
import 'sections/shifts_management_section.dart';
import 'widgets/guard_welcome_widget.dart';
import 'widgets/pending_reviews_widget.dart';

// Payment integration
import '../unified_components/modern_payment_status_widget.dart';
import 'services/payment_integration_service.dart';

// Billing integration
import '../billing/widgets/subscription_status_widget.dart';
import '../billing/screens/subscription_upgrade_screen.dart';

/// Modern, refactored Beveiliger Dashboard V2
/// 
/// This version implements:
/// - Separated controllers for animations, data, and navigation
/// - Responsive breakpoints for all screen sizes
/// - Maximum 4-level widget nesting
/// - Improved performance and maintainability
class ModernBeveiligerDashboardV2 extends StatefulWidget {
  final AnimationController? animationController;
  
  const ModernBeveiligerDashboardV2({
    super.key,
    this.animationController,
  });

  @override
  State<ModernBeveiligerDashboardV2> createState() => _ModernBeveiligerDashboardV2State();
}

class _ModernBeveiligerDashboardV2State extends State<ModernBeveiligerDashboardV2>
    with TickerProviderStateMixin {
  
  // Controllers
  late DashboardAnimationController _animationController;
  late DashboardDataController _dataController;
  late DashboardNavigationController _navigationController;
  
  // Scroll controller
  final ScrollController _scrollController = ScrollController();
  
  // Payment integration service
  late DashboardPaymentIntegrationService _paymentService;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize mobile performance optimizations
    MobilePerformanceOptimizer.initialize();
    MobilePerformanceOptimizer.optimizeForMobileMemory();
    
    // Start performance monitoring
    PerformanceMonitor.instance.startMeasurement('widget_build_ModernBeveiligerDashboardV2');
    
    // Initialize controllers
    _initializeControllers();
    
    // Load initial data
    _loadDashboardData();
  }
  
  void _initializeControllers() {
    // Animation controller
    _animationController = DashboardAnimationController(
      vsync: this,
      providedController: widget.animationController,
    );
    _animationController.initialize();
    
    // Data controller
    _dataController = DashboardDataController();
    
    // Navigation controller
    _navigationController = DashboardNavigationController(context: context);
    
    // Payment service
    _paymentService = DashboardPaymentIntegrationService();
  }
  
  Future<void> _loadDashboardData() async {
    await _dataController.loadAllData();
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _dataController.dispose();
    
    // Cleanup mobile performance optimizations
    MobilePerformanceOptimizer.dispose();
    
    PerformanceMonitor.instance.endMeasurement('widget_build_ModernBeveiligerDashboardV2');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Get responsive values
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);
    final responsivePadding = const EdgeInsets.all(DesignTokens.spacingM); // Fixed 16px padding for consistency
    
    // Maximum 4 levels: SafeArea > Background > Column > Content
    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(deviceType, responsivePadding),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build responsive header
  Widget _buildHeader() {
    return UnifiedHeader.animated(
      title: 'Dashboard',
      animationController: _animationController.controller,
      scrollController: _scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.guard,
      titleAlignment: TextAlign.left,
      actions: [
        SmartBadgeOverlay(
          badgeCount: _dataController.unreadNotificationCount,
          child: HeaderElements.actionButton(
            icon: Icons.notifications_outlined,
            onPressed: _navigationController.navigateToNotificationCenter,
            userRole: UserRole.guard,
          ),
        ),
      ],
    );
  }
  
  /// Build responsive content with BLoC
  Widget _buildContent(DeviceType deviceType, EdgeInsets padding) {
    return BlocBuilder<BeveiligerDashboardBloc, BeveiligerDashboardState>(
      builder: (context, state) {
        if (state is BeveiligerDashboardLoading) {
          return _buildLoadingState();
        }
        
        if (state is BeveiligerDashboardError) {
          return _buildErrorState(state);
        }
        
        if (state is BeveiligerDashboardLoaded) {
          return _buildDashboardContent(state.data, deviceType, padding);
        }
        
        return _buildLoadingState();
      },
    );
  }
  
  /// Build dashboard content with responsive layout
  Widget _buildDashboardContent(
    dashboard_models.EnhancedDashboardData data,
    DeviceType deviceType,
    EdgeInsets padding,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<BeveiligerDashboardBloc>().add(const RefreshDashboardData());
        await _dataController.refreshData();
        if (mounted) setState(() {});
      },
      color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero, // Remove default padding
        children: [
          // Welcome widget with padding
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: _buildWelcomeSection(data, deviceType),
          ),
          
          // Subscription status section with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: _buildSubscriptionSection(),
          ),
          
          // Profile completion section with padding
          if (_dataController.profileCompletion != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
              child: _buildProfileSection(deviceType),
            ),
          
          // Certificate alerts section with padding
          if (_shouldShowCertificates())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
              child: _buildCertificateSection(deviceType),
            ),
          
          // Pending reviews section with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: _buildPendingReviewsSection(),
          ),
          
          // Payment status section
          _buildPaymentSection(),
          
          // Shifts section - NO PADDING (full width for horizontal scroll)
          _buildShiftsSection(data.shifts, deviceType),
          
          // Bottom spacing
          SizedBox(
            height: ResponsiveBreakpoints.getResponsiveSpacing(
              context,
              baseSpacing: DesignTokens.spacingL,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build responsive welcome section
  Widget _buildWelcomeSection(
    dashboard_models.EnhancedDashboardData data,
    DeviceType deviceType,
  ) {
    return GuardWelcomeWidget(
      animationController: _animationController.controller,
      guardName: AuthService.currentUserName,
      todayEarnings: {
        'amount': data.earnings.dutchFormattedToday,
        'hours': data.earnings.hoursWorkedToday.toStringAsFixed(1),
      },
      nextShift: data.shifts.isNotEmpty ? {
        'time': data.shifts.first.dutchTimeRange,
        'location': data.shifts.first.location,
        'address': data.shifts.first.address,
        'startTime': data.shifts.first.startTime,
        'isActive': data.shifts.first.isActive,
      } : null,
      onShiftTap: _navigationController.navigateToPlanning,
      onWeatherTap: () => _navigationController.showWeatherDetails(data.weather),
    );
  }
  
  /// Build responsive profile section
  Widget _buildProfileSection(DeviceType deviceType) {
    return DashboardHeaderSection(
      profileCompletion: _dataController.profileCompletion,
      onNavigateToProfile: _navigationController.navigateToProfile,
    );
  }
  
  /// Build responsive certificate section
  Widget _buildCertificateSection(DeviceType deviceType) {
    return CertificateAlertsSection(
      certificateAlerts: _dataController.certificateAlerts,
      expiringCertificates: _dataController.expiringCertificates,
      isLoading: _dataController.loadingCertificateAlerts,
      onNavigateToCertificates: _navigationController.navigateToCertificates,
      onDismissAlert: (id) {
        _dataController.dismissAlert(id);
        if (mounted) setState(() {});
      },
      onScheduleReminder: _dataController.scheduleRenewalReminder,
    );
  }
  
  /// Build responsive shifts section
  Widget _buildShiftsSection(
    List<dashboard_models.EnhancedShiftData> shifts,
    DeviceType deviceType,
  ) {
    return ShiftsManagementSection(shifts: shifts);
  }
  
  /// Build pending reviews section
  Widget _buildPendingReviewsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingS,
      ),
      child: PendingReviewsWidget(
        animationController: _animationController.controller,
      ),
    );
  }
  
  /// Build payment status section
  Widget _buildPaymentSection() {
    return FutureBuilder<PaymentStatusData>(
      future: _paymentService.getPaymentStatusData(AuthService.currentUserId),
      builder: (context, snapshot) {
        return ModernPaymentStatusWidget(
          animationController: _animationController.controller,
          data: snapshot.data,
          onViewAllPayments: () {
            // Navigate to payment details screen
            Navigator.pushNamed(context, '/payments');
          },
        );
      },
    );
  }
  
  /// Check if certificates should be shown
  bool _shouldShowCertificates() {
    return _dataController.certificateAlerts.isNotEmpty ||
           _dataController.expiringCertificates.isNotEmpty ||
           _dataController.loadingCertificateAlerts;
  }
  
  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: DesignTokens.guardPrimary,
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Dashboard laden...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: ResponsiveBreakpoints.getResponsiveFontSize(
                context,
                baseSize: DesignTokens.fontSizeBody,
              ),
              color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build error state
  Widget _buildErrorState(BeveiligerDashboardError errorState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.colorError,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Fout bij laden dashboard',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: ResponsiveBreakpoints.getResponsiveFontSize(
                  context,
                  baseSize: DesignTokens.fontSizeTitle,
                ),
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorError,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              errorState.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: ResponsiveBreakpoints.getResponsiveFontSize(
                  context,
                  baseSize: DesignTokens.fontSizeBody,
                ),
                color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ElevatedButton(
              onPressed: () {
                context.read<BeveiligerDashboardBloc>().add(const LoadDashboardData());
                _loadDashboardData();
              },
              child: Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build subscription status section
  Widget _buildSubscriptionSection() {
    final userId = AuthService.currentUserId;
    if (userId.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingS,
      ),
      child: SubscriptionStatusWidget(
        userId: userId,
        showDetails: false, // Compact view for dashboard
        onUpgradePressed: () => _navigateToSubscriptionUpgrade(),
      ),
    );
  }
  
  /// Navigate to subscription upgrade screen
  void _navigateToSubscriptionUpgrade() {
    final userId = AuthService.currentUserId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionUpgradeScreen(
          userId: userId.isNotEmpty ? userId : null,
        ),
      ),
    );
  }
}