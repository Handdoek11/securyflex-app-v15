import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_theme_system.dart';
import '../../models/shift_model.dart';
import '../../models/time_entry_model.dart';

/// CalendarDayWidget - Individual day cell for the calendar
/// 
/// Features:
/// - Color-coded shift indicators
/// - GPS verification status
/// - Overtime warnings
/// - Nederlandse date formatting  
/// - Role-based theming
/// - Touch interactions
class CalendarDayWidget extends StatelessWidget {
  final UserRole userRole;
  final DateTime date;
  final List<Shift> shifts;
  final TimeEntry? timeEntry;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool showGPSStatus;
  final bool showOvertimeWarnings;
  final bool showDetailedView;
  final Function(DateTime)? onTapped;
  final Function(Shift)? onShiftTapped;

  const CalendarDayWidget({
    super.key,
    required this.userRole,
    required this.date,
    required this.shifts,
    this.timeEntry,
    this.isCurrentMonth = true,
    this.isToday = false,
    this.isSelected = false,
    this.showGPSStatus = true,
    this.showOvertimeWarnings = true,
    this.showDetailedView = false,
    this.onTapped,
    this.onShiftTapped,
  });

  @override
  Widget build(BuildContext context) {
    final hasShifts = shifts.isNotEmpty;
    final hasOvertime = _hasOvertime();
    final hasGPSIssue = _hasGPSIssue();
    
    return GestureDetector(
      onTap: () => onTapped?.call(date),
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: isSelected 
                ? _getPrimaryColor() 
                : DesignTokens.colorGray200,
            width: isSelected ? 2 : 0.5,
          ),
          borderRadius: showDetailedView 
              ? BorderRadius.circular(DesignTokens.radiusM)
              : BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(showDetailedView ? DesignTokens.spacingS : DesignTokens.spacingXS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day number
                  Row(
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: showDetailedView 
                              ? DesignTokens.fontSizeL 
                              : DesignTokens.fontSizeM,
                          fontWeight: isToday 
                              ? DesignTokens.fontWeightBold 
                              : DesignTokens.fontWeightMedium,
                          color: _getTextColor(),
                        ),
                      ),
                      if (isToday && !showDetailedView) ...[
                        const SizedBox(width: DesignTokens.spacingXS),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getPrimaryColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Detailed view content
                  if (showDetailedView) ...[
                    const SizedBox(height: DesignTokens.spacingS),
                    if (hasShifts) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: shifts.take(2).map((shift) => _buildShiftIndicator(shift, detailed: true)).toList(),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Center(
                          child: Text(
                            'Vrij',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.fontSizeS,
                              fontWeight: DesignTokens.fontWeightRegular,
                              color: _getTextSecondaryColor(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Compact view - shift dots
                    if (hasShifts) ...[
                      const SizedBox(height: DesignTokens.spacingXS),
                      Expanded(
                        child: Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: shifts.take(3).map((shift) => _buildShiftIndicator(shift)).toList(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Status indicators
            Positioned(
              top: 2,
              right: 2,
              child: Column(
                children: [
                  // GPS issue indicator
                  if (hasGPSIssue && showGPSStatus)
                    Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorError,
                        shape: BoxShape.circle,
                      ),
                    ),
                  
                  // Overtime warning
                  if (hasOvertime && showOvertimeWarnings)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DesignTokens.colorWarning,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            
            // Today indicator (detailed view)
            if (isToday && showDetailedView)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPrimaryColor(),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    'Vandaag',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.colorWhite,
                    ),
                  ),
                ),
              ),
            
            // More shifts indicator
            if (shifts.length > (showDetailedView ? 2 : 3))
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getPrimaryColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 8,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.colorWhite,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftIndicator(Shift shift, {bool detailed = false}) {
    if (detailed) {
      return GestureDetector(
        onTap: () => onShiftTapped?.call(shift),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: DesignTokens.spacingXS),
          padding: EdgeInsets.all(DesignTokens.spacingXS),
          decoration: BoxDecoration(
            color: _getShiftStatusColor(shift.status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
            border: Border.all(
              color: _getShiftStatusColor(shift.status),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.shiftTitle.length > 15 
                    ? '${shift.shiftTitle.substring(0, 12)}...'
                    : shift.shiftTitle,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: _getShiftStatusColor(shift.status),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${DateFormat('HH:mm').format(shift.startTime)}-${DateFormat('HH:mm').format(shift.endTime)}',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: _getShiftStatusColor(shift.status),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Simple dot indicator
      return GestureDetector(
        onTap: () => onShiftTapped?.call(shift),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _getShiftStatusColor(shift.status),
            shape: BoxShape.circle,
          ),
        ),
      );
    }
  }

  bool _hasOvertime() {
    return timeEntry != null && timeEntry!.getTotalWorkDuration().inHours > 8;
  }

  bool _hasGPSIssue() {
    // Check if any shifts have GPS verification issues
    return shifts.any((shift) => shift.requiresLocationVerification && shift.gpsVerificationStatus != 'verified');
  }

  Color _getBackgroundColor() {
    if (isToday) {
      return _getPrimaryColor().withValues(alpha: 0.1);
    } else if (isSelected) {
      return _getPrimaryColor().withValues(alpha: 0.05);
    } else if (!isCurrentMonth) {
      return DesignTokens.colorGray100;
    } else {
      return DesignTokens.colorWhite;
    }
  }

  Color _getTextColor() {
    if (!isCurrentMonth) {
      return DesignTokens.colorGray400;
    } else if (isToday) {
      return _getPrimaryColor();
    } else {
      return _getTextPrimaryColor();
    }
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

  Color _getTextSecondaryColor() {
    switch (userRole) {
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
}

