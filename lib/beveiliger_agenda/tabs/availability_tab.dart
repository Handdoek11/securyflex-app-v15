import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import '../models/shift_data.dart';
import '../utils/date_utils.dart';

/// Availability Tab Component
/// Allows guards to set when they're available for work
/// Features weekly grid interface, time slot selection, and recurring patterns
/// Critical for job matching and scheduling efficiency
/// Follows SecuryFlex unified design system and Dutch localization
class AvailabilityTab extends StatefulWidget {
  const AvailabilityTab({
    super.key,
    required this.animationController,
    this.onAvailabilityChanged, // Callback for availability updates
  });

  final AnimationController animationController;
  final Function(Map<String, List<TimeSlot>>)? onAvailabilityChanged;

  @override
  State<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<AvailabilityTab> {
  // Weekly availability data: day -> list of time slots
  Map<String, List<TimeSlot>> weeklyAvailability = {};

  // Special date exceptions
  Map<DateTime, List<TimeSlot>> specialDates = {};

  // Existing shifts for conflict detection
  List<ShiftData> existingShifts = [];

  bool _isLoading = false;

  // UI state
  String? selectedTemplate;
  bool showConflictWarnings = true;

  @override
  void initState() {
    super.initState();
    _initializeAvailability();
    _loadExistingShifts();
  }

  void _initializeAvailability() {
    // Initialize with default availability pattern
    final weekdays = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrijdag',
      'Zaterdag',
      'Zondag',
    ];

    for (String day in weekdays) {
      weeklyAvailability[day] = [
        // Default: available during standard work hours
        TimeSlot(
          startTime: TimeOfDay(hour: 8, minute: 0),
          endTime: TimeOfDay(hour: 17, minute: 0),
          isAvailable: true,
          slotType: TimeSlotType.morning,
        ),
      ];
    }
  }

