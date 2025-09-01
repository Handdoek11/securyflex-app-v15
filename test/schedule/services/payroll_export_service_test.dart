import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/schedule/services/payroll_export_service.dart';
import 'package:securyflex_app/schedule/models/time_entry_model.dart';

void main() {
  late PayrollExportService service;

  setUp(() {
    service = PayrollExportService();
  });

  group('PayrollExportService - CAO 2024 Compliance Tests', () {
    group('Basic Payroll Export', () {
      test('should export simple payroll data to CSV', () async {
        // Arrange
        final timeEntries = [
          _createTestTimeEntry('guard_001', DateTime(2024, 3, 4)),
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-04 to 2024-03-10',
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        expect(csvFile.path.endsWith('.csv'), isTrue);

        final content = await csvFile.readAsString();
        expect(content, contains('guard_001'));
        expect(content, contains('Periode'));
        expect(content, contains('Medewerker ID'));
      });

      test('should handle empty time entries', () async {
        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: [],
          periodDescription: '2024-03-04 to 2024-03-10',
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
        expect(lines.length, equals(1)); // Only header
      });
    });

    group('Export Formats', () {
      test('should export to AFAS format', () async {
        // Arrange
        final timeEntries = [
          _createTestTimeEntry('guard_002', DateTime(2024, 3, 4)),
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-04 to 2024-03-10',
          format: PayrollFormat.afas,
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        expect(content, contains('guard_002'));
      });

      test('should export to Exact Online format', () async {
        // Arrange
        final timeEntries = [
          _createTestTimeEntry('guard_003', DateTime(2024, 3, 4)),
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-04 to 2024-03-10',
          format: PayrollFormat.exact,
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        expect(content, contains('guard_003'));
      });

      test('should export to Nmbrs format', () async {
        // Arrange
        final timeEntries = [
          _createTestTimeEntry('guard_004', DateTime(2024, 3, 4)),
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-04 to 2024-03-10',
          format: PayrollFormat.nmbrs,
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        expect(content, contains('guard_004'));
      });
    });

    group('Dutch Business Rules', () {
      test('should handle weekend hours correctly', () async {
        // Arrange - Saturday shift
        final timeEntries = [
          _createWeekendTimeEntry('guard_005', DateTime(2024, 3, 9)), // Saturday
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-09 Weekend Shift',
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        expect(content, contains('Weekend Uren'));
      });

      test('should handle night shift hours correctly', () async {
        // Arrange - Night shift
        final timeEntries = [
          _createNightTimeEntry('guard_006', DateTime(2024, 3, 4)),
        ];

        // Act
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: '2024-03-04 Night Shift',
        );

        // Assert
        expect(csvFile.existsSync(), isTrue);
        final content = await csvFile.readAsString();
        expect(content, contains('Nacht Uren'));
      });
    });

    group('Error Handling', () {
      test('should validate invalid period description', () async {
        // Arrange
        final timeEntries = [
          _createTestTimeEntry('guard_007', DateTime(2024, 3, 4)),
        ];

        // Act & Assert - Should not throw for basic validation
        final csvFile = await service.exportToCSV(
          timeEntries: timeEntries,
          periodDescription: 'Invalid/Special*Characters',
        );
        
        expect(csvFile.existsSync(), isTrue);
      });
    });
  });
}

/// Helper function to create a test time entry
TimeEntry _createTestTimeEntry(String guardId, DateTime date) {
  return TimeEntry(
    id: 'entry_${guardId}_${date.millisecondsSinceEpoch}',
    guardId: guardId,
    jobSiteId: 'job_site_001',
    companyId: 'company_001',
    shiftId: 'shift_001',
    checkInTime: date.add(Duration(hours: 8)),
    checkOutTime: date.add(Duration(hours: 17)),
    actualWorkDuration: Duration(hours: 8),
    plannedWorkDuration: Duration(hours: 8),
    breaks: [],
    checkInLocation: null,
    checkOutLocation: null,
    checkInVerified: true,
    checkOutVerified: true,
    locationPings: [],
    status: TimeEntryStatus.approved,
    regularHours: 8.0,
    overtimeHours: 0.0,
    weekendHours: 0.0,
    nightHours: 0.0,
    caoCompliance: const CAOCompliance(
      isCompliant: true,
      violations: [],
      restPeriodBefore: 11.0,
      restPeriodAfter: 11.0,
      hasRequiredBreaks: true,
      weeklyHours: 40.0,
      exceedsWeeklyLimit: false,
      exceedsDailyLimit: false,
    ),
    guardApproved: true,
    companyApproved: true,
    guardApprovedAt: date.add(Duration(hours: 18)),
    companyApprovedAt: date.add(Duration(hours: 18)),
    approvalNotes: null,
    discrepancies: [],
    createdAt: date,
    updatedAt: date.add(Duration(hours: 18)),
    metadata: {},
    photos: [],
    notes: null,
  );
}

/// Helper function to create weekend time entry
TimeEntry _createWeekendTimeEntry(String guardId, DateTime date) {
  return TimeEntry(
    id: 'weekend_${guardId}_${date.millisecondsSinceEpoch}',
    guardId: guardId,
    jobSiteId: 'job_site_001',
    companyId: 'company_001',
    shiftId: 'weekend_shift_001',
    checkInTime: date.add(Duration(hours: 8)),
    checkOutTime: date.add(Duration(hours: 17)),
    actualWorkDuration: Duration(hours: 8),
    plannedWorkDuration: Duration(hours: 8),
    breaks: [],
    checkInLocation: null,
    checkOutLocation: null,
    checkInVerified: true,
    checkOutVerified: true,
    locationPings: [],
    status: TimeEntryStatus.approved,
    regularHours: 0.0,
    overtimeHours: 0.0,
    weekendHours: 8.0, // Weekend hours
    nightHours: 0.0,
    caoCompliance: const CAOCompliance(
      isCompliant: true,
      violations: [],
      restPeriodBefore: 11.0,
      restPeriodAfter: 11.0,
      hasRequiredBreaks: true,
      weeklyHours: 40.0,
      exceedsWeeklyLimit: false,
      exceedsDailyLimit: false,
    ),
    guardApproved: true,
    companyApproved: true,
    guardApprovedAt: date.add(Duration(hours: 18)),
    companyApprovedAt: date.add(Duration(hours: 18)),
    approvalNotes: null,
    discrepancies: [],
    createdAt: date,
    updatedAt: date.add(Duration(hours: 18)),
    metadata: {},
    photos: [],
    notes: null,
  );
}

/// Helper function to create night shift time entry
TimeEntry _createNightTimeEntry(String guardId, DateTime date) {
  return TimeEntry(
    id: 'night_${guardId}_${date.millisecondsSinceEpoch}',
    guardId: guardId,
    jobSiteId: 'job_site_001',
    companyId: 'company_001',
    shiftId: 'night_shift_001',
    checkInTime: date.add(Duration(hours: 22)), // 10 PM
    checkOutTime: date.add(Duration(hours: 30)), // 6 AM next day
    actualWorkDuration: Duration(hours: 8),
    plannedWorkDuration: Duration(hours: 8),
    breaks: [],
    checkInLocation: null,
    checkOutLocation: null,
    checkInVerified: true,
    checkOutVerified: true,
    locationPings: [],
    status: TimeEntryStatus.approved,
    regularHours: 0.0,
    overtimeHours: 0.0,
    weekendHours: 0.0,
    nightHours: 8.0, // Night hours
    caoCompliance: const CAOCompliance(
      isCompliant: true,
      violations: [],
      restPeriodBefore: 11.0,
      restPeriodAfter: 11.0,
      hasRequiredBreaks: true,
      weeklyHours: 40.0,
      exceedsWeeklyLimit: false,
      exceedsDailyLimit: false,
    ),
    guardApproved: true,
    companyApproved: true,
    guardApprovedAt: date.add(Duration(hours: 31)),
    companyApprovedAt: date.add(Duration(hours: 31)),
    approvalNotes: null,
    discrepancies: [],
    createdAt: date,
    updatedAt: date.add(Duration(hours: 31)),
    metadata: {},
    photos: [],
    notes: null,
  );
}