import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'helpers/firebase_test_helper.dart';

void main() {
  group('Application Functionality Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing to prevent "No Firebase App created" errors
      await FirebaseTestHelper.setupTestGroup();
    });

    setUp(() {
      // Reset state before each test
      AuthService.logout();
      ApplicationService.clearAllApplications();
    });

    test('Should not allow application when not logged in', () async {
      expect(AuthService.isLoggedIn, isFalse);
      
      final success = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Test motivation',
        contactPreference: 'email',
      );
      
      expect(success, isFalse);
      expect(await ApplicationService.getUserApplicationCount(), equals(0));
    });

    test('Should allow application when logged in', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      expect(AuthService.isLoggedIn, isTrue);
      
      final success = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Objectbeveiliging Kantoorcomplex',
        companyName: 'Amsterdam Security Partners',
        isAvailable: true,
        motivationMessage: 'Ik heb 5 jaar ervaring in objectbeveiliging',
        contactPreference: 'email',
      );
      
      expect(success, isTrue);
      expect(await ApplicationService.getUserApplicationCount(), equals(1));
      expect(await ApplicationService.hasAppliedForJob('SJ001'), isTrue);
    });

    test('Should prevent duplicate applications', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      // First application
      final firstSuccess = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'First application',
        contactPreference: 'email',
      );
      
      expect(firstSuccess, isTrue);
      expect(await ApplicationService.getUserApplicationCount(), equals(1));
      
      // Second application (should fail)
      final secondSuccess = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Second application',
        contactPreference: 'phone',
      );
      
      expect(secondSuccess, isFalse);
      expect(await ApplicationService.getUserApplicationCount(), equals(1));
    });

    test('Should allow applications to different jobs', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      // First job application
      final firstSuccess = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Job 1',
        companyName: 'Company 1',
        isAvailable: true,
        motivationMessage: 'Motivation 1',
        contactPreference: 'email',
      );
      
      // Second job application
      final secondSuccess = await ApplicationService.submitApplication(
        jobId: 'SJ002',
        jobTitle: 'Job 2',
        companyName: 'Company 2',
        isAvailable: true,
        motivationMessage: 'Motivation 2',
        contactPreference: 'phone',
      );
      
      expect(firstSuccess, isTrue);
      expect(secondSuccess, isTrue);
      expect(await ApplicationService.getUserApplicationCount(), equals(2));
      expect(await ApplicationService.hasAppliedForJob('SJ001'), isTrue);
      expect(await ApplicationService.hasAppliedForJob('SJ002'), isTrue);
    });

    test('Should retrieve application data correctly', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Test motivation message',
        contactPreference: 'email',
      );
      
      final application = ApplicationService.getApplicationForJob('SJ001');
      
      expect(application, isNotNull);
      expect(application!.jobId, equals('SJ001'));
      expect(application.jobTitle, equals('Test Job'));
      expect(application.companyName, equals('Test Company'));
      expect(application.applicantName, equals('Jan de Beveiliger'));
      expect(application.applicantType, equals('guard'));
      expect(application.isAvailable, isTrue);
      expect(application.motivationMessage, equals('Test motivation message'));
      expect(application.contactPreference, equals('email'));
      expect(application.status, equals(ApplicationStatus.pending));
    });

    test('Should handle application withdrawal', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      // Submit application
      await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Test motivation',
        contactPreference: 'email',
      );
      
      expect(await ApplicationService.hasAppliedForJob('SJ001'), isTrue);
      
      // Withdraw application
      final withdrawSuccess = await ApplicationService.withdrawApplication('SJ001');
      expect(withdrawSuccess, isTrue);
      
      // Check status changed
      final application = ApplicationService.getApplicationForJob('SJ001');
      expect(application!.status, equals(ApplicationStatus.withdrawn));
    });

    test('Should filter applications by status', () async {
      // Login first
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      // Submit multiple applications
      await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Job 1',
        companyName: 'Company 1',
        isAvailable: true,
        motivationMessage: 'Motivation 1',
        contactPreference: 'email',
      );
      
      await ApplicationService.submitApplication(
        jobId: 'SJ002',
        jobTitle: 'Job 2',
        companyName: 'Company 2',
        isAvailable: true,
        motivationMessage: 'Motivation 2',
        contactPreference: 'phone',
      );
      
      // Withdraw one application
      await ApplicationService.withdrawApplication('SJ001');
      
      final pendingApplications = await ApplicationService.getApplicationsByStatus(ApplicationStatus.pending);
      final withdrawnApplications = await ApplicationService.getApplicationsByStatus(ApplicationStatus.withdrawn);

      expect(pendingApplications.length, equals(1));
      expect(withdrawnApplications.length, equals(1));
      expect(pendingApplications.first.jobId, equals('SJ002'));
      expect(withdrawnApplications.first.jobId, equals('SJ001'));
    });

    test('Should provide correct status display texts in Dutch', () {
      expect(ApplicationService.getStatusDisplayText(ApplicationStatus.pending), equals('In behandeling'));
      expect(ApplicationService.getStatusDisplayText(ApplicationStatus.accepted), equals('Geaccepteerd'));
      expect(ApplicationService.getStatusDisplayText(ApplicationStatus.rejected), equals('Afgewezen'));
      expect(ApplicationService.getStatusDisplayText(ApplicationStatus.withdrawn), equals('Ingetrokken'));
    });

    test('Should provide correct status colors', () {
      expect(ApplicationService.getStatusColor(ApplicationStatus.pending), equals('#FFA726'));
      expect(ApplicationService.getStatusColor(ApplicationStatus.accepted), equals('#66BB6A'));
      expect(ApplicationService.getStatusColor(ApplicationStatus.rejected), equals('#EF5350'));
      expect(ApplicationService.getStatusColor(ApplicationStatus.withdrawn), equals('#BDBDBD'));
    });

    test('Should handle different user types correctly', () async {
      // Test with company user
      await AuthService.login('company@securyflex.nl', 'company123');
      
      final success = await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Company application',
        contactPreference: 'email',
      );
      
      expect(success, isTrue);
      
      final application = ApplicationService.getApplicationForJob('SJ001');
      expect(application!.applicantName, equals('Amsterdam Security BV'));
      expect(application.applicantType, equals('company'));
    });

    test('Should simulate network delay', () async {
      await AuthService.login('guard@securyflex.nl', 'guard123');
      
      final stopwatch = Stopwatch()..start();
      await ApplicationService.submitApplication(
        jobId: 'SJ001',
        jobTitle: 'Test Job',
        companyName: 'Test Company',
        isAvailable: true,
        motivationMessage: 'Test',
        contactPreference: 'email',
      );
      stopwatch.stop();
      
      // Should take at least 1200ms due to simulated delay
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(1200));
    });

    test('Should handle empty job ID', () async {
      await AuthService.login('guard@securyflex.nl', 'guard123');

      expect(await ApplicationService.hasAppliedForJob(''), isFalse);
      expect(ApplicationService.getApplicationForJob(''), isNull);
    });
  });
}