  void _loadExistingShifts() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading existing shifts
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          existingShifts = ShiftData.getSampleShifts();
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
              'Beschikbaarheid laden...',
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
      onRefresh: () async => _loadExistingShifts(),
      child: ListView(
        padding: EdgeInsets.only(
          top: DesignTokens.spacingM,
          bottom: DesignTokens.spacingL,
        ),
        children: [
          _buildQuickTemplates(),
          SizedBox(height: DesignTokens.spacingM),
          _buildWeeklyAvailabilityGrid(),
          SizedBox(height: DesignTokens.spacingM),
          _buildSpecialDatesSection(),
          SizedBox(height: DesignTokens.spacingM),
          _buildConflictWarnings(),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates() {
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
          child: Transform(
            transform: Matrix4.translationValues(0.0, 30 * (1.0 - 1.0), 0.0),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
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
                        'Snelle Templates',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingS),
                      Text(
                        'Kies een template om snel je beschikbaarheid in te stellen',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.colorGray600,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingM),
                      Wrap(
                        spacing: DesignTokens.spacingS,
                        runSpacing: DesignTokens.spacingS,
                        children: [
                          _buildTemplateChip('Doordeweeks', 'weekdays'),
                          _buildTemplateChip('Weekenden', 'weekends'),
                          _buildTemplateChip('Flexibel', 'flexible'),
                          _buildTemplateChip('24/7', 'fulltime'),
                        ],
                      ),
                      if (selectedTemplate != null) ...[
                        SizedBox(height: DesignTokens.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: UnifiedButton.secondary(
                                text: 'Template toepassen',
                                onPressed: _applyTemplate,
                              ),
                            ),
                            SizedBox(width: DesignTokens.spacingS),
                            Expanded(
                              child: UnifiedButton.primary(
                                text: 'Opslaan',
                                onPressed: _saveAvailability,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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

  Widget _buildTemplateChip(String label, String templateId) {
    final isSelected = selectedTemplate == templateId;
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTemplate = isSelected ? null : templateId;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : DesignTokens.colorGray100,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
          border: Border.all(
            color: isSelected ? colorScheme.primary : DesignTokens.colorGray300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DesignTokens.colorWhite : DesignTokens.colorGray700,
            fontWeight: DesignTokens.fontWeightMedium,
            fontSize: DesignTokens.fontSizeBody,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyAvailabilityGrid() {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
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
                                'Wekelijkse Beschikbaarheid',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline),
                          onPressed: _showAvailabilityHelp,
                          color: DesignTokens.colorGray600,
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      'Stel je standaard beschikbaarheid per dag in',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildTimeSlotLegend(),
                    SizedBox(height: DesignTokens.spacingM),
                    ...weeklyAvailability.entries.map(
                      (entry) =>
                          _buildDayAvailabilityRow(entry.key, entry.value),
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

  Widget _buildTimeSlotLegend() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          _buildLegendItem(
            'Ochtend',
            TimeSlotType.morning.color,
            '06:00-12:00',
          ),
          SizedBox(width: DesignTokens.spacingM),
          _buildLegendItem(
            'Middag',
            TimeSlotType.afternoon.color,
            '12:00-18:00',
          ),
          SizedBox(width: DesignTokens.spacingM),
          _buildLegendItem('Avond', TimeSlotType.evening.color, '18:00-24:00'),
          SizedBox(width: DesignTokens.spacingM),
          _buildLegendItem('Nacht', TimeSlotType.night.color, '00:00-06:00'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String timeRange) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          Text(
            timeRange,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: DesignTokens.colorGray600,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayAvailabilityRow(String day, List<TimeSlot> timeSlots) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: TimeSlotType.values
                      .map(
                        (slotType) =>
                            _buildTimeSlotButton(day, slotType, timeSlots),
                      )
                      .toList(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 20),
                onPressed: () => _editDayAvailability(day),
                color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
              ),
            ],
          ),
          if (timeSlots.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingXS),
            Wrap(
              spacing: DesignTokens.spacingXS,
              children: timeSlots
                  .where((slot) => slot.isAvailable)
                  .map(
                    (slot) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: slot.slotType.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusS,
                        ),
                      ),
                      child: Text(
                        '${slot.startTime.format(context)} - ${slot.endTime.format(context)}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeS,
                          color: slot.slotType.color,
                          fontWeight: DesignTokens.fontWeightMedium,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotButton(
    String day,
    TimeSlotType slotType,
    List<TimeSlot> timeSlots,
  ) {
    final isAvailable = timeSlots.any(
      (slot) => slot.slotType == slotType && slot.isAvailable,
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleTimeSlot(day, slotType),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
          padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: isAvailable ? slotType.color : DesignTokens.colorGray200,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            isAvailable ? Icons.check : Icons.close,
            color: isAvailable ? DesignTokens.colorWhite : DesignTokens.colorGray600,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialDatesSection() {
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
                    color: Colors.white.withValues(alpha: 0.18),
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
                                'Speciale Datums',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                          ),
                        ),
                        UnifiedButton.secondary(
                          text: 'Toevoegen',
                          onPressed: _addSpecialDate,
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      'Stel uitzonderingen in voor specifieke datums (vakantie, vrije dagen)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.colorGray600,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    if (specialDates.isEmpty)
                      Container(
                        padding: EdgeInsets.all(DesignTokens.spacingM),
                        decoration: BoxDecoration(
                          color: DesignTokens.colorGray100,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusS,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Geen speciale datums ingesteld',
                            style: TextStyle(
                              color: DesignTokens.colorGray600,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ),
                      )
                    else
                      ...specialDates.entries.map(
                        (entry) =>
                            _buildSpecialDateItem(entry.key, entry.value),
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

  Widget _buildConflictWarnings() {
    if (!showConflictWarnings) return SizedBox.shrink();

    final conflicts = _detectConflicts();
    if (conflicts.isEmpty) return SizedBox.shrink();

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
                    color: Colors.white.withValues(alpha: 0.18),
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
                        Icon(Icons.warning, color: DesignTokens.statusPending.withValues(alpha: 0.700)),
                        SizedBox(width: DesignTokens.spacingS),
                        Text(
                          'Conflicten Gedetecteerd',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                color: DesignTokens.statusPending.withValues(alpha: 0.700),
                                fontFamily: DesignTokens.fontFamily,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    ...conflicts.map(
                      (conflict) => Text(
                        conflict,
                        style: TextStyle(
                          color: DesignTokens.statusPending.withValues(alpha: 0.700),
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
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

  Widget _buildSpecialDateItem(DateTime date, List<TimeSlot> timeSlots) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.statusAccepted.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: DesignTokens.statusAccepted.withValues(alpha: 0.200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SafeDateUtils.formatDayMonth(date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                if (timeSlots.isEmpty)
                  Text(
                    'Niet beschikbaar',
                    style: TextStyle(
                      color: DesignTokens.statusCancelled.withValues(alpha: 0.600),
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  )
                else
                  Text(
                    timeSlots
                        .map(
                          (slot) =>
                              '${slot.startTime.format(context)} - ${slot.endTime.format(context)}',
                        )
                        .join(', '),
                    style: TextStyle(
                      color: DesignTokens.statusAccepted.withValues(alpha: 0.700),
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: DesignTokens.statusCancelled.withValues(alpha: 0.600)),
            onPressed: () => _removeSpecialDate(date),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _applyTemplate() {
    if (selectedTemplate == null) return;

    setState(() {
      switch (selectedTemplate) {
        case 'weekdays':
          _applyWeekdaysTemplate();
          break;
        case 'weekends':
          _applyWeekendsTemplate();
          break;
        case 'flexible':
          _applyFlexibleTemplate();
          break;
        case 'fulltime':
          _applyFulltimeTemplate();
          break;
      }
    });
  }

  void _applyWeekdaysTemplate() {
    final weekdays = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag'];
    final weekends = ['Zaterdag', 'Zondag'];

    for (String day in weekdays) {
      weeklyAvailability[day] = [
        TimeSlot(
          startTime: TimeOfDay(hour: 8, minute: 0),
          endTime: TimeOfDay(hour: 17, minute: 0),
          isAvailable: true,
          slotType: TimeSlotType.morning,
        ),
      ];
    }

    for (String day in weekends) {
      weeklyAvailability[day] = [];
    }
  }

  void _applyWeekendsTemplate() {
    final weekdays = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag'];
    final weekends = ['Zaterdag', 'Zondag'];

    for (String day in weekdays) {
      weeklyAvailability[day] = [];
    }

    for (String day in weekends) {
      weeklyAvailability[day] = [
        TimeSlot(
          startTime: TimeOfDay(hour: 10, minute: 0),
          endTime: TimeOfDay(hour: 18, minute: 0),
          isAvailable: true,
          slotType: TimeSlotType.afternoon,
        ),
      ];
    }
  }

  void _applyFlexibleTemplate() {
    final allDays = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrijdag',
      'Zaterdag',
      'Zondag',
    ];

    for (String day in allDays) {
      weeklyAvailability[day] = [
        TimeSlot(
          startTime: TimeOfDay(hour: 6, minute: 0),
          endTime: TimeOfDay(hour: 22, minute: 0),
          isAvailable: true,
          slotType: TimeSlotType.morning,
        ),
      ];
    }
  }

  void _applyFulltimeTemplate() {
    final allDays = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrijdag',
      'Zaterdag',
      'Zondag',
    ];

    for (String day in allDays) {
      weeklyAvailability[day] = [
        TimeSlot(
          startTime: TimeOfDay(hour: 0, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 59),
          isAvailable: true,
          slotType: TimeSlotType.morning,
        ),
      ];
    }
  }

  void _toggleTimeSlot(String day, TimeSlotType slotType) {
    setState(() {
      final daySlots = weeklyAvailability[day] ?? [];
      final existingSlot = daySlots.firstWhere(
        (slot) => slot.slotType == slotType,
        orElse: () => TimeSlot(
          startTime: slotType.defaultStartTime,
          endTime: slotType.defaultEndTime,
          isAvailable: false,
          slotType: slotType,
        ),
      );

      if (existingSlot.isAvailable) {
        daySlots.remove(existingSlot);
      } else {
        daySlots.add(
          TimeSlot(
            startTime: slotType.defaultStartTime,
            endTime: slotType.defaultEndTime,
            isAvailable: true,
            slotType: slotType,
          ),
        );
      }

      weeklyAvailability[day] = daySlots;
    });
  }

  void _editDayAvailability(String day) {
    // TODO: Show detailed time picker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gedetailleerde tijdbewerking voor $day')),
    );
  }

  void _addSpecialDate() {
    // TODO: Show date picker and time slot selection
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Speciale datum toevoegen')));
  }

  void _removeSpecialDate(DateTime date) {
    setState(() {
      specialDates.remove(date);
    });
  }

  void _showAvailabilityHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Beschikbaarheid Instellen'),
        content: Text(
          'Stel je wekelijkse beschikbaarheid in door op de tijdsloten te tikken:\n\n'
          '• Groen = Beschikbaar\n'
          '• Grijs = Niet beschikbaar\n\n'
          'Gebruik templates voor snelle instellingen of bewerk individuele dagen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Begrepen'),
          ),
        ],
      ),
    );
  }

  List<String> _detectConflicts() {
    final conflicts = <String>[];

    // Check for conflicts with existing shifts
    for (final shift in existingShifts) {
      final dayName = _getDayName(shift.startTime.weekday);
      final daySlots = weeklyAvailability[dayName] ?? [];

      final hasConflict = !daySlots.any(
        (slot) =>
            slot.isAvailable &&
            _timeOverlaps(
              slot.startTime,
              slot.endTime,
              TimeOfDay.fromDateTime(shift.startTime),
              TimeOfDay.fromDateTime(shift.endTime),
            ),
      );

      if (hasConflict) {
        conflicts.add(
          'Conflict met dienst: ${shift.title} op ${SafeDateUtils.formatDayMonth(shift.startTime)}',
        );
      }
    }

    return conflicts;
  }

  String _getDayName(int weekday) {
    const dayNames = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrijdag',
      'Zaterdag',
      'Zondag',
    ];
    return dayNames[weekday - 1];
  }

  bool _timeOverlaps(
    TimeOfDay start1,
    TimeOfDay end1,
    TimeOfDay start2,
    TimeOfDay end2,
  ) {
    final start1Minutes = start1.hour * 60 + start1.minute;
    final end1Minutes = end1.hour * 60 + end1.minute;
    final start2Minutes = start2.hour * 60 + start2.minute;
    final end2Minutes = end2.hour * 60 + end2.minute;

    return start1Minutes < end2Minutes && end1Minutes > start2Minutes;
  }

  void _saveAvailability() {
    if (widget.onAvailabilityChanged != null) {
      widget.onAvailabilityChanged!(weeklyAvailability);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Beschikbaarheid opgeslagen'),
        backgroundColor: DesignTokens.statusConfirmed,
      ),
    );
  }
}

/// Time Slot Data Model
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final TimeSlotType slotType;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.slotType,
  });

  TimeSlot copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAvailable,
    TimeSlotType? slotType,
  }) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      slotType: slotType ?? this.slotType,
    );
  }
}

/// Time Slot Type Enum
enum TimeSlotType {
  morning,
  afternoon,
  evening,
  night;

  Color get color {
    switch (this) {
      case TimeSlotType.morning:
        return DesignTokens.statusPending.withValues(alpha: 0.400);
      case TimeSlotType.afternoon:
        return DesignTokens.statusAccepted.withValues(alpha: 0.400);
      case TimeSlotType.evening:
        return DesignTokens.statusPending.withValues(alpha: 0.400);
      case TimeSlotType.night:
        return DesignTokens.guardPrimary.withValues(alpha: 0.400);
    }
  }

  String get label {
    switch (this) {
      case TimeSlotType.morning:
        return 'Ochtend';
      case TimeSlotType.afternoon:
        return 'Middag';
      case TimeSlotType.evening:
        return 'Avond';
      case TimeSlotType.night:
        return 'Nacht';
    }
  }

  TimeOfDay get defaultStartTime {
    switch (this) {
      case TimeSlotType.morning:
        return TimeOfDay(hour: 6, minute: 0);
      case TimeSlotType.afternoon:
        return TimeOfDay(hour: 12, minute: 0);
      case TimeSlotType.evening:
        return TimeOfDay(hour: 18, minute: 0);
      case TimeSlotType.night:
        return TimeOfDay(hour: 0, minute: 0);
    }
  }

  TimeOfDay get defaultEndTime {
    switch (this) {
      case TimeSlotType.morning:
        return TimeOfDay(hour: 12, minute: 0);
      case TimeSlotType.afternoon:
        return TimeOfDay(hour: 18, minute: 0);
      case TimeSlotType.evening:
        return TimeOfDay(hour: 24, minute: 0);
      case TimeSlotType.night:
        return TimeOfDay(hour: 6, minute: 0);
    }
  }
}
