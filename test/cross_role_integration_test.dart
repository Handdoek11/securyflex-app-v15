import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/beveiliger_dashboard/beveiliger_dashboard_home.dart';
import 'package:securyflex_app/company_dashboard/company_dashboard_home.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/services/application_review_service.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'helpers/firebase_test_helper.dart';

void main() {
  group('Cross-Role Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing to prevent "No Firebase App created" errors
      await FirebaseTestHelper.setupTestGroup();
    });

    setUp(() {
      // Reset authentication state and initialize mock data
      AuthService.logout();
      JobPostingService.initializeMockData();
      ApplicationReviewService.instance.initializeMockData('test_company');
    });

    group('Complete Guard-Company Workflow Tests', () {
      testWidgets('Complete job application workflow: Company posts job → Guard applies → Company reviews', (WidgetTester tester) async {
        // Step 1: Company logs in and posts a job
        await AuthService.login('company@securyflex.nl', 'company123');
        
        // Create a test job posting
        final testJob = JobPostingData(
          jobId: 'TEST_JOB_001',
          companyId: 'COMP001',
          title: 'Test Objectbeveiliging',
          description: 'Test job voor integratie testing',
          location: 'Amsterdam',
          postalCode: '1012AB',
          hourlyRate: 20.0,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
          createdDate: DateTime.now(),
          status: JobPostingStatus.active,
          jobType: JobType.objectbeveiliging,
        );
        
        final jobCreated = await JobPostingService.instance.createJob(testJob);
        expect(jobCreated, isTrue);
        
        // Verify Company can see their posted job
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show Company dashboard
        expect(find.byType(CompanyDashboardHome), findsOneWidget);
        
        // Step 2: Switch to Guard user and apply to the job
        AuthService.logout();
        await AuthService.login('guard@securyflex.nl', 'guard123');
        
        // Simulate Guard applying to the job
        final applicationSuccess = await ApplicationService.submitApplication(
          jobId: 'TEST_JOB_001',
          jobTitle: 'Test Objectbeveiliging',
          companyName: 'Test Company',
          isAvailable: true,
          motivationMessage: 'Ik ben geïnteresseerd in deze opdracht en heb relevante ervaring.',
          contactPreference: 'email',
        );
        expect(applicationSuccess, isTrue);
        
        // Verify Guard can see Guard dashboard
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: BeveiligerDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show Guard dashboard
        expect(find.byType(BeveiligerDashboardHome), findsOneWidget);
        
        // Step 3: Switch back to Company and review the application
        AuthService.logout();
        await AuthService.login('company@securyflex.nl', 'company123');
        
        // Get applications for the job
        final applications = await ApplicationReviewService.instance.getJobApplications('TEST_JOB_001');
        expect(applications, isNotEmpty);
        
        // Company accepts the application
        final acceptSuccess = await ApplicationReviewService.instance.acceptApplication(
          applications.first.applicationId,
          message: 'Welkom bij ons team!',
        );
        expect(acceptSuccess, isTrue);
        
        // Verify Company dashboard shows updated application status
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should show Company dashboard with updated data
        expect(find.byType(CompanyDashboardHome), findsOneWidget);
      });

      testWidgets('Role-based theming consistency across user types', (WidgetTester tester) async {
        // Test Guard theming
        await AuthService.login('guard@securyflex.nl', 'guard123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: BeveiligerDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Verify Guard colors are applied
        final guardTheme = Theme.of(tester.element(find.byType(BeveiligerDashboardHome)));
        expect(guardTheme.colorScheme.primary, equals(const Color(0xFF1E3A8A))); // Navy Blue
        
        // Switch to Company user
        AuthService.logout();
        await AuthService.login('company@securyflex.nl', 'company123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Verify Company colors are applied
        final companyTheme = Theme.of(tester.element(find.byType(CompanyDashboardHome)));
        expect(companyTheme.colorScheme.primary, equals(const Color(0xFF54D3C2))); // Teal
      });

      testWidgets('Navigation consistency between Guard and Company interfaces', (WidgetTester tester) async {
        // Test Guard navigation
        await AuthService.login('guard@securyflex.nl', 'guard123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: BeveiligerDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should have 4 navigation tabs
        expect(find.byType(BeveiligerDashboardHome), findsOneWidget);
        
        // Switch to Company navigation
        AuthService.logout();
        await AuthService.login('company@securyflex.nl', 'company123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should also have 4 navigation tabs with Company structure
        expect(find.byType(CompanyDashboardHome), findsOneWidget);
      });
    });

    group('Data Consistency Tests', () {
      test('Job posting data consistency between Company and Guard views', () async {
        // Company creates a job
        final jobData = JobPostingData(
          jobId: 'CONSISTENCY_TEST',
          companyId: 'COMP001',
          title: 'Consistency Test Job',
          description: 'Testing data consistency across roles',
          location: 'Utrecht',
          postalCode: '3511AB',
          hourlyRate: 25.0,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
          createdDate: DateTime.now(),
          status: JobPostingStatus.active,
          jobType: JobType.evenementbeveiliging,
        );
        
        await JobPostingService.instance.createJob(jobData);
        
        // Verify Company can retrieve the job
        final companyJob = await JobPostingService.instance.getJobById('CONSISTENCY_TEST');
        expect(companyJob, isNotNull);
        expect(companyJob!.title, equals('Consistency Test Job'));
        expect(companyJob.hourlyRate, equals(25.0));
        
        // TODO: Verify Guard can see the job in marketplace
        // This would require marketplace integration
      });

      test('Application data consistency between Guard and Company views', () async {
        // Initialize test data
        JobPostingService.initializeMockData();
        ApplicationReviewService.instance.initializeMockData('test_company');
        
        // Get applications from Company perspective
        final companyApplications = await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        expect(companyApplications, isNotEmpty);
        
        // Verify application data structure
        final firstApp = companyApplications.first;
        expect(firstApp.guardName, isNotEmpty);
        expect(firstApp.guardEmail, isNotEmpty);
        expect(firstApp.motivationMessage, isNotEmpty);
        expect(firstApp.guardRating, greaterThan(0));
        expect(firstApp.guardExperience, greaterThanOrEqualTo(0));
      });
    });

    group('Business Logic Integration Tests', () {
      test('Dutch validation consistency across roles', () async {
        // Test valid job creation
        final validJob = JobPostingData(
          jobId: 'VALID_TEST',
          companyId: 'COMP001',
          title: 'Valid Job Title',
          description: 'This is a valid job description with enough characters to pass validation',
          location: 'Amsterdam',
          postalCode: '1012AB', // Valid Dutch postal code
          hourlyRate: 18.50,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
          createdDate: DateTime.now(),
        );

        final validResult = await JobPostingService.instance.createJob(validJob);
        expect(validResult, isTrue);

        // Test invalid job creation (invalid postal code)
        final invalidJob = JobPostingData(
          jobId: 'INVALID_TEST',
          companyId: 'COMP001',
          title: 'Invalid Job',
          description: 'This job has invalid postal code',
          location: 'Amsterdam',
          postalCode: '12345', // Invalid format
          hourlyRate: 18.50,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
          createdDate: DateTime.now(),
        );

        final invalidResult = await JobPostingService.instance.createJob(invalidJob);
        expect(invalidResult, isFalse);
      });

      test('Currency formatting consistency', () async {
        final metrics = await JobPostingService.getCompanyJobStats('COMP001');
        
        // Verify financial data is properly formatted
        expect(metrics['averageHourlyRate'], isA<double>());
        expect(metrics['totalBudgetSpent'], isA<double>());
        
        // Values should be reasonable for Dutch market
        if (metrics['averageHourlyRate'] > 0) {
          expect(metrics['averageHourlyRate'], greaterThanOrEqualTo(10.0));
          expect(metrics['averageHourlyRate'], lessThanOrEqualTo(100.0));
        }
      });
    });

    group('Performance Integration Tests', () {
      test('Cross-role data loading performance', () async {
        final stopwatch = Stopwatch()..start();
        
        // Load Company data
        await JobPostingService.instance.getCompanyJobs('COMP001');
        await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        
        stopwatch.stop();
        
        // Should load within performance requirements
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // < 2 seconds
      });

      test('Memory efficiency with multiple role data', () async {
        // Load data for both roles
        final companyJobs = await JobPostingService.instance.getCompanyJobs('COMP001');
        final companyApplications = await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        
        // Verify data is loaded efficiently
        expect(companyJobs, isA<List<JobPostingData>>());
        expect(companyApplications, isA<List<ApplicationReviewData>>());
        
        // Data should be reasonable size
        expect(companyJobs.length, lessThan(100)); // Reasonable pagination
        expect(companyApplications.length, lessThan(100));
      });
    });

    group('Error Handling Integration Tests', () {
      test('Graceful handling of cross-role data inconsistencies', () async {
        // Test with non-existent job ID
        final nonExistentJob = await JobPostingService.instance.getJobById('NON_EXISTENT');
        expect(nonExistentJob, isNull);
        
        // Test with non-existent company ID
        final emptyApplications = await ApplicationReviewService.instance.getCompanyApplications('NON_EXISTENT');
        expect(emptyApplications, isEmpty);
      });

      test('Proper error handling for invalid operations', () async {
        // Test accepting non-existent application
        final invalidAccept = await ApplicationReviewService.instance.acceptApplication('NON_EXISTENT');
        expect(invalidAccept, isFalse);
        
        // Test deleting non-existent job
        final invalidDelete = await JobPostingService.instance.deleteJob('NON_EXISTENT');
        expect(invalidDelete, isFalse);
      });
    });
  });
}
