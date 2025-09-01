import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/models/company_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/company_service.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/services/application_review_service.dart';
import 'helpers/firebase_test_helper.dart';

void main() {
  group('Company Services Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing to prevent "No Firebase App created" errors
      await FirebaseTestHelper.setupTestGroup();
    });

    setUp(() {
      // Initialize mock data for each test
      JobPostingService.initializeMockData();
      ApplicationReviewService.instance.initializeMockData('test_company');
    });

    group('CompanyService Tests', () {
      test('Should get current company profile', () async {
        final company = await CompanyService.instance.getCurrentCompany();
        
        expect(company.companyName, equals('Amsterdam Security Partners'));
        expect(company.kvkNumber, equals('12345678'));
        expect(company.postalCode, equals('1012AB'));
        expect(company.status, equals(CompanyStatus.active));
        expect(company.isVerified, isTrue);
      });

      test('Should update company profile', () async {
        final originalCompany = await CompanyService.instance.getCurrentCompany();
        final updatedCompany = originalCompany.copyWith(
          companyName: 'Updated Security BV',
          phoneNumber: '+31 30 9876543',
        );
        
        final success = await CompanyService.instance.updateCompany(updatedCompany);
        expect(success, isTrue);
        
        final retrievedCompany = await CompanyService.instance.getCurrentCompany();
        expect(retrievedCompany.companyName, equals('Updated Security BV'));
        expect(retrievedCompany.phoneNumber, equals('+31 30 9876543'));
      });

      test('Should validate KvK numbers correctly', () {
        expect(CompanyService.isValidKvK('12345678'), isTrue);
        expect(CompanyService.isValidKvK('1234567'), isFalse); // Too short
        expect(CompanyService.isValidKvK('123456789'), isFalse); // Too long
        expect(CompanyService.isValidKvK('1234567a'), isFalse); // Contains letter
        expect(CompanyService.isValidKvK('12 34 56 78'), isTrue); // With spaces
      });

      test('Should validate Dutch postal codes correctly', () {
        expect(CompanyService.isValidPostalCode('1012AB'), isTrue);
        expect(CompanyService.isValidPostalCode('1012ab'), isTrue); // Case insensitive
        expect(CompanyService.isValidPostalCode('101AB'), isFalse); // Too short
        expect(CompanyService.isValidPostalCode('10123AB'), isFalse); // Too long
        expect(CompanyService.isValidPostalCode('1012A1'), isFalse); // Number in letters
      });

      test('Should validate Dutch phone numbers correctly', () {
        expect(CompanyService.isValidDutchPhone('+31612345678'), isTrue);
        expect(CompanyService.isValidDutchPhone('0612345678'), isTrue);
        expect(CompanyService.isValidDutchPhone('+31 6 12345678'), isTrue); // With spaces
        expect(CompanyService.isValidDutchPhone('06-1234-5678'), isTrue); // With dashes
        expect(CompanyService.isValidDutchPhone('1234567890'), isFalse); // No prefix
        expect(CompanyService.isValidDutchPhone('+31012345678'), isFalse); // Invalid area code
      });

      test('Should get company metrics', () async {
        final metrics = await CompanyService.instance.getCompanyMetrics();
        
        expect(metrics['activeJobs'], isA<int>());
        expect(metrics['pendingApplications'], isA<int>());
        expect(metrics['totalGuardsHired'], isA<int>());
        expect(metrics['monthlySpent'], isA<double>());
        expect(metrics['companyRating'], isA<double>());
      });
    });

    group('JobPostingService Tests', () {
      test('Should create new job posting', () async {
        final jobData = JobPostingData(
          jobId: 'TEST001',
          companyId: 'COMP001',
          title: 'Test Security Job',
          description: 'Test job description for security services in Amsterdam.',
          location: 'Amsterdam',
          postalCode: '1012AB',
          hourlyRate: 20.0,
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
          createdDate: DateTime.now(),
        );
        
        final success = await JobPostingService.instance.createJob(jobData);
        expect(success, isTrue);
        
        final retrievedJob = await JobPostingService.instance.getJobById('TEST001');
        expect(retrievedJob?.title, equals('Test Security Job'));
      });

      test('Should get company jobs', () async {
        final jobs = await JobPostingService.instance.getCompanyJobs('COMP001');
        expect(jobs, isNotEmpty);
        expect(jobs.every((job) => job.companyId == 'COMP001'), isTrue);
      });

      test('Should update job status', () async {
        final success = await JobPostingService.instance.updateJobStatus('JOB001', JobPostingStatus.filled);
        expect(success, isTrue);
        
        final job = await JobPostingService.instance.getJobById('JOB001');
        expect(job?.status, equals(JobPostingStatus.filled));
      });

      test('Should get job analytics', () async {
        final analytics = await JobPostingService.instance.getJobAnalytics('JOB001');
        
        expect(analytics['totalViews'], isA<int>());
        expect(analytics['applicationsCount'], isA<int>());
        expect(analytics['averageResponseTime'], isA<double>());
        expect(analytics['fillRate'], isA<double>());
      });

      test('Should get company job statistics', () async {
        final stats = await JobPostingService.getCompanyJobStats('COMP001');
        
        expect(stats['totalJobsPosted'], isA<int>());
        expect(stats['activeJobs'], isA<int>());
        expect(stats['averageHourlyRate'], isA<double>());
        expect(stats['totalApplications'], isA<int>());
      });
    });

    group('ApplicationReviewService Tests', () {
      test('Should get company applications', () async {
        final applications = await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        expect(applications, isNotEmpty);
        expect(applications.every((app) => app.guardName.isNotEmpty), isTrue);
      });

      test('Should get pending applications', () async {
        final pending = await ApplicationReviewService.instance.getPendingApplications('COMP001');
        expect(pending.every((app) => app.status == ApplicationReviewStatus.pending), isTrue);
      });

      test('Should accept application', () async {
        final applications = await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        if (applications.isNotEmpty) {
          final appId = applications.first.applicationId;
          final success = await ApplicationReviewService.instance.acceptApplication(
            appId, 
            message: 'Welkom bij ons team!',
          );
          expect(success, isTrue);
        }
      });

      test('Should reject application', () async {
        final applications = await ApplicationReviewService.instance.getCompanyApplications('COMP001');
        if (applications.length > 1) {
          final appId = applications[1].applicationId;
          final success = await ApplicationReviewService.instance.rejectApplication(
            appId,
            reason: 'Onvoldoende ervaring voor deze opdracht.',
          );
          expect(success, isTrue);
        }
      });

      test('Should get application statistics', () async {
        final stats = await ApplicationReviewService.instance.getApplicationStats('COMP001');
        
        expect(stats['totalApplications'], isA<int>());
        expect(stats['pendingReview'], isA<int>());
        expect(stats['acceptanceRate'], isA<double>());
        expect(stats['averageGuardRating'], isA<double>());
      });
    });

    group('Data Model Tests', () {
      test('JobPostingData should calculate total budget correctly', () {
        final job = JobPostingData(
          jobId: 'TEST001',
          companyId: 'COMP001',
          title: 'Test Job',
          description: 'Test description',
          location: 'Amsterdam',
          postalCode: '1012AB',
          hourlyRate: 20.0,
          startDate: DateTime(2024, 1, 1, 9, 0),
          endDate: DateTime(2024, 1, 1, 17, 0), // 8 hours
          createdDate: DateTime.now(),
        );
        
        expect(job.totalBudget, equals(160.0)); // 8 hours * 20.0 rate
        expect(job.durationInHours, equals(8));
      });

      test('JobPostingData should check if job is active', () {
        final activeJob = JobPostingData(
          jobId: 'TEST001',
          companyId: 'COMP001',
          title: 'Active Job',
          description: 'Test description',
          location: 'Amsterdam',
          postalCode: '1012AB',
          hourlyRate: 20.0,
          startDate: DateTime.now().subtract(const Duration(hours: 1)),
          endDate: DateTime.now().add(const Duration(hours: 1)),
          status: JobPostingStatus.active,
          createdDate: DateTime.now(),
        );
        
        expect(activeJob.isActive, isTrue);
        
        final inactiveJob = activeJob.copyWith(status: JobPostingStatus.draft);
        expect(inactiveJob.isActive, isFalse);
      });

      test('Should have proper Dutch status display names', () {
        expect(JobPostingStatus.draft.displayName, equals('Concept'));
        expect(JobPostingStatus.active.displayName, equals('Actief'));
        expect(JobPostingStatus.filled.displayName, equals('Vervuld'));
        expect(JobPostingStatus.cancelled.displayName, equals('Geannuleerd'));
        expect(JobPostingStatus.completed.displayName, equals('Voltooid'));
        expect(JobPostingStatus.expired.displayName, equals('Verlopen'));
        
        expect(ApplicationReviewStatus.pending.displayName, equals('In behandeling'));
        expect(ApplicationReviewStatus.accepted.displayName, equals('Geaccepteerd'));
        expect(ApplicationReviewStatus.rejected.displayName, equals('Afgewezen'));
        expect(ApplicationReviewStatus.withdrawn.displayName, equals('Ingetrokken'));
      });
    });
  });
}
