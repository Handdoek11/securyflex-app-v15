import 'package:flutter/material.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import '../../unified_design_tokens.dart';
import '../../unified_header.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/unified_background_service.dart';
import '../models/shift_data.dart';
import '../models/planning_category_data.dart';
import '../widgets/next_shift_card.dart';
import '../widgets/planning_categories.dart';
import '../widgets/planning_calendar.dart';
import '../utils/date_utils.dart';

class PlanningMainScreen extends StatefulWidget {
  const PlanningMainScreen({super.key, this.animationController});

  final AnimationController? animationController;
  @override
  State<PlanningMainScreen> createState() => _PlanningMainScreenState();
}

// Helper widget to reduce nesting - combines animation and card styling
class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.animationController,
    required this.interval,
    required this.child,
  });

  final AnimationController animationController;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Flattened structure: max 6 levels instead of 10
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: interval,
      ),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, _) {
        return FadeTransition(
          opacity: animation,
          child: Container(
            margin: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: 18,
            ),
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorWhite,
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: DesignTokens.colorGray500.withValues(alpha: 0.4),
                  offset: const Offset(1.1, 1.1),
                  blurRadius: 10.0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _PlanningMainScreenState extends State<PlanningMainScreen>
    with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;

  List<Widget> listViews = <Widget>[];
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;
  DateTime selectedDate = DateTime.now();
  List<ShiftData> shifts = ShiftData.getSampleShifts();
  PlanningCategoryData? selectedCategory;

  @override
  void initState() {
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController!,
        curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );
    addAllListData();

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });
    super.initState();
  }

  void addAllListData() {
    const int count = 4;

    // Next Shift Card
    listViews.add(
      NextShiftCard(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: widget.animationController!,
            curve: Interval((1 / count) * 0, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        animationController: widget.animationController!,
        nextShift: _getNextShift(),
        onTap: () {
          // Navigate to shift details
        },
      ),
    );

    // Planning Categories
    listViews.add(
      PlanningCategoriesView(
        mainScreenAnimation: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: widget.animationController!,
            curve: Interval((1 / count) * 1, 1.0, curve: Curves.fastOutSlowIn),
          ),
        ),
        mainScreenAnimationController: widget.animationController!,
        onCategorySelected: (category) {
          setState(() {
            selectedCategory = category;
          });
          _handleCategorySelection(category);
        },
      ),
    );

    // Content based on selected category
    if (selectedCategory != null) {
      listViews.add(_buildCategoryContent());
    } else {
      // Default content - Today's shifts
      listViews.add(_buildTodaysShiftsSummary());
    }
  }

  ShiftData? _getNextShift() {
    final now = DateTime.now();
    final upcomingShifts = shifts
        .where(
          (shift) =>
              shift.startTime.isAfter(now) &&
              (shift.status == ShiftStatus.confirmed ||
                  shift.status == ShiftStatus.accepted),
        )
        .toList();

    if (upcomingShifts.isEmpty) return null;

    upcomingShifts.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcomingShifts.first;
  }

  void _handleCategorySelection(PlanningCategoryData category) {
    // Rebuild the list based on selected category
    setState(() {
      listViews.clear();
      addAllListData();
    });
  }

  Widget _buildCategoryContent() {
    switch (selectedCategory!.viewType) {
      case PlanningViewType.day:
        return _buildTodaysShiftsSummary();
      case PlanningViewType.week:
        return _buildWeekView();
      case PlanningViewType.calendar:
        return _buildCalendarView();
      case PlanningViewType.month:
        return _buildAvailabilityView();
    }
  }

  Widget _buildWeekView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekShifts = <DateTime, List<ShiftData>>{};

    // Group shifts by day for this week
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      weekShifts[day] = shifts
          .where((shift) => SafeDateUtils.isSameDay(shift.startTime, day))
          .toList();
    }

    // Simplified structure: only 6 levels deep instead of 10
    return _AnimatedCard(
      animationController: widget.animationController!,
      interval: Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deze Week (${SafeDateUtils.formatDayMonth(startOfWeek)} - ${SafeDateUtils.formatDayMonth(startOfWeek.add(Duration(days: 6)))})',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeTitle,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          ...weekShifts.entries.map(
            (entry) => _buildDayRow(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(DateTime day, List<ShiftData> dayShifts) {
    final dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
    final dayName = dayNames[day.weekday - 1];
    final isToday = SafeDateUtils.isSameDay(day, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacingS + 4),
      decoration: BoxDecoration(
        color: isToday
            ? DesignTokens.statusInProgress.withValues(alpha: 0.1)
            : DesignTokens.colorGray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: isToday
            ? Border.all(
                color: DesignTokens.statusInProgress.withValues(alpha: 0.3),
              )
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
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontSize: DesignTokens.fontSizeBody,
                    color: isToday
                        ? DesignTokens.guardPrimary
                        : DesignTokens.guardTextPrimary,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.guardTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayShifts.isEmpty
                ? Text(
                    'Geen diensten',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightRegular,
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.guardTextSecondary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dayShifts
                        .map(
                          (shift) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  shift.shiftTypeIcon,
                                  size: 16,
                                  color: shift.statusColor,
                                ),
                                const SizedBox(width: DesignTokens.spacingS),
                                Expanded(
                                  child: Text(
                                    '${shift.title} (${SafeDateUtils.formatTimeRange(shift.startTime, shift.endTime)})',
                                    style: TextStyle(
                                      fontFamily: DesignTokens.fontFamily,
                                      fontWeight: DesignTokens.fontWeightMedium,
                                      fontSize: DesignTokens.fontSizeCaption,
                                      color: DesignTokens.guardTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    // Simplified structure: reduced nesting levels
    return _AnimatedCard(
      animationController: widget.animationController!,
      interval: Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender Overzicht',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeTitle,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          PlanningCalendarView(
            initialSelectedDate: selectedDate,
            shifts: shifts,
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildSelectedDateShifts(),
        ],
      ),
    );
  }

  Widget _buildSelectedDateShifts() {
    final selectedShifts = shifts
        .where(
          (shift) => SafeDateUtils.isSameDay(shift.startTime, selectedDate),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diensten op ${SafeDateUtils.formatDayMonth(selectedDate)}',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        if (selectedShifts.isEmpty)
          Text(
            'Geen diensten gepland',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.guardTextSecondary,
            ),
          )
        else
          ...selectedShifts.map((shift) => _buildShiftListItem(shift)),
      ],
    );
  }

  Widget _buildAvailabilityView() {
    final availabilitySlots = [
      {
        'day': 'Maandag',
        'times': ['08:00 - 17:00', '18:00 - 22:00'],
      },
      {
        'day': 'Dinsdag',
        'times': ['08:00 - 17:00'],
      },
      {
        'day': 'Woensdag',
        'times': ['Niet beschikbaar'],
      },
      {
        'day': 'Donderdag',
        'times': ['08:00 - 17:00', '18:00 - 22:00'],
      },
      {
        'day': 'Vrijdag',
        'times': ['08:00 - 17:00'],
      },
      {
        'day': 'Zaterdag',
        'times': ['10:00 - 18:00'],
      },
      {
        'day': 'Zondag',
        'times': ['Niet beschikbaar'],
      },
    ];

    // Simplified structure: reduced nesting levels
    return _AnimatedCard(
      animationController: widget.animationController!,
      interval: Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mijn Beschikbaarheid',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeTitle,
                  color: DesignTokens.guardTextPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.guardPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Bewerken',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          ...availabilitySlots.map(
            (slot) => _buildAvailabilityRow(
              slot['day'] as String,
              slot['times'] as List<String>,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityRow(String day, List<String> times) {
    final isAvailable = !times.contains('Niet beschikbaar');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacingS + 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? DesignTokens.guardPrimary.withValues(alpha: 0.1)
            : DesignTokens.guardTextSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable
              ? DesignTokens.guardPrimary.withValues(alpha: 0.3)
              : DesignTokens.guardTextSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.guardTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: times
                  .map(
                    (time) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isAvailable
                                ? DesignTokens.guardPrimary
                                : DesignTokens.guardTextSecondary,
                          ),
                          const SizedBox(width: DesignTokens.spacingS),
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightRegular,
                              fontSize: DesignTokens.fontSizeCaption,
                              color: isAvailable
                                  ? DesignTokens.guardTextPrimary
                                  : DesignTokens.guardTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Icon(Icons.edit, size: 16, color: DesignTokens.guardTextSecondary),
        ],
      ),
    );
  }

  Widget _buildTodaysShiftsSummary() {
    final today = DateTime.now();
    final todaysShifts = shifts
        .where(
          (shift) =>
              shift.startTime.year == today.year &&
              shift.startTime.month == today.month &&
              shift.startTime.day == today.day,
        )
        .toList();

    // Simplified structure: reduced nesting levels
    return _AnimatedCard(
      animationController: widget.animationController!,
      interval: Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vandaag (${SafeDateUtils.formatDayMonth(today)})',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeTitle,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS + 4),
          if (todaysShifts.isEmpty)
            Text(
              'Geen diensten gepland voor vandaag',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.guardTextSecondary,
              ),
            )
          else
            ...todaysShifts.map(
              (shift) => _buildShiftListItem(shift),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftListItem(ShiftData shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(DesignTokens.spacingS + 4),
      decoration: BoxDecoration(
        color: shift.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: shift.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(shift.shiftTypeIcon, color: shift.statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.title,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontSize: DesignTokens.fontSizeBody,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
                Text(
                  SafeDateUtils.formatTimeRange(shift.startTime, shift.endTime),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.guardTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: shift.statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              shift.statusDisplayName,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeCaption,
                color: DesignTokens.colorWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedBackgroundService.guardPremiumBackground(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: getAppBarUI(),
        ),
        body: getMainListViewUI(),
      ),
    );
  }

  Widget getMainListViewUI() {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.only(
              top: 24, // Remove header padding since it's now in AppBar
              bottom: 62 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: listViews.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              widget.animationController?.forward();
              return listViews[index];
            },
          );
        }
      },
    );
  }

  Widget getAppBarUI() {
    return UnifiedHeader.animated(
      title: 'Planning',
      animationController: widget.animationController!,
      scrollController: scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.guard,
      titleAlignment: TextAlign.left,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                SafeDateUtils.formatDayMonth(selectedDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
