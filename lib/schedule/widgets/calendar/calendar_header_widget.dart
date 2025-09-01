import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_buttons.dart';
import '../../../unified_theme_system.dart';
import '../calendar/shift_calendar_widget.dart';

/// CalendarHeaderWidget - Navigation header for the calendar
/// 
/// Features:
/// - Navigation between time periods
/// - Current period display with Nederlandse maanden
/// - Quick "Today" button
/// - Date picker integration
/// - Role-based theming
class CalendarHeaderWidget extends StatelessWidget {
  final UserRole userRole;
  final DateTime focusedDate;
  final CalendarViewType currentView;
  final VoidCallback? onPreviousTapped;
  final VoidCallback? onNextTapped;
  final VoidCallback? onTodayTapped;
  final VoidCallback? onDateTapped;

  const CalendarHeaderWidget({
    super.key,
    required this.userRole,
    required this.focusedDate,
    required this.currentView,
    this.onPreviousTapped,
    this.onNextTapped,
    this.onTodayTapped,
    this.onDateTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Previous button
        UnifiedButton.icon(
          icon: Icons.chevron_left,
          onPressed: onPreviousTapped ?? () {},
        ),
        
        const SizedBox(width: DesignTokens.spacingM),
        
        // Current period display
        Expanded(
          child: GestureDetector(
            onTap: onDateTapped,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: DesignTokens.spacingS,
                horizontal: DesignTokens.spacingM,
              ),
              decoration: BoxDecoration(
                color: _getPrimaryColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: _getPrimaryColor().withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: _getTextPrimaryColor(),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingXS),
                  Icon(
                    Icons.calendar_today,
                    size: DesignTokens.iconSizeS,
                    color: _getPrimaryColor(),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: DesignTokens.spacingM),
        
        // Today button
        UnifiedButton.text(
          text: 'Vandaag',
          onPressed: onTodayTapped ?? () {},
        ),
        
        const SizedBox(width: DesignTokens.spacingS),
        
        // Next button
        UnifiedButton.icon(
          icon: Icons.chevron_right,
          onPressed: onNextTapped ?? () {},
        ),
      ],
    );
  }

  String _getDisplayText() {
    switch (currentView) {
      case CalendarViewType.month:
        return DateFormat('MMMM yyyy', 'nl_NL').format(focusedDate);
      case CalendarViewType.week:
        final startOfWeek = _getMonday(focusedDate);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        
        if (startOfWeek.month == endOfWeek.month) {
          return '${startOfWeek.day}-${endOfWeek.day} ${DateFormat('MMMM yyyy', 'nl_NL').format(startOfWeek)}';
        } else if (startOfWeek.year == endOfWeek.year) {
          return '${startOfWeek.day} ${DateFormat('MMM', 'nl_NL').format(startOfWeek)} - ${endOfWeek.day} ${DateFormat('MMM yyyy', 'nl_NL').format(endOfWeek)}';
        } else {
          return '${DateFormat('d MMM yyyy', 'nl_NL').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'nl_NL').format(endOfWeek)}';
        }
      case CalendarViewType.day:
        return DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(focusedDate);
    }
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Color _getPrimaryColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getTextPrimaryColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextPrimary;
      case UserRole.company:
        return DesignTokens.companyTextPrimary;
      case UserRole.admin:
        return DesignTokens.adminTextPrimary;
    }
  }
}

