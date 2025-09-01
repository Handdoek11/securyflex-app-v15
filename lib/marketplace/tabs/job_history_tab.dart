import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens

/// Job History Tab Component
/// Shows guard's completed work history and past assignments
/// Includes earnings, ratings, and performance feedback
/// Follows SecuryFlex unified design system and Dutch localization
class JobHistoryTab extends StatefulWidget {
  const JobHistoryTab({
    super.key,
    required this.animationController,
    this.onJobSelected, // Cross-tab navigation hook
  });

  final AnimationController animationController;
  final Function(String jobId)? onJobSelected; // For navigating to job details

  @override
  State<JobHistoryTab> createState() => _JobHistoryTabState();
}

class _JobHistoryTabState extends State<JobHistoryTab> {
  List<CompletedJobData> _completedJobs = [];
  List<CompletedJobData> _filteredJobs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedJobType;
  String? _selectedCompany;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadJobHistory();
  }

  void _loadJobHistory() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Simulate loading delay
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _completedJobs = CompletedJobData.mockCompletedJobs;
          _updateFilteredJobs();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transparant voor gradient achtergrond
    return Theme(
      data: SecuryFlexTheme.getTheme(UserRole.guard),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Werkgeschiedenis laden...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: DesignTokens.statusCancelled),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.statusCancelled,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            UnifiedButton.secondary(
              text: 'Opnieuw proberen',
              onPressed: _loadJobHistory,
            ),
          ],
        ),
      );
    }

    if (_completedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: DesignTokens.colorGray500),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Nog geen voltooide opdrachten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Je werkgeschiedenis verschijnt hier zodra je\nje eerste opdracht hebt voltooid.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: 'Zoek nieuwe opdrachten',
              onPressed: () {
                // Cross-tab navigation hook - switch to Jobs tab
                if (widget.onJobSelected != null) {
                  widget.onJobSelected!(''); // Empty string indicates switch to jobs tab
                }
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadJobHistory(),
      child: Column(
        children: [
          _buildSummaryHeader(),
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredJobs.length,
              padding: EdgeInsets.only(
                top: DesignTokens.spacingS,
                bottom: DesignTokens.spacingL,
              ),
              itemBuilder: (context, index) {
                // Dashboard-style staggered animation
                final int count = _filteredJobs.length > 8 ? 8 : _filteredJobs.length;
                final Animation<double> animation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: widget.animationController,
                        curve: Interval(
                          (1 / count) * (index % count),
                          1.0,
                          curve: Curves.fastOutSlowIn,
                        ),
                      ),
                    );

                widget.animationController.forward();

                return JobHistoryContainer(
                  animationController: widget.animationController,
                  animation: animation,
                  child: _buildJobHistoryCard(_filteredJobs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final totalEarnings = _completedJobs.fold<double>(
      0.0,
      (sum, job) => sum + job.totalEarnings,
    );
    final totalHours = _completedJobs.fold<double>(
      0.0,
      (sum, job) => sum + job.hoursWorked,
    );
    final averageRating = _completedJobs.isNotEmpty
        ? _completedJobs.fold<double>(0.0, (sum, job) => sum + job.rating) / _completedJobs.length
        : 0.0;

    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Werkgeschiedenis Overzicht',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Voltooide Jobs',
                  '${_completedJobs.length}',
                  Icons.work_history,
                  DesignTokens.statusAccepted,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Totaal Verdiend',
                  '€${totalEarnings.toStringAsFixed(0)}',
                  Icons.euro,
                  DesignTokens.statusConfirmed,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Uren Gewerkt',
                  '${totalHours.toStringAsFixed(0)}h',
                  Icons.schedule,
                  DesignTokens.statusPending,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Gem. Beoordeling',
                  '${averageRating.toStringAsFixed(1)} ⭐',
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.colorGray600,
            fontFamily: DesignTokens.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: SecuryFlexTheme.getColorScheme(UserRole.guard).surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        boxShadow: [DesignTokens.shadowLight],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_filteredJobs.length} van ${_completedJobs.length} opdrachten',
              style: TextStyle(
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray700,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          UnifiedButton.secondary(
            text: 'Filters',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Werkgeschiedenis',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Job Type Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedJobType,
              decoration: InputDecoration(
                labelText: 'Job Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Alle types')),
                DropdownMenuItem(value: 'Objectbeveiliging', child: Text('Objectbeveiliging')),
                DropdownMenuItem(value: 'Evenementbeveiliging', child: Text('Evenementbeveiliging')),
                DropdownMenuItem(value: 'Persoonbeveiliging', child: Text('Persoonbeveiliging')),
                DropdownMenuItem(value: 'Surveillance', child: Text('Surveillance')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedJobType = value;
                });
              },
            ),
            SizedBox(height: DesignTokens.spacingM),
            // Company Filter
            DropdownButtonFormField<String>(
              initialValue: _selectedCompany,
              decoration: InputDecoration(
                labelText: 'Bedrijf',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('Alle bedrijven')),
                ...CompletedJobData.mockCompletedJobs
                    .map((job) => job.companyName)
                    .toSet()
                    .map((company) => DropdownMenuItem(
                          value: company,
                          child: Text(company),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCompany = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedJobType = null;
                _selectedCompany = null;
                _selectedDateRange = null;
                _updateFilteredJobs();
              });
              Navigator.pop(context);
            },
            child: Text('Reset'),
          ),
          UnifiedButton.primary(
            text: 'Toepassen',
            onPressed: () {
              _updateFilteredJobs();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _updateFilteredJobs() {
    _filteredJobs = _completedJobs.where((job) {
      // Job type filter
      if (_selectedJobType != null && job.jobType != _selectedJobType) {
        return false;
      }

      // Company filter
      if (_selectedCompany != null && job.companyName != _selectedCompany) {
        return false;
      }

      // Date range filter
      if (_selectedDateRange != null) {
        if (job.completionDate.isBefore(_selectedDateRange!.start) ||
            job.completionDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by completion date (most recent first)
    _filteredJobs.sort((a, b) => b.completionDate.compareTo(a.completionDate));
  }

  Widget _buildJobHistoryCard(CompletedJobData job) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      job.companyName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.100),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  'Voltooid',
                  style: TextStyle(
                    color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: DesignTokens.colorGray600),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Voltooid op ${DateFormat('dd MMM yyyy', 'nl_NL').format(job.completionDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: DesignTokens.colorGray600),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '${job.hoursWorked.toStringAsFixed(1)} uur gewerkt',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              Spacer(),
              Icon(Icons.euro, size: 16, color: DesignTokens.statusConfirmed.withValues(alpha: 0.600)),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '€${job.totalEarnings.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber.withValues(alpha: 0.600)),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '${job.rating.toStringAsFixed(1)} sterren',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              if (job.feedback.isNotEmpty) ...[
                Spacer(),
                Icon(Icons.comment, size: 16, color: DesignTokens.statusAccepted.withValues(alpha: 0.600)),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Feedback',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.statusAccepted.withValues(alpha: 0.600),
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ],
          ),
          if (job.feedback.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.statusAccepted.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(color: DesignTokens.statusAccepted.withValues(alpha: 0.200)),
              ),
              child: Text(
                job.feedback,
                style: TextStyle(
                  color: DesignTokens.statusAccepted.withValues(alpha: 0.700),
                  fontSize: DesignTokens.fontSizeS,
                  fontFamily: DesignTokens.fontFamily,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Job History Container widget for animations
class JobHistoryContainer extends StatelessWidget {
  final Widget child;
  final AnimationController? animationController;
  final Animation<double>? animation;

  const JobHistoryContainer({
    super.key,
    required this.child,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return AnimatedBuilder(
      animation: animationController ?? AlwaysStoppedAnimation(1.0),
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation ?? AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - (animation?.value ?? 1.0)),
              0.0,
            ),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: this.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Completed Job Data Model
class CompletedJobData {
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String location;
  final String jobType;
  final DateTime completionDate;
  final DateTime startDate;
  final double hoursWorked;
  final double hourlyRate;
  final double totalEarnings;
  final double rating;
  final String feedback;
  final List<String> certificatesUsed;

  const CompletedJobData({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.jobType,
    required this.completionDate,
    required this.startDate,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.totalEarnings,
    required this.rating,
    required this.feedback,
    required this.certificatesUsed,
  });

  static List<CompletedJobData> mockCompletedJobs = [
    CompletedJobData(
      jobId: 'CJ001',
      jobTitle: 'Objectbeveiliging Kantoorcomplex',
      companyName: 'Amsterdam Security Partners',
      location: 'Amsterdam Zuidas',
      jobType: 'Objectbeveiliging',
      completionDate: DateTime.now().subtract(Duration(days: 3)),
      startDate: DateTime.now().subtract(Duration(days: 3, hours: 8)),
      hoursWorked: 8.0,
      hourlyRate: 24.50,
      totalEarnings: 196.00,
      rating: 4.8,
      feedback: 'Uitstekende beveiliger! Zeer professioneel en alert tijdens de dienst.',
      certificatesUsed: ['Beveiligingsdiploma A', 'BHV'],
    ),
    CompletedJobData(
      jobId: 'CJ002',
      jobTitle: 'Evenementbeveiliging Concerthal',
      companyName: 'Rotterdam Event Security',
      location: 'Rotterdam Centrum',
      jobType: 'Evenementbeveiliging',
      completionDate: DateTime.now().subtract(Duration(days: 7)),
      startDate: DateTime.now().subtract(Duration(days: 7, hours: 6)),
      hoursWorked: 6.0,
      hourlyRate: 28.00,
      totalEarnings: 168.00,
      rating: 4.6,
      feedback: 'Goede communicatie met bezoekers en effectieve crowd control.',
      certificatesUsed: ['Beveiligingsdiploma B', 'BHV'],
    ),
    CompletedJobData(
      jobId: 'CJ003',
      jobTitle: 'Persoonbeveiliging VIP',
      companyName: 'Den Haag Executive Protection',
      location: 'Den Haag Centrum',
      jobType: 'Persoonbeveiliging',
      completionDate: DateTime.now().subtract(Duration(days: 14)),
      startDate: DateTime.now().subtract(Duration(days: 14, hours: 10)),
      hoursWorked: 10.0,
      hourlyRate: 35.00,
      totalEarnings: 350.00,
      rating: 5.0,
      feedback: 'Uitzonderlijk professioneel. Discrete en effectieve bescherming.',
      certificatesUsed: ['Beveiligingsdiploma B', 'BHV', 'Rijbewijs B'],
    ),
    CompletedJobData(
      jobId: 'CJ004',
      jobTitle: 'Surveillance Winkelcentrum',
      companyName: 'Utrecht Retail Security',
      location: 'Utrecht Centrum',
      jobType: 'Surveillance',
      completionDate: DateTime.now().subtract(Duration(days: 21)),
      startDate: DateTime.now().subtract(Duration(days: 21, hours: 8)),
      hoursWorked: 8.0,
      hourlyRate: 22.50,
      totalEarnings: 180.00,
      rating: 4.4,
      feedback: 'Goede observatievaardigheden en tijdige rapportage van incidenten.',
      certificatesUsed: ['Beveiligingsdiploma A'],
    ),
    CompletedJobData(
      jobId: 'CJ005',
      jobTitle: 'Objectbeveiliging Ziekenhuis',
      companyName: 'Eindhoven Healthcare Security',
      location: 'Eindhoven',
      jobType: 'Objectbeveiliging',
      completionDate: DateTime.now().subtract(Duration(days: 28)),
      startDate: DateTime.now().subtract(Duration(days: 28, hours: 12)),
      hoursWorked: 12.0,
      hourlyRate: 26.00,
      totalEarnings: 312.00,
      rating: 4.7,
      feedback: 'Empathische benadering van patiënten en bezoekers. Zeer betrouwbaar.',
      certificatesUsed: ['Beveiligingsdiploma A', 'BHV', 'VCA'],
    ),
  ];
}
