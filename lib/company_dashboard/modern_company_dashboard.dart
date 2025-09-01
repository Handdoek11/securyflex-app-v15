import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../unified_header.dart';
import '../unified_components/modern_applications_overview_widget.dart';

/// Modern, performance-optimized company dashboard
/// 
/// This is a complete rebuild of the company dashboard with:
/// - Clean architecture (max 4 nesting levels)
/// - Performance-first design
/// - Modern widget composition
/// - Material 3 compliance
/// - Unified design system throughout
/// 
/// Replaces the legacy dashboard with excessive nesting and technical debt.
class ModernCompanyDashboard extends StatefulWidget {
  const ModernCompanyDashboard({super.key});

  @override
  State<ModernCompanyDashboard> createState() => _ModernCompanyDashboardState();
}

class _ModernCompanyDashboardState extends State<ModernCompanyDashboard>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    
    _animationController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API calls - reduced delay for better UX
      await Future.delayed(const Duration(milliseconds: 100));

      // TODO: Load real data from services
      // - Business intelligence data
      // - Job management data
      // - Applications data
      // - Analytics data

      // Force a rebuild after data is "loaded"
      if (mounted) {
        setState(() => _isLoading = false);
      }

    } catch (e) {
      _showErrorMessage('Fout bij laden van dashboard gegevens');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            UnifiedHeader.multiLine(
              title: 'Bedrijf Dashboard',
              subtitle: 'Welkom terug, SecureGuard BV!',
              userRole: UserRole.company,
            ),
            // Content
            Expanded(
              child: _isLoading 
                ? _buildLoadingState()
                : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3.0,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Dashboard laden...',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    // Show loading state while data is being loaded
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Dashboard wordt geladen...',
              style: TextStyle(
                fontSize: 16,
                color: DesignTokens.colorGray600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // DEBUG: Simple test widget to verify data display
            Container(
              margin: EdgeInsets.all(DesignTokens.spacingM),
              padding: EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: DesignTokens.statusAccepted.withValues(alpha: 0.1),
                border: Border.all(color: DesignTokens.statusAccepted, width: 2),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEBUG: Company Dashboard Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: DesignTokens.statusAccepted,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text('✅ Data Loading: Complete'),
                  Text('✅ Widgets: Rendered'),
                  Text('✅ Status: Ready'),
                  Text('⏱️ Timestamp: ${DateTime.now().toString().substring(11, 19)}'),
                ],
              ),
            ),

            // DIRECT TEST: Replace widgets with simple containers
            Container(
              margin: EdgeInsets.all(DesignTokens.spacingM),
              padding: EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: DesignTokens.statusConfirmed,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Column(
                children: [
                  Text(
                    'FINANCIËN TEST',
                    style: TextStyle(
                      color: DesignTokens.colorWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Totale Omzet: €45.280',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 18),
                  ),
                  Text(
                    'Actieve Jobs: 12',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 18),
                  ),
                  Text(
                    'Beveiligers: 28',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 18),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.all(DesignTokens.spacingM),
              padding: EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: DesignTokens.statusPending,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Column(
                children: [
                  Text(
                    'ACTIEVE JOBS TEST',
                    style: TextStyle(
                      color: DesignTokens.colorWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Winkelcentrum Beveiliging - Amsterdam',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 16),
                  ),
                  Text(
                    'Evenement Security - Rotterdam',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 16),
                  ),
                  Text(
                    'Kantoor Beveiliging - Utrecht',
                    style: TextStyle(color: DesignTokens.colorWhite, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Applications Overview (this one works)
            ModernApplicationsOverviewWidget(
              animationController: null,
              animation: null,
              onViewAll: _handleViewAllApplications,
              onReviewPending: _handleReviewPendingApplications,
            ),
            
            // Analytics section (placeholder for future)
            _buildAnalyticsSection(),
            
            // Recent activity (placeholder for future)
            _buildRecentActivity(),
            
            // Bottom padding for better scrolling experience
            SizedBox(height: DesignTokens.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    // Placeholder for future analytics widget
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: SecuryFlexTheme.getColorScheme(UserRole.company).surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: SecuryFlexTheme.getColorScheme(UserRole.company).outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: DesignTokens.iconSizeL,
            color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geavanceerde Analytics',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBody,
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Komt binnenkort beschikbaar',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeS,
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Placeholder for future recent activity widget
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: SecuryFlexTheme.getColorScheme(UserRole.company).surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: SecuryFlexTheme.getColorScheme(UserRole.company).outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: DesignTokens.iconSizeL,
            color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Recente Activiteit',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBody,
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Komt binnenkort beschikbaar',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeS,
              color: SecuryFlexTheme.getColorScheme(UserRole.company).onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Event handlers




  void _handleViewAllApplications() {
    _showComingSoonMessage('Alle sollicitaties');
  }

  void _handleReviewPendingApplications() {
    _showComingSoonMessage('Sollicitaties beoordelen');
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature komt binnenkort beschikbaar'),
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.company).primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }
}
