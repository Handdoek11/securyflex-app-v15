import 'package:securyflex_app/beveiliger_agenda/models/shift_data.dart';

/// Daily overview data model for guard dashboard
/// Provides comprehensive daily metrics and information
class DailyOverviewData {
  // Time tracking
  final double hoursWorkedToday;
  final double scheduledHoursToday;
  final double remainingHoursToday;
  final bool isCurrentlyWorking;
  final DateTime? currentShiftStart;
  final DateTime? currentShiftEnd;
  final Duration? breakTime;
  final double overtimeHours;
  
  // Earnings
  final double earningsToday;
  final double projectedEarningsToday;
  final double averageHourlyRate;
  final double bonusEarnings;
  final double totalWeeklyEarnings;
  final double monthlyTarget;
  final double monthlyProgress;
  
  // Jobs & Shifts
  final List<ShiftData> todaysShifts;
  final List<ShiftData> tomorrowsShifts;
  final int completedShiftsToday;
  final int remainingShiftsToday;
  final ShiftData? currentShift;
  final ShiftData? nextShift;
  
  // Performance metrics
  final double punctualityScore;
  final double weeklyEfficiencyScore;
  final int consecutiveWorkDays;
  final double clientSatisfactionScore;
  final List<String> todaysAchievements;
  
  // Notifications & alerts
  final List<String> urgentNotifications;
  final List<String> reminders;
  final bool hasUnreadMessages;
  final int newJobOffers;
  
  // Planning & availability
  final List<DateTime> availableTimeSlots;
  final bool isAvailableForUrgentJobs;
  final Duration timeUntilNextShift;
  final String currentStatus;
  
  // Weekly context
  final double weeklyHoursWorked;
  final double weeklyHoursTarget;
  final int shiftsCompletedThisWeek;
  final double weeklyEarnings;
  
  const DailyOverviewData({
    this.hoursWorkedToday = 0.0,
    this.scheduledHoursToday = 0.0,
    this.remainingHoursToday = 0.0,
    this.isCurrentlyWorking = false,
    this.currentShiftStart,
    this.currentShiftEnd,
    this.breakTime,
    this.overtimeHours = 0.0,
    this.earningsToday = 0.0,
    this.projectedEarningsToday = 0.0,
    this.averageHourlyRate = 0.0,
    this.bonusEarnings = 0.0,
    this.totalWeeklyEarnings = 0.0,
    this.monthlyTarget = 0.0,
    this.monthlyProgress = 0.0,
    this.todaysShifts = const [],
    this.tomorrowsShifts = const [],
    this.completedShiftsToday = 0,
    this.remainingShiftsToday = 0,
    this.currentShift,
    this.nextShift,
    this.punctualityScore = 0.0,
    this.weeklyEfficiencyScore = 0.0,
    this.consecutiveWorkDays = 0,
    this.clientSatisfactionScore = 0.0,
    this.todaysAchievements = const [],
    this.urgentNotifications = const [],
    this.reminders = const [],
    this.hasUnreadMessages = false,
    this.newJobOffers = 0,
    this.availableTimeSlots = const [],
    this.isAvailableForUrgentJobs = true,
    this.timeUntilNextShift = Duration.zero,
    this.currentStatus = 'Beschikbaar',
    this.weeklyHoursWorked = 0.0,
    this.weeklyHoursTarget = 40.0,
    this.shiftsCompletedThisWeek = 0,
    this.weeklyEarnings = 0.0,
  });

  /// Calculate completion percentage for today's work
  double get todaysCompletionPercentage {
    if (scheduledHoursToday == 0) return 0.0;
    return (hoursWorkedToday / scheduledHoursToday).clamp(0.0, 1.0);
  }

  /// Calculate weekly progress percentage
  double get weeklyProgressPercentage {
    if (weeklyHoursTarget == 0) return 0.0;
    return (weeklyHoursWorked / weeklyHoursTarget).clamp(0.0, 1.0);
  }

