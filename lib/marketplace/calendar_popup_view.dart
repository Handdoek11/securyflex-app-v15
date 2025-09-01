import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../unified_design_tokens.dart';
import '../unified_buttons.dart';
import '../unified_theme_system.dart';
import '../unified_card_system.dart';

import 'custom_calendar.dart';

class CalendarPopupView extends StatefulWidget {
  const CalendarPopupView(
      {super.key,
      this.initialStartDate,
      this.initialEndDate,
      this.onApplyClick,
      this.onCancelClick,
      this.barrierDismissible = true,
      this.minimumDate,
      this.maximumDate});

  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final bool barrierDismissible;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime, DateTime)? onApplyClick;

  final Function()? onCancelClick;
  @override
  State<CalendarPopupView> createState() => _CalendarPopupViewState();
}

class _CalendarPopupViewState extends State<CalendarPopupView>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    animationController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    if (widget.initialStartDate != null) {
      startDate = widget.initialStartDate;
    }
    if (widget.initialEndDate != null) {
      endDate = widget.initialEndDate;
    }
    animationController?.forward();
    super.initState();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: animationController!,
          builder: (BuildContext context, Widget? child) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: animationController!.value,
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  if (widget.barrierDismissible) {
                    Navigator.pop(context);
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: UnifiedCard(
                      variant: UnifiedCardVariant.standard,
                      userRole: UserRole.guard,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Date range header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.spacingM,
                              horizontal: DesignTokens.spacingM,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Van',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight: DesignTokens.fontWeightMedium,
                                          fontSize: DesignTokens.fontSizeCaption,
                                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        startDate != null
                                            ? DateFormat('EEE, dd MMM', 'nl_NL')
                                                .format(startDate!)
                                            : '--/--',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight: DesignTokens.fontWeightSemiBold,
                                          fontSize: DesignTokens.fontSizeBody,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Tot',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight: DesignTokens.fontWeightMedium,
                                          fontSize: DesignTokens.fontSizeCaption,
                                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        endDate != null
                                            ? DateFormat('EEE, dd MMM', 'nl_NL')
                                                .format(endDate!)
                                            : '--/--',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: DesignTokens.fontFamily,
                                          fontWeight: DesignTokens.fontWeightSemiBold,
                                          fontSize: DesignTokens.fontSizeBody,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spacingL),
                          
                          // Calendar view
                          CustomCalendarView(
                            minimumDate: widget.minimumDate,
                            maximumDate: widget.maximumDate,
                            initialEndDate: widget.initialEndDate,
                            initialStartDate: widget.initialStartDate,
                            startEndDateChange: (DateTime startDateData,
                                DateTime endDateData) {
                              setState(() {
                                startDate = startDateData;
                                endDate = endDateData;
                              });
                            },
                          ),
                          
                          const SizedBox(height: DesignTokens.spacingL),
                          
                          // Apply button
                          UnifiedButton.primary(
                            text: 'Toepassen',
                            onPressed: () {
                              try {
                                widget.onApplyClick!(startDate!, endDate!);
                                Navigator.pop(context);
                              } catch (_) {}
                            },
                            size: UnifiedButtonSize.large,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}