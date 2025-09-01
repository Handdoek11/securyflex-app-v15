import 'package:securyflex_app/beveiliger_dashboard/models/daily_overview_data.dart';
import 'package:securyflex_app/beveiliger_agenda/models/shift_data.dart';

/// Service for managing daily overview data for guards
/// Provides comprehensive daily metrics, earnings, and shift information
class DailyOverviewService {
  static final DailyOverviewService _instance = DailyOverviewService._internal();
  factory DailyOverviewService() => _instance;
  DailyOverviewService._internal();

  static DailyOverviewService get instance => _instance;

  /// Cache for daily overview data
  DailyOverviewData? _cachedData;
  DateTime? _lastCacheUpdate;

  /// Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get comprehensive daily overview data
  Future<DailyOverviewData> getDailyOverview() async {
    // Check cache validity
    if (_cachedData != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
      return _cachedData!;
    }

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // In a real implementation, this would fetch from multiple APIs
      final data = await _fetchDailyOverviewData();
      
      // Update cache
      _cachedData = data;
      _lastCacheUpdate = DateTime.now();
      
      return data;
    } catch (e) {
      // Return sample data on error for demo purposes
      return DailyOverviewData.createSampleData();
    }
  }

  /// Fetch daily overview data from various sources
  Future<DailyOverviewData> _fetchDailyOverviewData() async {
    final now = DateTime.now();
    
    // Get shifts for today and tomorrow
    final allShifts = ShiftData.getSampleShifts();
    final todaysShifts = allShifts
        .where((shift) => _isSameDay(shift.startTime, now))
        .toList();
    final tomorrowsShifts = allShifts
        .where((shift) => _isSameDay(shift.startTime, now.add(Duration(days: 1))))
        .toList();

    // Calculate time tracking metrics
    final timeMetrics = _calculateTimeMetrics(todaysShifts);
    
    // Calculate earnings metrics
    final earningsMetrics = _calculateEarningsMetrics(todaysShifts);
    
    // Calculate performance metrics
    final performanceMetrics = _calculatePerformanceMetrics();
    
    // Get notifications and reminders
    final notifications = _getNotifications();
    
    // Get planning information
    final planningInfo = _getPlanningInfo(todaysShifts, tomorrowsShifts);

    return DailyOverviewData(
      // Time tracking
      hoursWorkedToday: timeMetrics['hoursWorked'] ?? 0.0,
      scheduledHoursToday: timeMetrics['scheduledHours'] ?? 0.0,
      remainingHoursToday: timeMetrics['remainingHours'] ?? 0.0,
      isCurrentlyWorking: timeMetrics['isWorking'] ?? false,
      currentShiftStart: timeMetrics['currentShiftStart'],
      currentShiftEnd: timeMetrics['currentShiftEnd'],
      breakTime: timeMetrics['breakTime'] ?? Duration.zero,
      overtimeHours: timeMetrics['overtimeHours'] ?? 0.0,
      
      // Earnings
      earningsToday: earningsMetrics['earningsToday'] ?? 0.0,
      projectedEarningsToday: earningsMetrics['projectedEarnings'] ?? 0.0,
      averageHourlyRate: earningsMetrics['averageRate'] ?? 0.0,
      bonusEarnings: earningsMetrics['bonusEarnings'] ?? 0.0,
      totalWeeklyEarnings: earningsMetrics['weeklyEarnings'] ?? 0.0,
      monthlyTarget: earningsMetrics['monthlyTarget'] ?? 0.0,
      monthlyProgress: earningsMetrics['monthlyProgress'] ?? 0.0,
      
      // Jobs & Shifts
      todaysShifts: todaysShifts,
      tomorrowsShifts: tomorrowsShifts,
      completedShiftsToday: planningInfo['completedShifts'] ?? 0,
      remainingShiftsToday: planningInfo['remainingShifts'] ?? 0,
      currentShift: planningInfo['currentShift'],
      nextShift: planningInfo['nextShift'],
      
      // Performance
      punctualityScore: performanceMetrics['punctualityScore'] ?? 0.0,
      weeklyEfficiencyScore: performanceMetrics['efficiencyScore'] ?? 0.0,
      consecutiveWorkDays: performanceMetrics['consecutiveDays'] ?? 0,
      clientSatisfactionScore: performanceMetrics['satisfactionScore'] ?? 0.0,
      todaysAchievements: performanceMetrics['achievements'] ?? [],
      
      // Notifications
      urgentNotifications: notifications['urgent'] ?? [],
      reminders: notifications['reminders'] ?? [],
      hasUnreadMessages: notifications['hasUnread'] ?? false,
      newJobOffers: notifications['newOffers'] ?? 0,
      
      // Planning
      availableTimeSlots: planningInfo['availableSlots'] ?? [],
      isAvailableForUrgentJobs: planningInfo['availableForUrgent'] ?? true,
      timeUntilNextShift: planningInfo['timeUntilNext'] ?? Duration.zero,
      currentStatus: planningInfo['currentStatus'] ?? 'Beschikbaar',
      
      // Weekly context
      weeklyHoursWorked: timeMetrics['weeklyHours'] ?? 0.0,
      weeklyHoursTarget: 40.0,
      shiftsCompletedThisWeek: performanceMetrics['weeklyShifts'] ?? 0,
      weeklyEarnings: earningsMetrics['weeklyEarnings'] ?? 0.0,
    );
  }

  /// Calculate time tracking metrics
  Map<String, dynamic> _calculateTimeMetrics(List<ShiftData> todaysShifts) {
    final now = DateTime.now();
    double hoursWorked = 0.0;
    double scheduledHours = 0.0;
    bool isWorking = false;
    DateTime? currentShiftStart;
    DateTime? currentShiftEnd;
    
    for (final shift in todaysShifts) {
      scheduledHours += shift.durationInHours;
      
      // Check if currently working this shift
      if (shift.status == ShiftStatus.inProgress &&
          now.isAfter(shift.startTime) && 
          now.isBefore(shift.endTime)) {
        isWorking = true;
        currentShiftStart = shift.startTime;
        currentShiftEnd = shift.endTime;
        
        // Calculate hours worked so far in current shift
        final workedDuration = now.difference(shift.startTime);
        hoursWorked += workedDuration.inMinutes / 60.0;
      } else if (shift.status == ShiftStatus.completed) {
        hoursWorked += shift.durationInHours;
      }
    }

    return {
      'hoursWorked': hoursWorked,
      'scheduledHours': scheduledHours,
      'remainingHours': (scheduledHours - hoursWorked).clamp(0.0, double.infinity),
      'isWorking': isWorking,
      'currentShiftStart': currentShiftStart,
      'currentShiftEnd': currentShiftEnd,
      'breakTime': Duration(minutes: 30), // Mock break time
      'overtimeHours': (hoursWorked > 8.0) ? hoursWorked - 8.0 : 0.0,
      'weeklyHours': 32.5, // Mock weekly hours
    };
  }

  /// Calculate earnings metrics
  Map<String, dynamic> _calculateEarningsMetrics(List<ShiftData> todaysShifts) {
    double earningsToday = 0.0;
    double projectedEarnings = 0.0;
    double totalRate = 0.0;
    int shiftCount = 0;

    for (final shift in todaysShifts) {
      totalRate += shift.hourlyRate;
      shiftCount++;
      
      if (shift.status == ShiftStatus.completed) {
        earningsToday += shift.totalAmount;
      }
      
      projectedEarnings += shift.totalAmount;
    }

    final averageRate = shiftCount > 0 ? totalRate / shiftCount : 0.0;

    return {
      'earningsToday': earningsToday,
      'projectedEarnings': projectedEarnings,
      'averageRate': averageRate,
      'bonusEarnings': 25.00, // Mock bonus
      'weeklyEarnings': 780.00, // Mock weekly earnings
      'monthlyTarget': 3200.00, // Mock monthly target
      'monthlyProgress': 2450.00, // Mock monthly progress
    };
  }

  /// Calculate performance metrics
  Map<String, dynamic> _calculatePerformanceMetrics() {
    return {
      'punctualityScore': 94.5,
      'efficiencyScore': 87.2,
      'consecutiveDays': 4,
      'satisfactionScore': 4.7,
      'weeklyShifts': 4,
      'achievements': [
        'Perfect punctualiteit',
        'Positieve klantfeedback',
        'Overtime bonus behaald',
      ],
    };
  }

  /// Get notifications and alerts
  Map<String, dynamic> _getNotifications() {
    return {
      'urgent': [
        'Nieuwe urgente opdracht beschikbaar',
      ],
      'reminders': [
        'Shift rapport invullen om 17:00',
        'Volgende shift morgen om 08:00',
      ],
      'hasUnread': true,
      'newOffers': 3,
    };
  }

  /// Get planning information
  Map<String, dynamic> _getPlanningInfo(List<ShiftData> todaysShifts, List<ShiftData> tomorrowsShifts) {
    final now = DateTime.now();
    
    // Find current and next shifts
    ShiftData? currentShift;
    ShiftData? nextShift;
    
    for (final shift in todaysShifts) {
      if (shift.status == ShiftStatus.inProgress) {
        currentShift = shift;
        break;
      }
    }
    
    // Find next upcoming shift
    final upcomingShifts = [...todaysShifts, ...tomorrowsShifts]
        .where((shift) => shift.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcomingShifts.isNotEmpty) {
      nextShift = upcomingShifts.first;
    }

    final completedShifts = todaysShifts.where((s) => s.status == ShiftStatus.completed).length;
    final remainingShifts = todaysShifts.where((s) => s.status != ShiftStatus.completed).length;

    return {
      'currentShift': currentShift,
      'nextShift': nextShift,
      'completedShifts': completedShifts,
      'remainingShifts': remainingShifts,
      'availableSlots': [
        DateTime(now.year, now.month, now.day + 1, 19, 0),
        DateTime(now.year, now.month, now.day + 2, 8, 0),
      ],
      'availableForUrgent': true,
      'timeUntilNext': nextShift?.startTime.difference(now) ?? Duration.zero,
      'currentStatus': currentShift != null ? 'Bezig met shift' : 'Beschikbaar',
    };
  }

  /// Refresh cached data
  Future<void> refreshData() async {
    _cachedData = null;
    _lastCacheUpdate = null;
    await getDailyOverview();
  }

  /// Update specific metrics (for real-time updates)
  Future<void> updateTimeTracking({
    double? hoursWorked,
    bool? isCurrentlyWorking,
  }) async {
    // Ensure we have data to update
    if (_cachedData == null) {
      await getDailyOverview();
    }

    if (_cachedData != null) {
      _cachedData = _cachedData!.copyWith(
        hoursWorkedToday: hoursWorked,
        isCurrentlyWorking: isCurrentlyWorking,
      );
    }
  }

  /// Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Clear cache (for testing)
  void clearCache() {
    _cachedData = null;
    _lastCacheUpdate = null;
  }
}
