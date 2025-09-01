import 'package:flutter/material.dart';

import '../../unified_design_tokens.dart';
import '../../unified_status_colors.dart';
import '../models/shift_data.dart';
import '../utils/date_utils.dart';

class PlanningCalendarView extends StatefulWidget {
  const PlanningCalendarView({
    super.key,
    this.initialSelectedDate,
    this.onDateSelected,
    this.minimumDate,
    this.maximumDate,
    this.shifts = const [],
  });

  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTime? initialSelectedDate;
  final Function(DateTime)? onDateSelected;
  final List<ShiftData> shifts;

  @override
  State<PlanningCalendarView> createState() => _PlanningCalendarViewState();
}

class _PlanningCalendarViewState extends State<PlanningCalendarView> {
  List<DateTime> dateList = <DateTime>[];
  DateTime currentMonthDate = DateTime.now();
  DateTime? selectedDate;

  @override
  void initState() {
    setListOfDate(currentMonthDate);
    if (widget.initialSelectedDate != null) {
      selectedDate = widget.initialSelectedDate;
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setListOfDate(DateTime monthDate) {
    dateList.clear();
    final DateTime newDate = DateTime(monthDate.year, monthDate.month, 0);
    int previousMothDay = 0;
    if (newDate.weekday < 7) {
      previousMothDay = newDate.weekday;
      for (int i = 1; i <= previousMothDay; i++) {
        dateList.add(newDate.subtract(Duration(days: previousMothDay - i)));
      }
    }
    for (int i = 0; i < (42 - previousMothDay); i++) {
      dateList.add(newDate.add(Duration(days: i + 1)));
    }
  }

  /// Controleert of er diensten zijn op een specifieke datum
  bool hasShiftsOnDate(DateTime date) {
    return widget.shifts.any(
      (shift) =>
          shift.startTime.year == date.year &&
          shift.startTime.month == date.month &&
          shift.startTime.day == date.day,
    );
  }

  /// Geeft het aantal diensten op een specifieke datum
  int getShiftCountOnDate(DateTime date) {
    return widget.shifts
        .where(
          (shift) =>
              shift.startTime.year == date.year &&
              shift.startTime.month == date.month &&
              shift.startTime.day == date.day,
        )
        .length;
  }

  /// Geeft de status kleur voor een datum met diensten (unified system)
  Color getDateStatusColor(DateTime date) {
    final shiftsOnDate = widget.shifts.where(
      (shift) =>
          shift.startTime.year == date.year &&
          shift.startTime.month == date.month &&
          shift.startTime.day == date.day,
    );

    if (shiftsOnDate.isEmpty) return Colors.transparent;

    // Prioriteit: confirmed > inProgress > pending > accepted
    if (shiftsOnDate.any((s) => s.status == ShiftStatus.confirmed)) {
      return StatusColorHelper.getShiftStatusColor(ShiftStatus.confirmed);
    } else if (shiftsOnDate.any((s) => s.status == ShiftStatus.inProgress)) {
      return StatusColorHelper.getShiftStatusColor(ShiftStatus.inProgress);
    } else if (shiftsOnDate.any((s) => s.status == ShiftStatus.pending)) {
      return StatusColorHelper.getShiftStatusColor(ShiftStatus.pending);
    } else if (shiftsOnDate.any((s) => s.status == ShiftStatus.accepted)) {
      return StatusColorHelper.getShiftStatusColor(ShiftStatus.accepted);
    }
    return DesignTokens.colorGray400;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                    border: Border.all(color: DesignTokens.guardTextSecondary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(24.0),
                      ),
                      onTap: () {
                        setState(() {
                          currentMonthDate = DateTime(
                            currentMonthDate.year,
                            currentMonthDate.month,
                            0,
                          );
                          setListOfDate(currentMonthDate);
                        });
                      },
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        color: DesignTokens.guardTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    SafeDateUtils.formatMonthYear(currentMonthDate),
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: 20,
                      color: DesignTokens.guardTextPrimary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                    border: Border.all(color: DesignTokens.guardTextSecondary),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(24.0),
                      ),
                      onTap: () {
                        setState(() {
                          currentMonthDate = DateTime(
                            currentMonthDate.year,
                            currentMonthDate.month + 2,
                            0,
                          );
                          setListOfDate(currentMonthDate);
                        });
                      },
                      child: Icon(
                        Icons.keyboard_arrow_right,
                        color: DesignTokens.guardTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8, bottom: 8),
          child: Row(children: getDaysNameUI()),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8),
          child: Column(children: getDaysNoUI()),
        ),
      ],
    );
  }

  List<Widget> getDaysNameUI() {
    final List<Widget> listUI = <Widget>[];
    final List<String> dayNames = SafeDateUtils.getDutchDayNames();

    for (int i = 0; i < 7; i++) {
      listUI.add(
        Expanded(
          child: Center(
            child: Text(
              dayNames[i],
              style: TextStyle(
                fontSize: 16,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.guardPrimary,
              ),
            ),
          ),
        ),
      );
    }
    return listUI;
  }

  List<Widget> getDaysNoUI() {
    final List<Widget> noList = <Widget>[];
    int count = 0;
    for (int i = 0; i < dateList.length / 7; i++) {
      final List<Widget> listUI = <Widget>[];
      for (int i = 0; i < 7; i++) {
        final DateTime date = dateList[count];
        listUI.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(32.0),
                      ),
                      onTap: () {
                        if (currentMonthDate.month == date.month) {
                          if (widget.minimumDate != null &&
                              widget.maximumDate != null) {
                            final DateTime newminimumDate = DateTime(
                              widget.minimumDate!.year,
                              widget.minimumDate!.month,
                              widget.minimumDate!.day - 1,
                            );
                            final DateTime newmaximumDate = DateTime(
                              widget.maximumDate!.year,
                              widget.maximumDate!.month,
                              widget.maximumDate!.day + 1,
                            );
                            if (date.isAfter(newminimumDate) &&
                                date.isBefore(newmaximumDate)) {
                              onDateClick(date);
                            }
                          } else if (widget.minimumDate != null) {
                            final DateTime newminimumDate = DateTime(
                              widget.minimumDate!.year,
                              widget.minimumDate!.month,
                              widget.minimumDate!.day - 1,
                            );
                            if (date.isAfter(newminimumDate)) {
                              onDateClick(date);
                            }
                          } else if (widget.maximumDate != null) {
                            final DateTime newmaximumDate = DateTime(
                              widget.maximumDate!.year,
                              widget.maximumDate!.month,
                              widget.maximumDate!.day + 1,
                            );
                            if (date.isBefore(newmaximumDate)) {
                              onDateClick(date);
                            }
                          } else {
                            onDateClick(date);
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: getIsSelectedDate(date)
                                ? DesignTokens.guardPrimary
                                : Colors.transparent,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(32.0),
                            ),
                            border: Border.all(
                              color: getIsSelectedDate(date)
                                  ? DesignTokens.colorWhite
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: getIsSelectedDate(date)
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: DesignTokens.colorGray600,
                                      blurRadius: 4,
                                      offset: const Offset(0, 0),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: getIsSelectedDate(date)
                                    ? DesignTokens.colorWhite
                                    : currentMonthDate.month == date.month
                                    ? DesignTokens.guardTextPrimary
                                    : DesignTokens.guardTextSecondary
                                          .withValues(alpha: 0.6),
                                fontSize:
                                    MediaQuery.of(context).size.width > 360
                                    ? 18
                                    : 16,
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: getIsSelectedDate(date)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Shift indicator
                  if (hasShiftsOnDate(date))
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: getDateStatusColor(date),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  // Today indicator
                  if (DateTime.now().day == date.day &&
                      DateTime.now().month == date.month &&
                      DateTime.now().year == date.year)
                    Positioned(
                      bottom: 9,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: getIsSelectedDate(date)
                              ? DesignTokens.colorWhite
                              : DesignTokens.guardPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        count += 1;
      }
      noList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: listUI,
        ),
      );
    }
    return noList;
  }

  bool getIsSelectedDate(DateTime date) {
    if (selectedDate != null &&
        selectedDate!.day == date.day &&
        selectedDate!.month == date.month &&
        selectedDate!.year == date.year) {
      return true;
    }
    return false;
  }

  void onDateClick(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }
}
