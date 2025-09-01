import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/company_dashboard/services/company_service.dart';
import 'package:securyflex_app/company_dashboard/utils/company_layout_tokens.dart';
import 'package:securyflex_app/routing/app_routes.dart';


/// Comprehensive analytics screen for companies
/// Shows detailed metrics, trends, and performance data
class CompanyAnalyticsScreen extends StatefulWidget {
  final AnimationController? animationController;

  const CompanyAnalyticsScreen({
    super.key,
    this.animationController,
  });

  @override
  State<CompanyAnalyticsScreen> createState() => _CompanyAnalyticsScreenState();
}

class _CompanyAnalyticsScreenState extends State<CompanyAnalyticsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _analytics = {};
  late ScrollController scrollController;
  late AnimationController _localAnimationController;
  String _selectedPeriod = '30d'; // 7d, 30d, 90d, 1y

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _localAnimationController = widget.animationController ??
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    scrollController.dispose();
    if (widget.animationController == null) {
      _localAnimationController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simplified analytics loading
      final companyMetrics = await CompanyService.instance.getCompanyMetrics();
      final jobMetrics = await _getBasicJobMetrics();
      final applicationMetrics = await _getBasicApplicationMetrics();
      final performanceMetrics = await _getBasicPerformanceMetrics();

      if (mounted) {
        setState(() {
          _analytics = {
            'company': companyMetrics,
            'jobs': jobMetrics,
            'applications': applicationMetrics,
            'performance': performanceMetrics,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kon analytics niet laden';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getBasicJobMetrics() async {
    // Simplified job metrics for mobile-first approach
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'totalJobs': 127,
      'activeJobs': 5,
      'completedJobs': 122,
      'averageJobValue': 735.00,
      'jobSuccessRate': 96.1,
      'averageFillTime': 2.5, // days
      'jobsByType': {
        'Objectbeveiliging': 45,
        'Evenementbeveiliging': 32,
        'Persoonbeveiliging': 28,
        'Mobiele surveillance': 22,
      },
    };
  }

  Future<Map<String, dynamic>> _getBasicApplicationMetrics() async {
    // Simplified application metrics for mobile-first approach
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'totalApplications': 234,
      'pendingApplications': 12,
      'acceptedApplications': 156,
      'rejectedApplications': 66,
      'acceptanceRate': 70.3,
      'averageResponseTime': 1.8, // days
      'topApplicants': [
        {'name': 'Jan de Vries', 'applications': 8, 'acceptanceRate': 87.5},
        {'name': 'Maria Janssen', 'applications': 6, 'acceptanceRate': 83.3},
        {'name': 'Ahmed Hassan', 'applications': 7, 'acceptanceRate': 71.4},
      ],
    };
  }

  Future<Map<String, dynamic>> _getBasicPerformanceMetrics() async {
    // Simplified performance metrics for mobile-first approach
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'companyRating': 4.6,
      'totalReviews': 89,
      'repeatHireRate': 78.5,
      'guardSatisfaction': 4.4,
      'onTimeCompletion': 94.2,
      'costEfficiency': 87.3,
      'performanceAreas': {
        'Communicatie': 4.7,
        'Betrouwbaarheid': 4.6,
        'Professionaliteit': 4.5,
        'Betaling': 4.8,
        'Werksfeer': 4.4,
      },
    };
  }

  /// Company gradient header for analytics screen
  Widget getAppBarUI() {
    return UnifiedHeader.companyGradient(
      title: 'Analytics',
      showNotifications: true,
      onNotificationPressed: () => _navigateToNotifications(),
    );
  }

  void _navigateToNotifications() {
    // Navigate to notifications screen
    context.go(AppRoutes.companyNotifications);
  }





  /// Simple period selector with buttons for mobile-first approach
  Widget _buildPeriodSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPeriodButton('7d', 'Laatste 7 dagen'),
          _buildPeriodButton('30d', 'Laatste 30 dagen'),
          _buildPeriodButton('90d', 'Laatste 90 dagen'),
          _buildPeriodButton('1y', 'Laatste jaar'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
        child: isSelected
          ? UnifiedButton.primary(
              text: label.split(' ').last, // Show only the period part
              onPressed: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadAnalytics();
              },
            )
          : UnifiedButton.secondary(
              text: label.split(' ').last,
              onPressed: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadAnalytics();
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      color: companyColors.surfaceContainerHighest,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: getAppBarUI(),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      children: [
        // Period selector
        Container(
          color: companyColors.surface,
          padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
          child: _buildPeriodSelector(),
        ),
        // Content
        Expanded(
          child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: companyColors.primary),
              )
            : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: DesignTokens.colorError),
                      SizedBox(height: DesignTokens.spacingM),
                      Text(_errorMessage),
                      SizedBox(height: DesignTokens.spacingM),
                      UnifiedButton.primary(
                        text: 'Opnieuw proberen',
                        onPressed: _loadAnalytics,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: companyColors.primary,
                  child: SingleChildScrollView(
                    padding: CompanyLayoutTokens.contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewSection(),
                        CompanyLayoutTokens.largeSpacing,
                        _buildJobMetricsSection(),
                        CompanyLayoutTokens.largeSpacing,
                        _buildApplicationMetricsSection(),
                        CompanyLayoutTokens.largeSpacing,
                        _buildPerformanceMetricsSection(),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    final companyMetrics = _analytics['company'] as Map<String, dynamic>? ?? {};

    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Overzicht',
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Actieve Jobs',
                  '${companyMetrics['activeJobs'] ?? 0}',
                  Icons.work,
                  SecuryFlexTheme.getColorScheme(UserRole.company).primary,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: _buildMetricCard(
                  'Sollicitaties',
                  '${companyMetrics['pendingApplications'] ?? 0}',
                  Icons.people,
                  DesignTokens.colorWarning,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Maandelijkse Uitgaven',
                  NumberFormat.currency(locale: 'nl_NL', symbol: '€').format(companyMetrics['monthlySpent'] ?? 0),
                  Icons.euro,
                  DesignTokens.colorSuccess,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: _buildMetricCard(
                  'Bedrijfsrating',
                  '${companyMetrics['companyRating'] ?? 0.0}',
                  Icons.star,
                  DesignTokens.colorWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobMetricsSection() {
    final jobMetrics = _analytics['jobs'] as Map<String, dynamic>? ?? {};
    final jobsByType = jobMetrics['jobsByType'] as Map<String, dynamic>? ?? {};
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Job Performance',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key job metrics
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Totaal Jobs',
                  '${jobMetrics['totalJobs'] ?? 0}',
                  Icons.work_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Succesvol',
                  '${jobMetrics['completedJobs'] ?? 0}',
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Gem. Waarde',
                  NumberFormat.currency(locale: 'nl_NL', symbol: '€').format(jobMetrics['averageJobValue'] ?? 0),
                  Icons.euro_outlined,
                ),
              ),
            ],
          ),

          CompanyLayoutTokens.standardSpacing,

          // Job success rate
          Row(
            children: [
              Icon(Icons.trending_up, color: DesignTokens.colorSuccess, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Succespercentage: ${jobMetrics['jobSuccessRate'] ?? 0}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.colorSuccess,
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.spacingM),

          // Average fill time
          Row(
            children: [
              Icon(Icons.schedule, color: companyColors.primary, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Gem. invultijd: ${jobMetrics['averageFillTime'] ?? 0} dagen',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: companyColors.primary,
                ),
              ),
            ],
          ),

          if (jobsByType.isNotEmpty) ...[
            CompanyLayoutTokens.standardSpacing,
            Text(
              'Jobs per Type',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            ...jobsByType.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: companyColors.primaryContainer,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: companyColors.onPrimaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      children: [
        Icon(
          icon,
          color: companyColors.primary,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: companyColors.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: companyColors.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildApplicationMetricsSection() {
    final applicationMetrics = _analytics['applications'] as Map<String, dynamic>? ?? {};
    final topApplicants = applicationMetrics['topApplicants'] as List<dynamic>? ?? [];
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Sollicitatie Analytics',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application overview
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Totaal',
                  '${applicationMetrics['totalApplications'] ?? 0}',
                  Icons.people_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Geaccepteerd',
                  '${applicationMetrics['acceptedApplications'] ?? 0}',
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'In behandeling',
                  '${applicationMetrics['pendingApplications'] ?? 0}',
                  Icons.pending_outlined,
                ),
              ),
            ],
          ),

          CompanyLayoutTokens.standardSpacing,

          // Acceptance rate
          Row(
            children: [
              Icon(Icons.thumb_up, color: DesignTokens.colorSuccess, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Acceptatiepercentage: ${applicationMetrics['acceptanceRate'] ?? 0}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.colorSuccess,
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.spacingS),

          // Response time
          Row(
            children: [
              Icon(Icons.timer, color: companyColors.primary, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Gem. reactietijd: ${applicationMetrics['averageResponseTime'] ?? 0} dagen',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: companyColors.primary,
                ),
              ),
            ],
          ),

          if (topApplicants.isNotEmpty) ...[
            CompanyLayoutTokens.standardSpacing,
            Text(
              'Top Sollicitanten',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            ...topApplicants.take(3).map((applicant) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: DesignTokens.iconSizeM,
                    backgroundColor: companyColors.primaryContainer,
                    child: Text(
                      applicant['name'][0],
                      style: TextStyle(
                        color: companyColors.onPrimaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                        Text(
                          '${applicant['applications']} sollicitaties • ${applicant['acceptanceRate']}% geaccepteerd',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: companyColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsSection() {
    final performanceMetrics = _analytics['performance'] as Map<String, dynamic>? ?? {};
    final performanceAreas = performanceMetrics['performanceAreas'] as Map<String, dynamic>? ?? {};
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return CompanyLayoutTokens.buildStandardSection(
      context: context,
      title: 'Performance & Kwaliteit',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key performance indicators
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Bedrijfsrating',
                  '${performanceMetrics['companyRating'] ?? 0.0}',
                  Icons.star_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Herhaalaanstellingen',
                  '${performanceMetrics['repeatHireRate'] ?? 0}%',
                  Icons.repeat,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Op tijd voltooid',
                  '${performanceMetrics['onTimeCompletion'] ?? 0}%',
                  Icons.schedule_outlined,
                ),
              ),
            ],
          ),

          CompanyLayoutTokens.standardSpacing,

          // Guard satisfaction
          Row(
            children: [
              Icon(Icons.sentiment_satisfied, color: DesignTokens.colorSuccess, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Beveiligerstevredenheid: ${performanceMetrics['guardSatisfaction'] ?? 0.0}/5.0',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.colorSuccess,
                ),
              ),
            ],
          ),

          SizedBox(height: DesignTokens.spacingS),

          // Cost efficiency
          Row(
            children: [
              Icon(Icons.trending_up, color: companyColors.primary, size: DesignTokens.iconSizeM),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Kostenefficiëntie: ${performanceMetrics['costEfficiency'] ?? 0}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: companyColors.primary,
                ),
              ),
            ],
          ),

          if (performanceAreas.isNotEmpty) ...[
            CompanyLayoutTokens.standardSpacing,
            Text(
              'Performance per Gebied',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            ...performanceAreas.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${entry.value}/5.0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  LinearProgressIndicator(
                    value: (entry.value as double) / 5.0,
                    backgroundColor: companyColors.outline.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(entry.value as double),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return DesignTokens.statusConfirmed;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return DesignTokens.statusPending;
    if (rating >= 3.0) return Colors.deepOrange;
    return DesignTokens.statusCancelled;
  }


}
