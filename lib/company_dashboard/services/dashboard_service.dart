
/// Service for managing dashboard data and metrics
/// Provides comprehensive dashboard functionality for security companies
class DashboardService {
  static DashboardService? _instance;
  static DashboardService get instance {
    _instance ??= DashboardService._();
    return _instance!;
  }

  DashboardService._();

  /// Get dashboard metrics for company
  Future<Map<String, dynamic>> getDashboardMetrics(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'totalJobs': 45,
      'activeJobs': 12,
      'completedJobs': 33,
      'totalRevenue': 125000.0,
      'monthlyRevenue': 28000.0,
      'totalGuards': 18,
      'availableGuards': 8,
      'onDutyGuards': 6,
      'averageRating': 4.7,
      'responseTime': 8.5,
    };
  }

  /// Get recent activity for company
  Future<List<Map<String, dynamic>>> getRecentActivity(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return [
      {
        'id': 'activity_1',
        'type': 'job_completed',
        'title': 'Nachtbeveiliging Voltooid',
        'description': 'Job #JOB001 is succesvol afgerond',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'guardName': 'Jan de Vries',
        'location': 'Amsterdam Centrum',
      },
      {
        'id': 'activity_2',
        'type': 'guard_assigned',
        'title': 'Beveiliger Toegewezen',
        'description': 'Maria van der Berg toegewezen aan Job #JOB002',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'guardName': 'Maria van der Berg',
        'location': 'Rotterdam Zuid',
      },
      {
        'id': 'activity_3',
        'type': 'emergency_response',
        'title': 'Noodoproep Beantwoord',
        'description': 'Snelle reactie op incident bij Job #JOB003',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'guardName': 'Piet Janssen',
        'location': 'Den Haag Noord',
      },
    ];
  }

  /// Get upcoming shifts for company
  Future<List<Map<String, dynamic>>> getUpcomingShifts(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    return [
      {
        'id': 'shift_1',
        'jobId': 'JOB004',
        'jobTitle': 'Evenementbeveiliging',
        'startTime': DateTime.now().add(const Duration(hours: 2)),
        'endTime': DateTime.now().add(const Duration(hours: 10)),
        'location': 'Utrecht Centrum',
        'assignedGuard': 'Lisa van der Berg',
        'status': 'confirmed',
      },
      {
        'id': 'shift_2',
        'jobId': 'JOB005',
        'jobTitle': 'Objectbeveiliging',
        'startTime': DateTime.now().add(const Duration(hours: 4)),
        'endTime': DateTime.now().add(const Duration(hours: 12)),
        'location': 'Eindhoven West',
        'assignedGuard': 'Tom Hendriks',
        'status': 'pending',
      },
      {
        'id': 'shift_3',
        'jobId': 'JOB006',
        'jobTitle': 'Nachtbeveiliging',
        'startTime': DateTime.now().add(const Duration(hours: 8)),
        'endTime': DateTime.now().add(const Duration(hours: 16)),
        'location': 'Tilburg Centrum',
        'assignedGuard': 'Sarah de Jong',
        'status': 'confirmed',
      },
    ];
  }

  /// Get financial overview for company
  Future<Map<String, dynamic>> getFinancialOverview(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'totalRevenue': 125000.0,
      'monthlyRevenue': 28000.0,
      'weeklyRevenue': 6500.0,
      'pendingPayments': 8500.0,
      'averageJobValue': 2800.0,
      'revenueGrowth': 12.5,
      'topRevenueSource': 'Objectbeveiliging',
      'monthlyExpenses': 18000.0,
      'profitMargin': 35.7,
    };
  }
}
