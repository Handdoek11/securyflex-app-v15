import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import '../models/shift_data.dart';
import '../widgets/next_shift_card.dart';
import '../utils/date_utils.dart';

/// Shifts Tab Component
/// Extracted from PlanningMainScreen focusing on current/upcoming shifts
/// Includes NextShiftCard functionality and today's shifts summary
/// Maintains shift status management and real-time updates
/// Follows SecuryFlex unified design system and Dutch localization
class ShiftsTab extends StatefulWidget {
  const ShiftsTab({
    super.key,
    required this.animationController,
    this.onShiftSelected, // Navigation hook for shift details
  });

  final AnimationController animationController;
  final Function(String shiftId)? onShiftSelected; // For navigating to shift details

  @override
  State<ShiftsTab> createState() => _ShiftsTabState();
}

class _ShiftsTabState extends State<ShiftsTab> {
  List<ShiftData> shifts = ShiftData.getSampleShifts();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Simulate loading delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          shifts = ShiftData.getSampleShifts();
          _isLoading = false;
        });
      }
    });
  }

  ShiftData? _getNextShift() {
    final now = DateTime.now();
    final upcomingShifts = shifts.where((shift) =>
        shift.startTime.isAfter(now) &&
        (shift.status == ShiftStatus.confirmed || shift.status == ShiftStatus.accepted)
    ).toList();

    if (upcomingShifts.isEmpty) return null;

    upcomingShifts.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcomingShifts.first;
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
              'Diensten laden...',
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
            ElevatedButton(
              onPressed: _loadShifts,
              child: Text('Opnieuw proberen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadShifts(),
      child: ListView(
        padding: EdgeInsets.only(
          top: DesignTokens.spacingM,
          bottom: DesignTokens.spacingL,
        ),
        children: [
          _buildNextShiftCard(),
          SizedBox(height: DesignTokens.spacingM),
          _buildTodaysShiftsSummary(),
          SizedBox(height: DesignTokens.spacingM),
          _buildWeekView(),
        ],
      ),
    );
  }

  Widget _buildNextShiftCard() {
    final nextShift = _getNextShift();
    
    return NextShiftCard(
      animation: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: widget.animationController,
          curve: const Interval(0.0, 0.3, curve: Curves.fastOutSlowIn),
        ),
      ),
      animationController: widget.animationController,
      nextShift: nextShift,
      onTap: () {
        if (nextShift != null && widget.onShiftSelected != null) {
          widget.onShiftSelected!(nextShift.id);
        }
      },
    );
  }

  Widget _buildTodaysShiftsSummary() {
    final today = DateTime.now();
    final todaysShifts = shifts.where((shift) =>
        shift.startTime.year == today.year &&
        shift.startTime.month == today.month &&
        shift.startTime.day == today.day).toList();

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
                            'Vandaag (${SafeDateUtils.formatDayMonth(today)})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingS),
                      if (todaysShifts.isEmpty)
                        Text(
                          'Geen diensten gepland voor vandaag',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DesignTokens.colorGray600,
                            fontFamily: DesignTokens.fontFamily,
                          ),
                        )
                      else
                        ...todaysShifts.map((shift) => _buildShiftListItem(shift)),
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

  Widget _buildWeekView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekShifts = <DateTime, List<ShiftData>>{};

    // Group shifts by day for this week
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      weekShifts[day] = shifts.where((shift) =>
          SafeDateUtils.isSameDay(shift.startTime, day)).toList();
    }

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: const Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
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
                            'Deze Week (${SafeDateUtils.formatDayMonth(startOfWeek)} - ${SafeDateUtils.formatDayMonth(startOfWeek.add(Duration(days: 6)))})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingM),
                      ...weekShifts.entries.map((entry) => _buildDayRow(entry.key, entry.value)),
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

  Widget _buildDayRow(DateTime day, List<ShiftData> dayShifts) {
    final dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    final dayName = dayNames[day.weekday - 1];
    final isToday = SafeDateUtils.isSameDay(day, DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: isToday
            ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.1)
            : DesignTokens.colorGray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: isToday
            ? Border.all(color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: isToday
                        ? SecuryFlexTheme.getColorScheme(UserRole.guard).primary
                        : DesignTokens.colorGray700,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.colorGray600,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayShifts.isEmpty
                ? Text(
                    'Geen diensten',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.colorGray600,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dayShifts.map((shift) => Padding(
                      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onShiftSelected != null) {
                            widget.onShiftSelected!(shift.id);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              shift.shiftTypeIcon,
                              size: 16,
                              color: shift.statusColor,
                            ),
                            SizedBox(width: DesignTokens.spacingXS),
                            Expanded(
                              child: Text(
                                '${shift.title} (${SafeDateUtils.formatTimeRange(shift.startTime, shift.endTime)})',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: DesignTokens.fontWeightMedium,
                                  color: DesignTokens.colorGray700,
                                  fontFamily: DesignTokens.fontFamily,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftListItem(ShiftData shift) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: shift.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: shift.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (widget.onShiftSelected != null) {
            widget.onShiftSelected!(shift.id);
          }
        },
        child: Row(
          children: [
            Icon(
              shift.shiftTypeIcon,
              color: shift.statusColor,
              size: 20,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  Text(
                    SafeDateUtils.formatTimeRange(shift.startTime, shift.endTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                color: shift.statusColor,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                shift.statusDisplayName,
                style: TextStyle(
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.colorWhite,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
