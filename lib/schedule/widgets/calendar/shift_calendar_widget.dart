import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_buttons.dart';
import '../../../unified_card_system.dart';
import '../../../unified_header.dart';
import '../../../unified_theme_system.dart';
import '../../blocs/schedule_bloc.dart';
import '../../models/shift_model.dart';
import '../../models/time_entry_model.dart';
import 'calendar_day_widget.dart';
import 'calendar_header_widget.dart';
import 'shift_detail_popup.dart';

/// Calendar view types for schedule display
enum CalendarViewType {
  month,
  week, 
  day,
}

/// Nederlandse dagen van de week
const List<String> dutchWeekdays = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];

/// ShiftCalendarWidget - Comprehensive calendar for Dutch security schedule management
/// 
/// Features:
/// - Monthly, weekly, and daily views with smooth transitions
/// - Color-coded shifts based on type and status
/// - GPS verification status indicators
/// - CAO compliance warnings for overtime
/// - Touch interactions for shift details
/// - Swipe gestures for navigation
/// - Nederlandse localization
/// - Role-based theming (guard/company/admin)
class ShiftCalendarWidget extends StatefulWidget {
  final UserRole userRole;
  final DateTime initialDate;
  final CalendarViewType initialView;
  final List<Shift> shifts;
  final List<TimeEntry> timeEntries;
  final Function(Shift)? onShiftTapped;
  final Function(DateTime)? onDateSelected;
  final Function(DateTime, CalendarViewType)? onViewChanged;
  final bool showGPSStatus;
  final bool showOvertimeWarnings;
  final bool showLeaveRequests;
  final double? height;

  const ShiftCalendarWidget({
    super.key,
    required this.userRole,
    required this.initialDate,
    this.initialView = CalendarViewType.month,
    required this.shifts,
    required this.timeEntries,
    this.onShiftTapped,
    this.onDateSelected,
    this.onViewChanged,
    this.showGPSStatus = true,
    this.showOvertimeWarnings = true,
    this.showLeaveRequests = true,
    this.height,
  });

  @override
  State<ShiftCalendarWidget> createState() => _ShiftCalendarWidgetState();
}

class _ShiftCalendarWidgetState extends State<ShiftCalendarWidget> with TickerProviderStateMixin {
  late CalendarViewType _currentView;
  late DateTime _focusedDate;
  DateTime? _selectedDate;
  late PageController _pageController;
  late AnimationController _viewTransitionController;
  late Animation<double> _viewTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _focusedDate = widget.initialDate;
    _selectedDate = widget.initialDate;
    _pageController = PageController(initialPage: 1000); // Large initial page for infinite scroll
    