  /// Calculate monthly earnings progress percentage
  double get monthlyEarningsPercentage {
    if (monthlyTarget == 0) return 0.0;
    return (monthlyProgress / monthlyTarget).clamp(0.0, 1.0);
  }

  /// Check if guard is on track for daily target
  bool get isOnTrackToday {
    final now = DateTime.now();
    final dayProgress = (now.hour + now.minute / 60.0) / 24.0;
    final workProgress = todaysCompletionPercentage;
    return workProgress >= dayProgress * 0.8; // Allow 20% buffer
  }

  /// Get current shift status text
  String get currentShiftStatus {
    if (isCurrentlyWorking && currentShift != null) {
      return 'Bezig: ${currentShift!.title}';
    } else if (nextShift != null) {
      final timeUntil = nextShift!.startTime.difference(DateTime.now());
      if (timeUntil.inHours < 2) {
        return 'Volgende shift over ${timeUntil.inMinutes} min';
      } else {
        return 'Volgende shift om ${_formatTime(nextShift!.startTime)}';
      }
    } else {
      return 'Geen geplande shifts';
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Copy with method for updates
  DailyOverviewData copyWith({
    double? hoursWorkedToday,
    double? scheduledHoursToday,
    double? remainingHoursToday,
    bool? isCurrentlyWorking,
    DateTime? currentShiftStart,
    DateTime? currentShiftEnd,
    Duration? breakTime,
    double? overtimeHours,
    double? earningsToday,
    double? projectedEarningsToday,
    double? averageHourlyRate,
    double? bonusEarnings,
    double? totalWeeklyEarnings,
    double? monthlyTarget,
    double? monthlyProgress,
    List<ShiftData>? todaysShifts,
    List<ShiftData>? tomorrowsShifts,
    int? completedShiftsToday,
    int? remainingShiftsToday,
    ShiftData? currentShift,
    ShiftData? nextShift,
    double? punctualityScore,
    double? weeklyEfficiencyScore,
    int? consecutiveWorkDays,
    double? clientSatisfactionScore,
    List<String>? todaysAchievements,
    List<String>? urgentNotifications,
    List<String>? reminders,
    bool? hasUnreadMessages,
    int? newJobOffers,
    List<DateTime>? availableTimeSlots,
    bool? isAvailableForUrgentJobs,
    Duration? timeUntilNextShift,
    String? currentStatus,
    double? weeklyHoursWorked,
    double? weeklyHoursTarget,
    int? shiftsCompletedThisWeek,
    double? weeklyEarnings,
  }) {
    return DailyOverviewData(
      hoursWorkedToday: hoursWorkedToday ?? this.hoursWorkedToday,
      scheduledHoursToday: scheduledHoursToday ?? this.scheduledHoursToday,
      remainingHoursToday: remainingHoursToday ?? this.remainingHoursToday,
      isCurrentlyWorking: isCurrentlyWorking ?? this.isCurrentlyWorking,
      currentShiftStart: currentShiftStart ?? this.currentShiftStart,
      currentShiftEnd: currentShiftEnd ?? this.currentShiftEnd,
      breakTime: breakTime ?? this.breakTime,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      earningsToday: earningsToday ?? this.earningsToday,
      projectedEarningsToday: projectedEarningsToday ?? this.projectedEarningsToday,
      averageHourlyRate: averageHourlyRate ?? this.averageHourlyRate,
      bonusEarnings: bonusEarnings ?? this.bonusEarnings,
      totalWeeklyEarnings: totalWeeklyEarnings ?? this.totalWeeklyEarnings,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
      todaysShifts: todaysShifts ?? this.todaysShifts,
      tomorrowsShifts: tomorrowsShifts ?? this.tomorrowsShifts,
      completedShiftsToday: completedShiftsToday ?? this.completedShiftsToday,
      remainingShiftsToday: remainingShiftsToday ?? this.remainingShiftsToday,
      currentShift: currentShift ?? this.currentShift,
      nextShift: nextShift ?? this.nextShift,
      punctualityScore: punctualityScore ?? this.punctualityScore,
      weeklyEfficiencyScore: weeklyEfficiencyScore ?? this.weeklyEfficiencyScore,
      consecutiveWorkDays: consecutiveWorkDays ?? this.consecutiveWorkDays,
      clientSatisfactionScore: clientSatisfactionScore ?? this.clientSatisfactionScore,
      todaysAchievements: todaysAchievements ?? this.todaysAchievements,
      urgentNotifications: urgentNotifications ?? this.urgentNotifications,
      reminders: reminders ?? this.reminders,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      newJobOffers: newJobOffers ?? this.newJobOffers,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      isAvailableForUrgentJobs: isAvailableForUrgentJobs ?? this.isAvailableForUrgentJobs,
      timeUntilNextShift: timeUntilNextShift ?? this.timeUntilNextShift,
      currentStatus: currentStatus ?? this.currentStatus,
      weeklyHoursWorked: weeklyHoursWorked ?? this.weeklyHoursWorked,
      weeklyHoursTarget: weeklyHoursTarget ?? this.weeklyHoursTarget,
      shiftsCompletedThisWeek: shiftsCompletedThisWeek ?? this.shiftsCompletedThisWeek,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
    );
  }

  /// Create sample data for testing
  static DailyOverviewData createSampleData() {
    final now = DateTime.now();
    final todayShifts = ShiftData.getSampleShifts()
        .where((shift) => _isSameDay(shift.startTime, now))
        .toList();
    
    final tomorrowShifts = ShiftData.getSampleShifts()
        .where((shift) => _isSameDay(shift.startTime, now.add(Duration(days: 1))))
        .toList();

    return DailyOverviewData(
      hoursWorkedToday: 6.5,
      scheduledHoursToday: 8.0,
      remainingHoursToday: 1.5,
      isCurrentlyWorking: true,
      currentShiftStart: DateTime(now.year, now.month, now.day, 8, 0),
      currentShiftEnd: DateTime(now.year, now.month, now.day, 17, 0),
      breakTime: Duration(minutes: 30),
      overtimeHours: 0.5,
      earningsToday: 156.00,
      projectedEarningsToday: 192.00,
      averageHourlyRate: 19.50,
      bonusEarnings: 25.00,
      totalWeeklyEarnings: 780.00,
      monthlyTarget: 3200.00,
      monthlyProgress: 2450.00,
      todaysShifts: todayShifts,
      tomorrowsShifts: tomorrowShifts,
      completedShiftsToday: 1,
      remainingShiftsToday: 1,
      currentShift: todayShifts.isNotEmpty ? todayShifts.first : null,
      nextShift: tomorrowShifts.isNotEmpty ? tomorrowShifts.first : null,
      punctualityScore: 94.5,
      weeklyEfficiencyScore: 87.2,
      consecutiveWorkDays: 4,
      clientSatisfactionScore: 4.7,
      todaysAchievements: [
        'Perfect punctualiteit',
        'Positieve klantfeedback',
        'Overtime bonus behaald',
      ],
      urgentNotifications: [
        'Nieuwe urgente opdracht beschikbaar',
      ],
      reminders: [
        'Shift rapport invullen om 17:00',
        'Volgende shift morgen om 08:00',
      ],
      hasUnreadMessages: true,
      newJobOffers: 3,
      availableTimeSlots: [
        DateTime(now.year, now.month, now.day + 1, 19, 0),
        DateTime(now.year, now.month, now.day + 2, 8, 0),
      ],
      isAvailableForUrgentJobs: true,
      timeUntilNextShift: Duration(hours: 15),
      currentStatus: 'Bezig met shift',
      weeklyHoursWorked: 32.5,
      weeklyHoursTarget: 40.0,
      shiftsCompletedThisWeek: 4,
      weeklyEarnings: 780.00,
    );
  }

  /// Helper method to check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
