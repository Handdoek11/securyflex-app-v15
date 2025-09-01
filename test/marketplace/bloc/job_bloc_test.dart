import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:securyflex_app/marketplace/bloc/job_bloc.dart';
import 'package:securyflex_app/marketplace/bloc/job_event.dart';
import 'package:securyflex_app/marketplace/bloc/job_state.dart';
import 'package:securyflex_app/marketplace/repository/job_repository.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/auth/bloc/auth_bloc.dart';
import 'package:securyflex_app/auth/bloc/auth_state.dart';

// Mock classes
class MockJobRepository extends Mock implements JobRepository {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('JobBloc Tests', () {
    late JobBloc jobBloc;
    late MockJobRepository mockRepository;
    late MockAuthBloc mockAuthBloc;
    late List<SecurityJobData> mockJobs;

    setUp(() {
      mockRepository = MockJobRepository();
      mockAuthBloc = MockAuthBloc();
      
      // Create mock jobs
      mockJobs = [
        SecurityJobData(
          jobId: 'SJ001',
          jobTitle: 'Objectbeveiliging Amsterdam',
          companyName: 'Security Solutions BV',
          location: 'Amsterdam',
          hourlyRate: 25.0,
          distance: 5.2,
          jobType: 'Objectbeveiliging',
          requiredCertificates: ['Beveiligingsdiploma A'],
          description: 'Objectbeveiliging in Amsterdam centrum',
        ),
        SecurityJobData(
          jobId: 'SJ002',
          jobTitle: 'Evenementbeveiliging Rotterdam',
          companyName: 'Event Security NL',
          location: 'Rotterdam',
          hourlyRate: 30.0,
          distance: 15.5,
          jobType: 'Evenementbeveiliging',
          requiredCertificates: ['Beveiligingsdiploma B'],
          description: 'Evenementbeveiliging voor grote evenementen',
        ),
      ];
      
      // Setup default mock returns
      when(() => mockRepository.getJobs()).thenAnswer((_) async => mockJobs);
      when(() => mockRepository.getAppliedJobs(any())).thenAnswer((_) async => []);
      when(() => mockRepository.watchJobs()).thenAnswer((_) => Stream.value(mockJobs));
      when(() => mockRepository.filterJobs(
        searchQuery: any(named: 'searchQuery'),
        minHourlyRate: any(named: 'minHourlyRate'),
        maxHourlyRate: any(named: 'maxHourlyRate'),
        maxDistance: any(named: 'maxDistance'),
        jobType: any(named: 'jobType'),
        requiredCertificates: any(named: 'requiredCertificates'),
      )).thenAnswer((_) async => mockJobs);
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthUnauthenticated()));
      when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());
      
      jobBloc = JobBloc(repository: mockRepository, authBloc: mockAuthBloc);
    });

    JobBloc createAuthenticatedJobBloc() {
      when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(
        userId: 'test-user-id',
        userType: 'guard',
        userName: 'Test User',
        userEmail: 'test@example.com',
        userData: {},
      ));
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthAuthenticated(
        userId: 'test-user-id',
        userType: 'guard',
        userName: 'Test User',
        userEmail: 'test@example.com',
        userData: {},
      )));
      return JobBloc(repository: mockRepository, authBloc: mockAuthBloc);
    }

    tearDown(() {
      jobBloc.close();
    });

    test('initial state is JobInitial', () {
      expect(jobBloc.state, equals(const JobInitial()));
    });

    group('JobInitialize', () {
      blocTest<JobBloc, JobState>(
        'emits [JobLoading, JobLoaded] when initialization succeeds',
        build: () => jobBloc,
        act: (bloc) => bloc.add(const JobInitialize()),
        expect: () => [
          const JobLoading(loadingMessage: 'Opdrachten initialiseren...'),
          isA<JobLoaded>()
              .having((state) => state.allJobs.length, 'allJobs.length', 2)
              .having((state) => state.filteredJobs.length, 'filteredJobs.length', 2)
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', false),
        ],
      );

      blocTest<JobBloc, JobState>(
        'emits [JobLoading, JobError] when initialization fails',
        build: () {
          when(() => mockRepository.getJobs()).thenThrow(Exception('Network error'));
          return jobBloc;
        },
        act: (bloc) => bloc.add(const JobInitialize()),
        expect: () => [
          const JobLoading(loadingMessage: 'Opdrachten initialiseren...'),
          isA<JobError>(),
        ],
      );
    });

    group('LoadJobs', () {
      blocTest<JobBloc, JobState>(
        'emits [JobLoading, JobLoaded] when loading succeeds',
        build: () => jobBloc,
        act: (bloc) => bloc.add(const LoadJobs()),
        expect: () => [
          const JobLoading(loadingMessage: 'Opdrachten laden...'),
          isA<JobLoaded>()
              .having((state) => state.allJobs.length, 'allJobs.length', 2)
              .having((state) => state.filteredJobs.length, 'filteredJobs.length', 2),
        ],
      );
    });

    group('SearchJobs', () {
      blocTest<JobBloc, JobState>(
        'filters jobs correctly when searching',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const SearchJobs('Amsterdam')),
        wait: const Duration(milliseconds: 400), // Wait for debounce
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.filters.searchQuery, 'searchQuery', 'Amsterdam')
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', true),
        ],
      );

      blocTest<JobBloc, JobState>(
        'returns empty list when no jobs match search',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const SearchJobs('NonExistentJob')),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.filters.searchQuery, 'searchQuery', 'NonExistentJob')
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', true),
        ],
      );
    });

    group('FilterJobs', () {
      blocTest<JobBloc, JobState>(
        'applies hourly rate filter correctly',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const FilterJobs(
          hourlyRateRange: RangeValues(20, 28),
        )),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.filters.hourlyRateRange, 'hourlyRateRange', const RangeValues(20, 28))
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', true),
        ],
      );

      blocTest<JobBloc, JobState>(
        'applies job type filter correctly',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const FilterJobs(
          jobType: 'Objectbeveiliging',
        )),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.filters.jobType, 'jobType', 'Objectbeveiliging')
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', true),
        ],
      );
    });

    group('ApplyToJob', () {
      blocTest<JobBloc, JobState>(
        'emits JobApplicationSuccess when application succeeds',
        build: () {
          when(() => mockRepository.applyToJob(any(), any(), message: any(named: 'message')))
              .thenAnswer((_) async => true);
          return createAuthenticatedJobBloc();
        },
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const ApplyToJob(jobId: 'SJ001')),
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.appliedJobIds.contains('SJ001'), 'appliedJobIds contains SJ001', true),
          isA<JobApplicationSuccess>()
              .having((state) => state.jobId, 'jobId', 'SJ001')
              .having((state) => state.jobTitle, 'jobTitle', 'Objectbeveiliging Amsterdam'),
        ],
      );

      blocTest<JobBloc, JobState>(
        'emits JobError when user not authenticated',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const ApplyToJob(jobId: 'SJ001')),
        expect: () => [
          isA<JobError>()
              .having((state) => state.error.code, 'error.code', 'not_authenticated'),
        ],
      );

      blocTest<JobBloc, JobState>(
        'emits JobError when application fails',
        build: () {
          when(() => mockRepository.applyToJob(any(), any(), message: any(named: 'message')))
              .thenAnswer((_) async => false);
          return createAuthenticatedJobBloc();
        },
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ),
        act: (bloc) => bloc.add(const ApplyToJob(jobId: 'SJ001')),
        expect: () => [
          isA<JobError>()
              .having((state) => state.error.code, 'error.code', 'application_failed'),
        ],
      );
    });

    group('ClearFilters', () {
      blocTest<JobBloc, JobState>(
        'clears all filters and shows all jobs',
        build: () => jobBloc,
        seed: () => JobLoaded(
          allJobs: mockJobs,
          filteredJobs: [mockJobs.first], // Filtered list
          filters: const JobFilter(
            searchQuery: 'Amsterdam',
            hourlyRateRange: RangeValues(20, 30),
            jobType: 'Objectbeveiliging',
          ),
          appliedJobIds: const {},
          hasActiveFilters: true,
        ),
        act: (bloc) => bloc.add(const ClearFilters()),
        expect: () => [
          isA<JobLoaded>()
              .having((state) => state.filteredJobs.length, 'filteredJobs.length', 2)
              .having((state) => state.filters, 'filters', const JobFilter())
              .having((state) => state.hasActiveFilters, 'hasActiveFilters', false),
        ],
      );
    });

    group('LoadJobMetadata', () {
      blocTest<JobBloc, JobState>(
        'emits JobMetadataLoaded when metadata loading succeeds',
        build: () {
          when(() => mockRepository.getJobTypes()).thenAnswer((_) async => ['Objectbeveiliging', 'Evenementbeveiliging']);
          when(() => mockRepository.getAvailableCertificates()).thenAnswer((_) async => ['Beveiligingsdiploma A', 'Beveiligingsdiploma B']);
          when(() => mockRepository.getCompanies()).thenAnswer((_) async => ['Security Solutions BV', 'Event Security NL']);
          when(() => mockRepository.getLocations()).thenAnswer((_) async => ['Amsterdam', 'Rotterdam']);
          return jobBloc;
        },
        act: (bloc) => bloc.add(const LoadJobMetadata()),
        expect: () => [
          isA<JobMetadataLoaded>()
              .having((state) => state.jobTypes.length, 'jobTypes.length', 2)
              .having((state) => state.certificates.length, 'certificates.length', 2)
              .having((state) => state.companies.length, 'companies.length', 2)
              .having((state) => state.locations.length, 'locations.length', 2),
        ],
      );
    });

    group('LoadJobStatistics', () {
      blocTest<JobBloc, JobState>(
        'emits JobStatisticsLoaded when statistics loading succeeds',
        build: () {
          when(() => mockRepository.getJobStatistics()).thenAnswer((_) async => {
            'totalJobs': 2,
            'averageHourlyRate': 27.5,
            'jobTypesCount': 2,
            'companiesCount': 2,
          });
          return jobBloc;
        },
        act: (bloc) => bloc.add(const LoadJobStatistics()),
        expect: () => [
          isA<JobStatisticsLoaded>()
              .having((state) => state.statistics['totalJobs'], 'totalJobs', 2)
              .having((state) => state.statistics['averageHourlyRate'], 'averageHourlyRate', 27.5),
        ],
      );
    });

    group('Convenience Getters', () {
      test('isLoaded returns true when state is JobLoaded', () {
        jobBloc.emit(JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ));
        
        expect(jobBloc.isLoaded, isTrue);
      });

      test('isLoading returns true when state is JobLoading', () {
        jobBloc.emit(const JobLoading());
        expect(jobBloc.isLoading, isTrue);
      });

      test('allJobs returns correct jobs when loaded', () {
        jobBloc.emit(JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ));
        
        expect(jobBloc.allJobs, equals(mockJobs));
      });

      test('filteredJobs returns correct filtered jobs', () {
        final filteredJobs = [mockJobs.first];
        jobBloc.emit(JobLoaded(
          allJobs: mockJobs,
          filteredJobs: filteredJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        ));
        
        expect(jobBloc.filteredJobs, equals(filteredJobs));
      });
    });

    group('Dutch Localization', () {
      test('JobLoaded provides correct Dutch status messages', () {
        // No jobs, no filters
        const emptyState = JobLoaded(
          allJobs: [],
          filteredJobs: [],
          filters: JobFilter(),
          appliedJobIds: {},
          hasActiveFilters: false,
        );
        expect(emptyState.statusMessage, equals('Geen opdrachten beschikbaar'));

        // No jobs with filters
        const emptyFilteredState = JobLoaded(
          allJobs: [],
          filteredJobs: [],
          filters: JobFilter(searchQuery: 'test'),
          appliedJobIds: {},
          hasActiveFilters: true,
        );
        expect(emptyFilteredState.statusMessage, equals('Geen opdrachten gevonden met huidige filters'));

        // Jobs with filters
        final filteredState = JobLoaded(
          allJobs: mockJobs,
          filteredJobs: [mockJobs.first],
          filters: const JobFilter(searchQuery: 'Amsterdam'),
          appliedJobIds: const {},
          hasActiveFilters: true,
        );
        expect(filteredState.statusMessage, equals('1 van 2 opdrachten'));

        // All jobs, no filters
        final allJobsState = JobLoaded(
          allJobs: mockJobs,
          filteredJobs: mockJobs,
          filters: const JobFilter(),
          appliedJobIds: const {},
          hasActiveFilters: false,
        );
        expect(allJobsState.statusMessage, equals('2 opdrachten beschikbaar'));
      });

      test('JobApplicationSuccess provides Dutch success message', () {
        const successState = JobApplicationSuccess(
          jobId: 'SJ001',
          jobTitle: 'Test Job',
        );
        
        expect(successState.localizedSuccessMessage, equals('Sollicitatie voor "Test Job" succesvol verzonden!'));
      });

      test('JobApplicationRemoved provides Dutch success message', () {
        const removedState = JobApplicationRemoved(
          jobId: 'SJ001',
          jobTitle: 'Test Job',
        );
        
        expect(removedState.localizedSuccessMessage, equals('Sollicitatie voor "Test Job" succesvol ingetrokken'));
      });
    });
  });
}
