import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';
import '../../unified_components/premium_glass_system.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens

import '../utils/date_utils.dart';

/// Timesheet Tab Component
/// Provides comprehensive time tracking and earnings management for guards
/// Features current shift timer, hours summary, earnings calculation, and export functionality
/// Integrates with shift completion workflow and payroll systems
/// Follows SecuryFlex unified design system and Dutch localization
class TimesheetTab extends StatefulWidget {
  const TimesheetTab({
    super.key,
    required this.animationController,
    this.onShiftStatusChanged, // Callback for shift status updates
  });

  final AnimationController animationController;
  final Function(bool isOnShift)? onShiftStatusChanged;

  @override
  State<TimesheetTab> createState() => _TimesheetTabState();
}

class _TimesheetTabState extends State<TimesheetTab>
    with TickerProviderStateMixin {
  
  // Current shift tracking
  bool _isOnShift = false;
  DateTime? _shiftStartTime;
  Duration _shiftDuration = Duration.zero;
  Timer? _shiftTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Data
  List<TimesheetEntry> _timesheetEntries = [];
  bool _isLoading = false;
  
  // UI state
  TimePeriod _selectedPeriod = TimePeriod.week;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTimesheetData();
    _checkActiveShift();
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _checkActiveShift() {
    // Check if there's an active shift from previous session
    // This would typically come from persistent storage or API
    setState(() {
      _isOnShift = false; // Mock: no active shift
    });
  }

  void _loadTimesheetData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading timesheet data
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _timesheetEntries = TimesheetEntry.getMockEntries();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'Urenstaat laden...',
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

    return RefreshIndicator(
      onRefresh: () async => _loadTimesheetData(),
      child: ListView(
        padding: EdgeInsets.only(
          top: DesignTokens.spacingM,
          bottom: DesignTokens.spacingL,
        ),
        children: [
          _buildCurrentShiftTimer(),
          SizedBox(height: DesignTokens.spacingM),
          _buildPeriodSelector(),
          SizedBox(height: DesignTokens.spacingM),
          _buildHoursSummaryCards(),
          SizedBox(height: DesignTokens.spacingM),
          _buildEarningsVisualization(),
          SizedBox(height: DesignTokens.spacingM),
          _buildHoursBreakdown(),
          SizedBox(height: DesignTokens.spacingM),
          _buildExportSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentShiftTimer() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: const Interval(0.0, 0.3, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isOnShift 
                        ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    border: Border.all(
                      color: _isOnShift
                          ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.25),
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
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOnShift ? Icons.timer : Icons.timer_off,
                          color: _isOnShift 
                              ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary
                              : DesignTokens.colorGray600,
                          size: 28,
                        ),
                        SizedBox(width: DesignTokens.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOnShift ? 'Actieve Dienst' : 'Geen Actieve Dienst',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  color: _isOnShift 
                                      ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary
                                      : DesignTokens.colorGray700,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                              ),
                              if (_isOnShift && _shiftStartTime != null)
                                Text(
                                  'Gestart om ${DateFormat('HH:mm', 'nl_NL').format(_shiftStartTime!)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DesignTokens.colorGray600,
                                    fontFamily: DesignTokens.fontFamily,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingL),
                    
                    // Large timer display
                    if (_isOnShift) ...[
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(DesignTokens.spacingL),
                              decoration: BoxDecoration(
                                color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                              ),
                              child: Text(
                                _formatDuration(_shiftDuration),
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: DesignTokens.fontWeightBold,
                                  color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: DesignTokens.spacingL),
                    ],
                    
                    // Clock in/out buttons
                    Row(
                      children: [
                        Expanded(
                          child: UnifiedButton.primary(
                            text: _isOnShift ? 'Uitklokken' : 'Inklokken',
                            onPressed: _toggleShift,
                          ),
                        ),
                        if (_isOnShift) ...[
                          SizedBox(width: DesignTokens.spacingM),
                          Expanded(
                            child: UnifiedButton.secondary(
                              text: 'Pauze',
                              onPressed: _toggleBreak,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),
          ),
        ); // FadeTransition closing
      },
    ); // AnimatedBuilder closing
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
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
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          child: Row(
            children: TimePeriod.values.map((period) =>
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _loadTimesheetData();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == period
                          ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      period.label,
                      style: TextStyle(
                        color: _selectedPeriod == period
                            ? DesignTokens.colorWhite
                            : DesignTokens.colorGray700,
                        fontWeight: DesignTokens.fontWeightMedium,
                        fontSize: DesignTokens.fontSizeBody,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ).toList(),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHoursSummaryCards() {
    final summary = _calculateHoursSummary();

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: const Interval(0.3, 0.6, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uren Overzicht (${_selectedPeriod.label})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Totaal Uren',
                        '${summary['totalHours']?.toStringAsFixed(1) ?? '0.0'}h',
                        Icons.schedule,
                        DesignTokens.statusAccepted,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: _buildSummaryCard(
                        'Overuren',
                        '${summary['overtimeHours']?.toStringAsFixed(1) ?? '0.0'}h',
                        Icons.trending_up,
                        DesignTokens.statusPending,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Gemiddeld/Dag',
                        '${summary['averageHoursPerDay']?.toStringAsFixed(1) ?? '0.0'}h',
                        Icons.bar_chart,
                        DesignTokens.statusConfirmed,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: _buildSummaryCard(
                        'Diensten',
                        '${summary['totalShifts']}',
                        Icons.work,
                        DesignTokens.statusPending,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return ClipRRect(
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.colorGray600,
              fontFamily: DesignTokens.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildEarningsVisualization() {
    final earnings = _calculateEarnings();

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: const Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
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
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Verdiensten (${_selectedPeriod.label})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingM,
                            vertical: DesignTokens.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.statusConfirmed.withValues(alpha: 0.100),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                          ),
                          child: Text(
                            '€${earnings['total']?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                              fontWeight: DesignTokens.fontWeightBold,
                              fontSize: DesignTokens.fontSizeBodyLarge,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildEarningsBreakdown(earnings),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsBreakdown(Map<String, double> earnings) {
    return Column(
      children: [
        _buildEarningsItem('Basis Uurloon', earnings['base']!, DesignTokens.statusAccepted),
        _buildEarningsItem('Overuren', earnings['overtime']!, DesignTokens.statusPending),
        _buildEarningsItem('Toeslagen', earnings['allowances']!, DesignTokens.statusPending),
        _buildEarningsItem('Bonussen', earnings['bonuses']!, DesignTokens.statusConfirmed),
        Divider(height: DesignTokens.spacingM),
        _buildEarningsItem('Totaal', earnings['total']!, DesignTokens.statusConfirmed, isTotal: true),
      ],
    );
  }

  Widget _buildEarningsItem(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          Text(
            '€${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? DesignTokens.fontWeightBold : DesignTokens.fontWeightMedium,
              color: isTotal ? color : DesignTokens.colorGray700,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursBreakdown() {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.fastOutSlowIn),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
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
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uren per Type & Bedrijf',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    ..._getFilteredEntries().take(5).map((entry) =>
                      _buildTimesheetEntryItem(entry)),
                    if (_getFilteredEntries().length > 5) ...[
                      SizedBox(height: DesignTokens.spacingS),
                      Center(
                        child: TextButton(
                          onPressed: _showAllEntries,
                          child: Text(
                            'Bekijk alle ${_getFilteredEntries().length} items',
                            style: TextStyle(
                              color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      child: Container(
        decoration: BoxDecoration(
          color: SecuryFlexTheme.getColorScheme(UserRole.guard).surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          boxShadow: [DesignTokens.shadowMedium],
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export & Rapportage',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                'Download je urenstaat voor salarisadministratie',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              Row(
                children: [
                  Expanded(
                    child: UnifiedButton.secondary(
                      text: 'PDF Export',
                      onPressed: () { if (!_isExporting) _exportTimesheet('pdf'); },
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: UnifiedButton.secondary(
                      text: 'Excel Export',
                      onPressed: () { if (!_isExporting) _exportTimesheet('excel'); },
                    ),
                  ),
                ],
              ),
              if (_isExporting) ...[
                SizedBox(height: DesignTokens.spacingM),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'Export wordt voorbereid...',
                      style: TextStyle(
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Map<String, double> _calculateHoursSummary() {
    final entries = _getFilteredEntries();
    double totalHours = 0;
    double overtimeHours = 0;
    int totalShifts = entries.length;

    for (final entry in entries) {
      totalHours += entry.hoursWorked;
      if (entry.hoursWorked > 8) {
        overtimeHours += entry.hoursWorked - 8;
      }
    }

    final averageHoursPerDay = totalShifts > 0 ? totalHours / totalShifts : 0.0;

    return {
      'totalHours': totalHours,
      'overtimeHours': overtimeHours,
      'averageHoursPerDay': averageHoursPerDay.toDouble(),
      'totalShifts': totalShifts.toDouble(),
    };
  }

  Map<String, double> _calculateEarnings() {
    final entries = _getFilteredEntries();
    double base = 0;
    double overtime = 0;
    double allowances = 0;
    double bonuses = 0;

    for (final entry in entries) {
      base += entry.baseEarnings;
      overtime += entry.overtimeEarnings;
      allowances += entry.allowances;
      bonuses += entry.bonuses;
    }

    return {
      'base': base,
      'overtime': overtime,
      'allowances': allowances,
      'bonuses': bonuses,
      'total': base + overtime + allowances + bonuses,
    };
  }

  List<TimesheetEntry> _getFilteredEntries() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case TimePeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case TimePeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return _timesheetEntries.where((entry) =>
        entry.date.isAfter(startDate.subtract(Duration(days: 1)))).toList();
  }

  Widget _buildTimesheetEntryItem(TimesheetEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.colorGray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.jobType.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              entry.jobType.icon,
              color: entry.jobType.color,
              size: 20,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.companyName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                Text(
                  '${entry.jobType.label} • ${SafeDateUtils.formatDayMonth(entry.date)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.colorGray600,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.hoursWorked.toStringAsFixed(1)}h',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              Text(
                '€${entry.totalEarnings.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.600),
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action methods
  void _toggleShift() async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isOnShift = !_isOnShift;

      if (_isOnShift) {
        _shiftStartTime = DateTime.now();
        _shiftDuration = Duration.zero;
        _pulseController.repeat(reverse: true);
        _startShiftTimer();
      } else {
        _shiftStartTime = null;
        _shiftDuration = Duration.zero;
        _pulseController.stop();
        _shiftTimer?.cancel();
      }
    });

    // Notify parent about status change
    if (widget.onShiftStatusChanged != null) {
      widget.onShiftStatusChanged!(_isOnShift);
    }

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnShift ? 'Ingeklokt' : 'Uitgeklokt'),
        backgroundColor: _isOnShift ? DesignTokens.statusConfirmed : DesignTokens.statusPending,
      ),
    );
  }

  void _toggleBreak() {
    // TODO: Implement break functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pauze functionaliteit komt binnenkort')),
    );
  }

  void _startShiftTimer() {
    _shiftTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isOnShift && _shiftStartTime != null) {
        setState(() {
          _shiftDuration = DateTime.now().difference(_shiftStartTime!);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showAllEntries() {
    // TODO: Navigate to detailed timesheet view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gedetailleerde urenstaat komt binnenkort')),
    );
  }

  void _exportTimesheet(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Simulate export process
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Urenstaat geëxporteerd als $format'),
            backgroundColor: DesignTokens.statusConfirmed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export mislukt: $e'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}

/// Time Period Enum for filtering
enum TimePeriod {
  week,
  month,
  year;

  String get label {
    switch (this) {
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Maand';
      case TimePeriod.year:
        return 'Jaar';
    }
  }
}

/// Job Type for timesheet entries
enum JobType {
  objectSecurity,
  eventSecurity,
  personalSecurity,
  surveillance;

  String get label {
    switch (this) {
      case JobType.objectSecurity:
        return 'Objectbeveiliging';
      case JobType.eventSecurity:
        return 'Evenementbeveiliging';
      case JobType.personalSecurity:
        return 'Persoonbeveiliging';
      case JobType.surveillance:
        return 'Surveillance';
    }
  }

  IconData get icon {
    switch (this) {
      case JobType.objectSecurity:
        return Icons.business;
      case JobType.eventSecurity:
        return Icons.event;
      case JobType.personalSecurity:
        return Icons.person_pin;
      case JobType.surveillance:
        return Icons.visibility;
    }
  }

  Color get color {
    switch (this) {
      case JobType.objectSecurity:
        return DesignTokens.statusAccepted.withValues(alpha: 0.600);
      case JobType.eventSecurity:
        return DesignTokens.statusPending.withValues(alpha: 0.600);
      case JobType.personalSecurity:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.600);
      case JobType.surveillance:
        return DesignTokens.statusPending.withValues(alpha: 0.600);
    }
  }
}

/// Timesheet Entry Data Model
class TimesheetEntry {
  final String id;
  final DateTime date;
  final String companyName;
  final JobType jobType;
  final double hoursWorked;
  final double hourlyRate;
  final double baseEarnings;
  final double overtimeEarnings;
  final double allowances;
  final double bonuses;

  const TimesheetEntry({
    required this.id,
    required this.date,
    required this.companyName,
    required this.jobType,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.baseEarnings,
    required this.overtimeEarnings,
    required this.allowances,
    required this.bonuses,
  });

  double get totalEarnings => baseEarnings + overtimeEarnings + allowances + bonuses;

  static List<TimesheetEntry> getMockEntries() {
    return [
      TimesheetEntry(
        id: 'TE001',
        date: DateTime.now().subtract(Duration(days: 1)),
        companyName: 'Amsterdam Security Partners',
        jobType: JobType.objectSecurity,
        hoursWorked: 8.0,
        hourlyRate: 24.50,
        baseEarnings: 196.00,
        overtimeEarnings: 0.00,
        allowances: 15.00,
        bonuses: 0.00,
      ),
      TimesheetEntry(
        id: 'TE002',
        date: DateTime.now().subtract(Duration(days: 2)),
        companyName: 'Rotterdam Event Security',
        jobType: JobType.eventSecurity,
        hoursWorked: 10.0,
        hourlyRate: 28.00,
        baseEarnings: 224.00,
        overtimeEarnings: 56.00,
        allowances: 20.00,
        bonuses: 25.00,
      ),
      TimesheetEntry(
        id: 'TE003',
        date: DateTime.now().subtract(Duration(days: 3)),
        companyName: 'Den Haag Executive Protection',
        jobType: JobType.personalSecurity,
        hoursWorked: 12.0,
        hourlyRate: 35.00,
        baseEarnings: 280.00,
        overtimeEarnings: 140.00,
        allowances: 30.00,
        bonuses: 50.00,
      ),
      TimesheetEntry(
        id: 'TE004',
        date: DateTime.now().subtract(Duration(days: 4)),
        companyName: 'Utrecht Retail Security',
        jobType: JobType.surveillance,
        hoursWorked: 6.0,
        hourlyRate: 22.50,
        baseEarnings: 135.00,
        overtimeEarnings: 0.00,
        allowances: 10.00,
        bonuses: 0.00,
      ),
      TimesheetEntry(
        id: 'TE005',
        date: DateTime.now().subtract(Duration(days: 7)),
        companyName: 'Eindhoven Healthcare Security',
        jobType: JobType.objectSecurity,
        hoursWorked: 9.0,
        hourlyRate: 26.00,
        baseEarnings: 208.00,
        overtimeEarnings: 26.00,
        allowances: 18.00,
        bonuses: 15.00,
      ),
    ];
  }
}
