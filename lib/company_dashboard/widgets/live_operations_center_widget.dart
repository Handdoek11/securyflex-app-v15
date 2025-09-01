import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_theme_system.dart';
// CompanyDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/company_dashboard/models/business_intelligence_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart'
    show GuardAvailabilityStatus;
import 'package:securyflex_app/company_dashboard/services/guard_performance_service.dart';
import 'package:securyflex_app/company_dashboard/services/client_satisfaction_service.dart';
import 'package:securyflex_app/company_dashboard/utils/company_layout_tokens.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';

/// Live Operations Center Widget for real-time business intelligence monitoring
/// Provides comprehensive real-time dashboard with guard tracking, incidents, and alerts
class LiveOperationsCenterWidget extends StatefulWidget {
  final AnimationController animationController;
  final Animation<double> animation;

  const LiveOperationsCenterWidget({
    super.key,
    required this.animationController,
    required this.animation,
  });

  @override
  State<LiveOperationsCenterWidget> createState() =>
      _LiveOperationsCenterWidgetState();
}

class _LiveOperationsCenterWidgetState
    extends State<LiveOperationsCenterWidget> {
  final String _companyId = 'COMP001';
  LiveDashboardMetrics? _liveMetrics;
  Map<String, GuardAvailabilityStatus>? _guardAvailability;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveData();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    // Clean up real-time subscriptions
    GuardPerformanceService.instance.dispose();
    ClientSatisfactionService.instance.dispose();
    super.dispose();
  }

  Future<void> _loadLiveData() async {
    try {
      final guardAvailability = await GuardPerformanceService.instance
          .getGuardAvailabilityHeatmap(_companyId);
      final guardStats = await GuardPerformanceService.instance
          .getGuardUtilizationStats(_companyId);
      final overallNPS = await ClientSatisfactionService.instance.getOverallNPS(
        _companyId,
      );

      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _guardAvailability = guardAvailability;
          _liveMetrics = LiveDashboardMetrics(
            activeGuards: guardStats['active_guards'] ?? 0,
            availableGuards: guardStats['available_guards'] ?? 0,
            ongoingJobs: 8, // Mock data
            emergencyAlerts: 0,
            currentDayRevenue: 1250.0,
            averageClientSatisfaction:
                overallNPS / 20.0, // Convert NPS to 0-5 scale
            pendingApplications: 12,
            complianceIssues: 2,
            lastUpdated: DateTime.now(),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startRealtimeUpdates() {
    // Start real-time monitoring services
    GuardPerformanceService.instance.startRealtimeMonitoring(_companyId);
    ClientSatisfactionService.instance.startRealtimeMonitoring(_companyId);

    // Listen to real-time updates
    GuardPerformanceService.instance.availabilityStream.listen((availability) {
      if (mounted) {
        setState(() {
          _guardAvailability = availability;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - widget.animation.value),
              0.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with real-time indicator
                Row(
                  children: [
                    Icon(
                      Icons.radar,
                      color: DesignTokens.companyTeal,
                      size: DesignTokens.iconSizeL,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Operations Center',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  color: DesignTokens.darkText,
                                ),
                          ),
                          SizedBox(height: DesignTokens.spacingXS),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: DesignTokens.colorSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: DesignTokens.spacingXS),
                              Expanded(
                                child: Text(
                                  'Live - Laatste update: ${_formatTime(DateTime.now())}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: DesignTokens.lightText),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadLiveData,
                      icon: Icon(
                        Icons.refresh,
                        color: DesignTokens.companyTeal,
                        size: DesignTokens.iconSizeM,
                      ),
                    ),
                  ],
                ),

                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: DesignTokens.spacingXL,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.companyTeal,
                      ),
                    ),
                  )
                else ...[
                  SizedBox(height: DesignTokens.spacingL),

                  // Live metrics grid
                  _buildLiveMetricsGrid(context),

                  SizedBox(height: DesignTokens.spacingL),

                  // Guard availability heatmap
                  _buildGuardAvailabilitySection(context),

                  SizedBox(height: DesignTokens.spacingL),

                  // Emergency alerts and compliance status
                  _buildAlertsSection(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveMetricsGrid(BuildContext context) {
    if (_liveMetrics == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 900;

        // Determine grid layout based on screen size
        int crossAxisCount;
        double childAspectRatio;
        double spacing;

        if (isMobile) {
          crossAxisCount = 2;
          childAspectRatio = 1.2;
          spacing = DesignTokens.spacingS;
        } else if (isTablet) {
          crossAxisCount = 3;
          childAspectRatio = 1.1;
          spacing = DesignTokens.spacingS;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.0;
          spacing = DesignTokens.spacingXS;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          children: [
            _buildMetricCard(
              context,
              icon: Icons.security,
              value: '${_liveMetrics!.activeGuards}',
              label: 'Actieve Beveiligers',
              color: DesignTokens.companyTeal,
            ),
            _buildMetricCard(
              context,
              icon: Icons.work,
              value: '${_liveMetrics!.ongoingJobs}',
              label: 'Lopende Jobs',
              color: DesignTokens.colorInfo,
            ),
            _buildMetricCard(
              context,
              icon: Icons.euro,
              value: '€${_liveMetrics!.currentDayRevenue.toStringAsFixed(0)}',
              label: 'Vandaag',
              color: DesignTokens.colorSuccess,
            ),
            _buildMetricCard(
              context,
              icon: Icons.star,
              value: _liveMetrics!.averageClientSatisfaction.toStringAsFixed(1),
              label: 'Tevredenheid',
              color: DesignTokens.colorWarning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(
            isMobile ? DesignTokens.spacingXS : DesignTokens.spacingS,
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 80 : 100,
              maxHeight: isMobile ? 120 : 140,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isMobile
                      ? DesignTokens.iconSizeS
                      : DesignTokens.iconSizeM,
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                      color: color,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: isMobile ? 10 : 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuardAvailabilitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beveiliger Beschikbaarheid',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildAvailabilityHeatmap(context),
      ],
    );
  }

  Widget _buildAvailabilityHeatmap(BuildContext context) {
    if (_guardAvailability == null) return const SizedBox.shrink();

    final statusCounts = <GuardAvailabilityStatus, int>{};
    for (final status in _guardAvailability!.values) {
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        final statusIndicators = [
          _buildStatusIndicator(
            context,
            'Beschikbaar',
            statusCounts[GuardAvailabilityStatus.available] ?? 0,
            DesignTokens.colorSuccess,
          ),
          _buildStatusIndicator(
            context,
            'Aan het werk',
            statusCounts[GuardAvailabilityStatus.onDuty] ?? 0,
            DesignTokens.colorInfo,
          ),
          _buildStatusIndicator(
            context,
            'Pauze',
            statusCounts[GuardAvailabilityStatus.busy] ?? 0,
            DesignTokens.colorWarning,
          ),
          _buildStatusIndicator(
            context,
            'Offline',
            statusCounts[GuardAvailabilityStatus.unavailable] ?? 0,
            DesignTokens.colorGray500,
          ),
        ];

        if (isMobile) {
          // Mobile: 2x2 grid
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: statusIndicators[0]),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: statusIndicators[1]),
                ],
              ),
              SizedBox(height: DesignTokens.spacingS),
              Row(
                children: [
                  Expanded(child: statusIndicators[2]),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: statusIndicators[3]),
                ],
              ),
            ],
          );
        } else {
          // Tablet/Desktop: Single row
          return Row(
            children: statusIndicators
                .expand(
                  (indicator) => [
                    Expanded(child: indicator),
                    if (indicator != statusIndicators.last)
                      SizedBox(width: DesignTokens.spacingS),
                  ],
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingS),
      backgroundColor: color.withValues(alpha: 0.1),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAlertCard(
            context,
            icon: Icons.warning,
            title: 'Noodmeldingen',
            value: '${_liveMetrics?.emergencyAlerts ?? 0}',
            color: _liveMetrics?.emergencyAlerts == 0
                ? DesignTokens.colorSuccess
                : DesignTokens.colorError,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildAlertCard(
            context,
            icon: Icons.assignment_late,
            title: 'Compliance Issues',
            value: '${_liveMetrics?.complianceIssues ?? 0}',
            color: _liveMetrics?.complianceIssues == 0
                ? DesignTokens.colorSuccess
                : DesignTokens.colorWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = context.screenWidth;
        final isMobile = screenWidth < 600;

        return UnifiedCard.standard(
          userRole: UserRole.company,
          padding: CompanyLayoutTokens.cardPadding,
          backgroundColor: color.withValues(alpha: 0.1),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: isMobile ? 60 : 80,
              maxHeight: isMobile ? 100 : 120,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isMobile
                      ? DesignTokens.iconSizeM
                      : DesignTokens.iconSizeL,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                          color: color,
                          fontSize: isMobile ? 18 : 22,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontSize: isMobile ? 11 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