    _viewTransitionController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    _viewTransitionAnimation = CurvedAnimation(
      parent: _viewTransitionController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: SizedBox(
        height: widget.height ?? _getCalendarHeight(),
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: DesignTokens.spacingM),
            _buildViewToggle(),
            const SizedBox(height: DesignTokens.spacingM),
            Expanded(
              child: AnimatedBuilder(
                animation: _viewTransitionAnimation,
                builder: (context, child) {
                  return _buildCalendarBody();
                },
              ),
            ),
            if (_hasSelectedDateShifts()) ...[
              const SizedBox(height: DesignTokens.spacingM),
              _buildSelectedDateSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return CalendarHeaderWidget(
      userRole: widget.userRole,
      focusedDate: _focusedDate,
      currentView: _currentView,
      onPreviousTapped: _navigateToPrevious,
      onNextTapped: _navigateToNext,
      onTodayTapped: _navigateToToday,
      onDateTapped: _showDatePicker,
    );
  }

  Widget _buildViewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildViewButton('Maand', CalendarViewType.month),
        const SizedBox(width: DesignTokens.spacingS),
        _buildViewButton('Week', CalendarViewType.week),
        const SizedBox(width: DesignTokens.spacingS),
        _buildViewButton('Dag', CalendarViewType.day),
      ],
    );
  }

  Widget _buildViewButton(String text, CalendarViewType viewType) {
    final isSelected = _currentView == viewType;
    
    return UnifiedButton.category(
      text: text,
      isSelected: isSelected,
      onPressed: () => _changeView(viewType),
    );
  }

  Widget _buildCalendarBody() {
    switch (_currentView) {
      case CalendarViewType.month:
        return _buildMonthView();
      case CalendarViewType.week:
        return _buildWeekView();
      case CalendarViewType.day:
        return _buildDayView();
    }
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        _buildWeekdayHeaders(),
        const SizedBox(height: DesignTokens.spacingS),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onMonthPageChanged,
            itemBuilder: (context, index) {
              final monthDate = _getMonthForPage(index);
              return _buildMonthGrid(monthDate);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return Column(
      children: [
        _buildWeekdayHeaders(),
        const SizedBox(height: DesignTokens.spacingS),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onWeekPageChanged,
            itemBuilder: (context, index) {
              final weekStart = _getWeekStartForPage(index);
              return _buildWeekGrid(weekStart);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onDayPageChanged,
      itemBuilder: (context, index) {
        final dayDate = _getDayForPage(index);
        return _buildDayContent(dayDate);
      },
    );
  }

  Widget _buildWeekdayHeaders() {
    return Row(
      children: dutchWeekdays.map((weekday) {
        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: _getTextSecondaryColor(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate grid start (first Monday of the view)
    final gridStart = firstDayOfMonth.subtract(Duration(days: firstDayWeekday - 1));
    
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final date = gridStart.add(Duration(days: index));
        final isCurrentMonth = date.month == monthDate.month;
        final isToday = _isToday(date);
        final isSelected = _isSelected(date);
        
        return CalendarDayWidget(
          userRole: widget.userRole,
          date: date,
          shifts: _getShiftsForDate(date),
          timeEntry: _getTimeEntryForDate(date),
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          isSelected: isSelected,
          showGPSStatus: widget.showGPSStatus,
          showOvertimeWarnings: widget.showOvertimeWarnings,
          onTapped: _onDateTapped,
          onShiftTapped: widget.onShiftTapped,
        );
      },
    );
  }

  Widget _buildWeekGrid(DateTime weekStart) {
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final isToday = _isToday(date);
        final isSelected = _isSelected(date);
        
        return Expanded(
          child: CalendarDayWidget(
            userRole: widget.userRole,
            date: date,
            shifts: _getShiftsForDate(date),
            timeEntry: _getTimeEntryForDate(date),
            isCurrentMonth: true,
            isToday: isToday,
            isSelected: isSelected,
            showGPSStatus: widget.showGPSStatus,
            showOvertimeWarnings: widget.showOvertimeWarnings,
            showDetailedView: true,
            onTapped: _onDateTapped,
            onShiftTapped: widget.onShiftTapped,
          ),
        );
      }),
    );
  }

  Widget _buildDayContent(DateTime date) {
    final shifts = _getShiftsForDate(date);
    final timeEntry = _getTimeEntryForDate(date);
    final isToday = _isToday(date);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: isToday ? _getPrimaryColor().withValues(alpha: 0.1) : _getBackgroundColor(),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: isToday ? Border.all(color: _getPrimaryColor()) : null,
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE', 'nl_NL').format(date),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: _getTextSecondaryColor(),
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy', 'nl_NL').format(date),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeXL,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: _getTextPrimaryColor(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.spacingL),
          
          // Shifts for the day
          if (shifts.isNotEmpty) ...[
            Text(
              'Diensten',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeHeading,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getTextPrimaryColor(),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            ...shifts.map((shift) => _buildDayShiftCard(shift)),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: DesignTokens.iconSizeXXL,
                    color: _getTextSecondaryColor(),
                  ),
                  const SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Geen diensten gepland',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: _getTextSecondaryColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Time entry summary
          if (timeEntry != null) ...[
            const SizedBox(height: DesignTokens.spacingL),
            Text(
              'Tijd Registratie',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeHeading,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getTextPrimaryColor(),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _buildTimeEntrySummary(timeEntry),
          ],
        ],
      ),
    );
  }

  Widget _buildDayShiftCard(Shift shift) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: UnifiedCard.standard(
        userRole: widget.userRole,
        isClickable: true,
        onTap: () => widget.onShiftTapped?.call(shift),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getShiftStatusColor(shift.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.shiftTitle,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeL,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: _getTextPrimaryColor(),
                        ),
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(shift.startTime)} - ${DateFormat('HH:mm').format(shift.endTime)}',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeM,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: _getTextSecondaryColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildShiftStatusBadge(shift.status),
              ],
            ),
            if (shift.location != null) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: DesignTokens.iconSizeS,
                    color: _getTextSecondaryColor(),
                  ),
                  const SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    shift.location.address,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: _getTextSecondaryColor(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntrySummary(TimeEntry timeEntry) {
    final totalDuration = timeEntry.getTotalWorkDuration();
    final isOvertime = totalDuration.inHours > 8;
    
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                timeEntry.checkInTime != null && timeEntry.checkOutTime == null
                    ? Icons.play_circle_fill
                    : Icons.check_circle,
                color: timeEntry.checkInTime != null && timeEntry.checkOutTime == null
                    ? DesignTokens.colorSuccess
                    : _getPrimaryColor(),
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  timeEntry.checkInTime != null && timeEntry.checkOutTime == null
                      ? 'Actieve dienst'
                      : 'Dienst voltooid',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: _getTextPrimaryColor(),
                  ),
                ),
              ),
              if (isOvertime)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.colorWarning,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    'Overwerk',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeS,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.colorWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              _buildTimeDetail('Inchecken', timeEntry.checkInTime),
              const SizedBox(width: DesignTokens.spacingL),
              _buildTimeDetail('Uitchecken', timeEntry.checkOutTime),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Totaal: ${_formatDuration(totalDuration)}',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightBold,
              color: isOvertime ? DesignTokens.colorWarning : _getTextPrimaryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetail(String label, DateTime? time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getTextSecondaryColor(),
          ),
        ),
        Text(
          time != null ? DateFormat('HH:mm').format(time) : '--:--',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateSummary() {
    if (_selectedDate == null) return const SizedBox.shrink();
    
    final shifts = _getShiftsForDate(_selectedDate!);
    final timeEntry = _getTimeEntryForDate(_selectedDate!);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _getPrimaryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: _getPrimaryColor().withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE d MMMM', 'nl_NL').format(_selectedDate!),
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextPrimaryColor(),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          if (shifts.isNotEmpty)
            Text(
              '${shifts.length} dienst${shifts.length == 1 ? '' : 'en'}',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextSecondaryColor(),
              ),
            ),
          if (timeEntry != null)
            Text(
              'Totaal gewerkt: ${_formatDuration(timeEntry.getTotalWorkDuration())}',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextSecondaryColor(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftStatusBadge(ShiftStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getShiftStatusColor(status),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Text(
        _getShiftStatusText(status),
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.colorWhite,
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToPrevious() {
    setState(() {
      switch (_currentView) {
        case CalendarViewType.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
          break;
        case CalendarViewType.week:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
          break;
        case CalendarViewType.day:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          break;
      }
      widget.onViewChanged?.call(_focusedDate, _currentView);
    });
  }

  void _navigateToNext() {
    setState(() {
      switch (_currentView) {
        case CalendarViewType.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
          break;
        case CalendarViewType.week:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
          break;
        case CalendarViewType.day:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          break;
      }
      widget.onViewChanged?.call(_focusedDate, _currentView);
    });
  }

  void _navigateToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedDate = today;
      _selectedDate = today;
      widget.onDateSelected?.call(today);
      widget.onViewChanged?.call(_focusedDate, _currentView);
    });
  }

  void _changeView(CalendarViewType newView) {
    if (_currentView != newView) {
      _viewTransitionController.forward().then((_) {
        setState(() {
          _currentView = newView;
          widget.onViewChanged?.call(_focusedDate, _currentView);
        });
        _viewTransitionController.reverse();
      });
    }
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  void _showDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('nl', 'NL'),
    );
    
    if (selectedDate != null) {
      setState(() {
        _focusedDate = selectedDate;
        _selectedDate = selectedDate;
      });
      widget.onDateSelected?.call(selectedDate);
      widget.onViewChanged?.call(_focusedDate, _currentView);
    }
  }

  // Page changed handlers
  void _onMonthPageChanged(int index) {
    setState(() {
      _focusedDate = _getMonthForPage(index);
    });
    widget.onViewChanged?.call(_focusedDate, _currentView);
  }

  void _onWeekPageChanged(int index) {
    setState(() {
      _focusedDate = _getWeekStartForPage(index);
    });
    widget.onViewChanged?.call(_focusedDate, _currentView);
  }

  void _onDayPageChanged(int index) {
    setState(() {
      _focusedDate = _getDayForPage(index);
    });
    widget.onViewChanged?.call(_focusedDate, _currentView);
  }

  // Helper methods
  DateTime _getMonthForPage(int index) {
    final baseDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    return DateTime(baseDate.year, baseDate.month + (index - 1000));
  }

  DateTime _getWeekStartForPage(int index) {
    final baseDate = _getMonday(widget.initialDate);
    return baseDate.add(Duration(days: 7 * (index - 1000)));
  }

  DateTime _getDayForPage(int index) {
    return widget.initialDate.add(Duration(days: index - 1000));
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<Shift> _getShiftsForDate(DateTime date) {
    return widget.shifts.where((shift) {
      final shiftDate = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return shiftDate == targetDate;
    }).toList();
  }

  TimeEntry? _getTimeEntryForDate(DateTime date) {
    return widget.timeEntries.cast<TimeEntry?>().firstWhere(
      (entry) {
        if (entry == null || entry.checkInTime == null) return false;
        final entryDate = DateTime(entry.checkInTime!.year, entry.checkInTime!.month, entry.checkInTime!.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        return entryDate == targetDate;
      },
      orElse: () => null,
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  bool _isSelected(DateTime date) {
    return _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;
  }

  bool _hasSelectedDateShifts() {
    return _selectedDate != null && _getShiftsForDate(_selectedDate!).isNotEmpty;
  }

  double _getCalendarHeight() {
    switch (_currentView) {
      case CalendarViewType.month:
        return 600.0;
      case CalendarViewType.week:
        return 400.0;
      case CalendarViewType.day:
        return 500.0;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}u ${minutes}m';
  }

  // Role-based styling methods
  Color _getPrimaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardBackground;
      case UserRole.company:
        return DesignTokens.companyBackground;
      case UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }

  Color _getTextPrimaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextPrimary;
      case UserRole.company:
        return DesignTokens.companyTextPrimary;
      case UserRole.admin:
        return DesignTokens.adminTextPrimary;
    }
  }

  Color _getTextSecondaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextSecondary;
      case UserRole.company:
        return DesignTokens.companyTextSecondary;
      case UserRole.admin:
        return DesignTokens.adminTextSecondary;
    }
  }

  Color _getShiftStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return DesignTokens.statusDraft;
      case ShiftStatus.published:
        return DesignTokens.statusPending;
      case ShiftStatus.confirmed:
        return DesignTokens.statusConfirmed;
      case ShiftStatus.inProgress:
        return DesignTokens.statusInProgress;
      case ShiftStatus.completed:
        return DesignTokens.statusCompleted;
      case ShiftStatus.cancelled:
        return DesignTokens.statusCancelled;
      case ShiftStatus.noShow:
        return DesignTokens.colorError;
      case ShiftStatus.expired:
        return DesignTokens.statusExpired;
      case ShiftStatus.replacement:
        return DesignTokens.colorWarning;
      default:
        return DesignTokens.colorGray500;
    }
  }

  String _getShiftStatusText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return 'Concept';
      case ShiftStatus.published:
        return 'Gepubliceerd';
      case ShiftStatus.confirmed:
        return 'Bevestigd';
      case ShiftStatus.inProgress:
        return 'Actief';
      case ShiftStatus.completed:
        return 'Voltooid';
      case ShiftStatus.cancelled:
        return 'Geannuleerd';
      case ShiftStatus.noShow:
        return 'Niet verschenen';
      case ShiftStatus.expired:
        return 'Verlopen';
      case ShiftStatus.replacement:
        return 'Vervanger';
      default:
        return 'Onbekend';
    }
  }
}