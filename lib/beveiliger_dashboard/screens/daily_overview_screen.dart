import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/beveiliger_dashboard/models/daily_overview_data.dart';
import 'package:securyflex_app/beveiliger_dashboard/services/daily_overview_service.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';
import 'package:intl/intl.dart';

/// Detailed Daily Overview Screen for Guards
/// Provides comprehensive daily metrics, earnings, and planning information
class DailyOverviewScreen extends StatefulWidget {
  final AnimationController? animationController;

  const DailyOverviewScreen({super.key, this.animationController});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  DailyOverviewData? _overviewData;
  bool _isLoading = true;
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _loadDailyOverview();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await DailyOverviewService.instance.getDailyOverview();
      if (mounted) {
        setState(() {
          _overviewData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Kon dagelijks overzicht niet laden. Probeer het opnieuw.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    _refreshController.forward();

    try {
      await DailyOverviewService.instance.refreshData();
      final data = await DailyOverviewService.instance.getDailyOverview();

      if (mounted) {
        setState(() {
          _overviewData = data;
          _errorMessage = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: DesignTokens.colorWhite, size: 20),
                SizedBox(width: DesignTokens.spacingS),
                Text('Gegevens bijgewerkt'),
              ],
            ),
            backgroundColor: DesignTokens.colorSuccess,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: DesignTokens.colorWhite, size: 20),
                SizedBox(width: DesignTokens.spacingS),
                Text('Kon gegevens niet bijwerken'),
              ],
            ),
            backgroundColor: DesignTokens.colorError,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _refreshController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final today = DateFormat('EEEE d MMMM', 'nl_NL').format(DateTime.now());

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: Column(
          children: [
            _buildHeader(colorScheme, today),
            Expanded(child: _buildBody(colorScheme)),
          ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, String today) {
    return UnifiedHeader.animated(
      title: 'Uren & Verdiensten',
      animationController: widget.animationController!,
      scrollController: _scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.guard,
      titleAlignment: TextAlign.left,
      leading: HeaderElements.backButton(
        userRole: UserRole.guard,
        onPressed: () => context.pop(),
      ),
      actions: [
        AnimatedBuilder(
          animation: _refreshAnimation,
          builder: (context, child) {
            return IconButton(
              onPressed: _isLoading ? null : _refreshData,
              icon: Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: Icon(
                  Icons.refresh,
                  color: _isLoading
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              tooltip: 'Ververs gegevens',
              splashRadius: 20,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return _buildLoadingState(colorScheme);
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState(colorScheme);
    }

    if (_overviewData == null) {
      return _buildEmptyState(colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card - Belangrijkste metrics met speciale styling
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: DesignTokens.spacingL),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radiusM),
                  bottomLeft: Radius.circular(DesignTokens.radiusM),
                  bottomRight: Radius.circular(DesignTokens.radiusM),
                  topRight: Radius.circular(
                    68.0,
                  ), // ✅ Speciale radius zoals dashboard
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: const Offset(0, 2),
                    blurRadius: 8.0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  children: [
                    // Daily Metrics - Raw content zonder eigen container
                    _buildDailyMetricsContent(),

                    SizedBox(height: DesignTokens.spacingL),

                    // Earnings Breakdown - Raw content zonder eigen container
                    _buildEarningsContent(),
                  ],
                ),
              ),
            ),

            // Individual cards voor details - Dashboard style
            _buildDetailCard(child: _buildTimeTrackingContent()),

            SizedBox(height: DesignTokens.spacingM),

            _buildDetailCard(child: _buildPlanningContent()),

            // Conditional cards - ALLE met pure content
            if (_overviewData!.todaysAchievements.isNotEmpty ||
                _overviewData!.clientSatisfactionScore >= 4.0) ...[
              SizedBox(height: DesignTokens.spacingM),
              _buildDetailCard(child: _buildPerformanceContent()),
            ],

            if (_overviewData!.urgentNotifications.isNotEmpty ||
                _overviewData!.reminders.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spacingM),
              _buildDetailCard(child: _buildNotificationsContent()),
            ],

            SizedBox(height: DesignTokens.spacingXL),
          ],
        ),
      ),
    );
  }

  /// Build daily metrics content without container wrapper
  Widget _buildDailyMetricsContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.dashboard,
                color: colorScheme.onPrimaryContainer,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vandaag\'s Overzicht',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Text(
                    _overviewData!.currentShiftStatus,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Metrics grid - simplified for hero card
        _buildSimplifiedMetrics(colorScheme, currencyFormat),
      ],
    );
  }

  /// Build earnings content without container wrapper
  Widget _buildEarningsContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.euro,
                color: DesignTokens.colorSuccess,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Text(
              'Verdiensten Overzicht',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSection,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),
        // Simplified earnings display
        Text(
          'Vandaag Verdiend',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          currencyFormat.format(_overviewData!.earningsToday),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: DesignTokens.colorSuccess,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
      ],
    );
  }

  /// Build simplified metrics for hero card
  Widget _buildSimplifiedMetrics(
    ColorScheme colorScheme,
    NumberFormat currencyFormat,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            icon: Icons.access_time,
            label: 'Uren',
            value: '${_overviewData!.hoursWorkedToday.toStringAsFixed(1)}u',
            color: colorScheme.primary,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildMetricItem(
            icon: Icons.work,
            label: 'Shifts',
            value: '${_overviewData!.completedShiftsToday}',
            color: DesignTokens.colorInfo,
          ),
        ),
      ],
    );
  }

  /// Build metric item for hero card
  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeM),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build time tracking content without container wrapper
  Widget _buildTimeTrackingContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.access_time,
                color: colorScheme.onPrimaryContainer,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tijd Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Text(
                    _overviewData!.isCurrentlyWorking
                        ? 'Actief aan het werk'
                        : 'Niet actief',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _overviewData!.isCurrentlyWorking
                          ? DesignTokens.colorSuccess
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),

        // Time breakdown
        if (_overviewData!.isCurrentlyWorking) ...[
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: DesignTokens.colorSuccess,
                  size: DesignTokens.iconSizeL,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Huidige Shift',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: DesignTokens.colorSuccess,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                      ),
                      Text(
                        _overviewData!.currentShiftStart != null
                            ? '${DateTime.now().difference(_overviewData!.currentShiftStart!).inHours}:${(DateTime.now().difference(_overviewData!.currentShiftStart!).inMinutes % 60).toString().padLeft(2, '0')}'
                            : '0:00',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: DesignTokens.colorSuccess,
                              fontWeight: DesignTokens.fontWeightBold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
        ],

        // Daily summary
        Row(
          children: [
            Expanded(
              child: _buildTimeMetric(
                'Vandaag',
                '${_overviewData!.hoursWorkedToday.toStringAsFixed(1)}u',
                Icons.today,
                colorScheme.primary,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildTimeMetric(
                'Deze Week',
                '${_overviewData!.weeklyHoursWorked.toStringAsFixed(1)}u',
                Icons.calendar_view_week,
                DesignTokens.colorInfo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build planning content without container wrapper
  Widget _buildPlanningContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.colorInfo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.calendar_today,
                color: DesignTokens.colorInfo,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planning Overzicht',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSection,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  Text(
                    'Komende shifts en planning',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),

        // Today's shifts
        if (_overviewData!.todaysShifts.isNotEmpty) ...[
          Text(
            'Vandaag (${_overviewData!.todaysShifts.length} shifts)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ..._overviewData!.todaysShifts
              .take(2)
              .map(
                (shift) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                  child: Container(
                    padding: EdgeInsets.all(DesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: DesignTokens.colorInfo,
                          size: DesignTokens.iconSizeS,
                        ),
                        SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            shift.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ] else ...[
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    'Geen shifts gepland voor vandaag',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build time metric item
  Widget _buildTimeMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeM),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build performance content without container wrapper
  Widget _buildPerformanceContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.trending_up,
                color: DesignTokens.colorSuccess,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prestatie Indicatoren',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Text(
                    'Jouw prestaties vandaag',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),

        // Performance metrics
        Row(
          children: [
            Expanded(
              child: _buildPerformanceMetric(
                'Punctualiteit',
                '${(_overviewData!.punctualityScore * 100).toInt()}%',
                Icons.schedule,
                DesignTokens.colorSuccess,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: _buildPerformanceMetric(
                'Klanttevredenheid',
                '${_overviewData!.clientSatisfactionScore.toStringAsFixed(1)}/5',
                Icons.star,
                DesignTokens.colorWarning,
              ),
            ),
          ],
        ),

        if (_overviewData!.todaysAchievements.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Vandaag Behaald',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ..._overviewData!.todaysAchievements
              .take(3)
              .map(
                (achievement) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: DesignTokens.colorSuccess,
                        size: DesignTokens.iconSizeS,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          achievement,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }

  /// Build notifications content without container wrapper
  Widget _buildNotificationsContent() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.colorWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Icon(
                Icons.notifications_active,
                color: DesignTokens.colorWarning,
                size: DesignTokens.iconSizeM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meldingen & Herinneringen',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeSection,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  Text(
                    'Belangrijke updates voor jou',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingL),

        // Urgent notifications
        if (_overviewData!.urgentNotifications.isNotEmpty) ...[
          Text(
            'Urgent',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DesignTokens.colorError,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ..._overviewData!.urgentNotifications.map(
            (notification) => Container(
              margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: DesignTokens.colorError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(
                  color: DesignTokens.colorError.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    color: DesignTokens.colorError,
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      notification,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.colorError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Regular reminders
        if (_overviewData!.reminders.isNotEmpty) ...[
          if (_overviewData!.urgentNotifications.isNotEmpty)
            SizedBox(height: DesignTokens.spacingM),
          Text(
            'Herinneringen',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          ..._overviewData!.reminders
              .take(3)
              .map(
                (reminder) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: DesignTokens.colorInfo,
                        size: DesignTokens.iconSizeS,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          reminder,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }

  /// Build performance metric item
  Widget _buildPerformanceMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeM),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build detail card with dashboard-style container
  Widget _buildDetailCard({required Widget child}) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SizedBox(
      width: double.infinity,
      child: UnifiedCard.standard(
        userRole: UserRole.guard,
        padding: EdgeInsets.all(DesignTokens.spacingL),
        backgroundColor: colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusM),
              bottomLeft: Radius.circular(DesignTokens.radiusM),
              bottomRight: Radius.circular(DesignTokens.radiusM),
              topRight: Radius.circular(
                32.0,
              ), // Kleinere speciale radius voor detail cards
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Dagelijks overzicht laden...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: DesignTokens.colorError),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Oeps!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ElevatedButton.icon(
              onPressed: _loadDailyOverview,
              icon: Icon(Icons.refresh),
              label: Text('Opnieuw proberen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Geen gegevens beschikbaar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Er zijn momenteel geen dagelijkse gegevens beschikbaar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
