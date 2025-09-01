import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:securyflex_app/reputation/bloc/reputation_bloc.dart';
import 'package:securyflex_app/reputation/models/reputation_data.dart';
import 'package:securyflex_app/reputation/services/reputation_calculation_service.dart';

import 'reputation_bloc_test.mocks.dart';

@GenerateMocks([ReputationCalculationService])
void main() {
  group('ReputationBloc Tests', () {
    late ReputationBloc bloc;
    late MockReputationCalculationService mockService;

    setUp(() {
      mockService = MockReputationCalculationService();
      bloc = ReputationBloc(reputationService: mockService);
    });

    tearDown(() {
      bloc.close();
    });

    group('LoadReputation', () {
      const testUserId = 'test-user-123';
      const testUserRole = 'guard';

      final testReputationData = ReputationData(
        userId: testUserId,
        userRole: testUserRole,
        lastCalculated: DateTime.now(),
        firstJobDate: DateTime.now().subtract(const Duration(days: 365)),
        overallScore: 85.0,
        jobCompletionRating: 4.2,
        reliabilityScore: 90.0,
        clientFeedbackScore: 88.0,
        complianceScore: 75.0,
        experienceMultiplier: 1.2,
        totalJobsCompleted: 25,
        totalJobsCancelled: 1,
        noShowCount: 0,
        lateArrivalCount: 2,
        earlyCompletionCount: 3,
        averageResponseTime: 12.5,
        positiveReviewCount: 20,
        neutralReviewCount: 4,
        negativeReviewCount: 1,
        repeatClientPercentage: 60.0,
        recommendationRate: 80.0,
        wpbrCertified: true,
        kvkVerified: false,
        activeCertificateCount: 2,
        complianceViolationCount: 0,
        monthlyScoreChange: 2.5,
        quarterlyScoreChange: 8.0,
        currentTrend: ReputationTrend.improving,
        achievedMilestones: [
          ReputationMilestone.firstJob,
          ReputationMilestone.tenJobsCompleted,
          ReputationMilestone.firstGoodReview,
        ],
        specializationScores: {'eventSecurity': 4.5, 'retailSecurity': 4.2},
        topSpecialization: 'eventSecurity',
        averageHourlyRate: 16.50,
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits [ReputationLoading, ReputationLoaded] when LoadReputation succeeds',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: true))
              .thenAnswer((_) async => testReputationData);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationLoading(),
          ReputationLoaded(testReputationData),
        ],
        verify: (_) {
          verify(mockService.getReputation(testUserId, testUserRole, useCache: true)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits [ReputationLoading, ReputationError] when LoadReputation fails',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: true))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationLoading(),
          isA<ReputationError>(),
        ],
        verify: (_) {
          verify(mockService.getReputation(testUserId, testUserRole, useCache: true)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'passes useCache parameter correctly to service',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: false))
              .thenAnswer((_) async => testReputationData);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadReputation(testUserId, testUserRole, useCache: false)),
        expect: () => [
          ReputationLoading(),
          ReputationLoaded(testReputationData),
        ],
        verify: (_) {
          verify(mockService.getReputation(testUserId, testUserRole, useCache: false)).called(1);
        },
      );
    });

    group('RecalculateReputation', () {
      const testUserId = 'test-user-123';
      const testUserRole = 'guard';

      final recalculatedData = ReputationData.initial(
        userId: testUserId,
        userRole: testUserRole,
      ).copyWith(overallScore: 75.0, totalJobsCompleted: 15);

      blocTest<ReputationBloc, ReputationState>(
        'emits [ReputationCalculating, ReputationLoaded] when recalculation succeeds',
        build: () {
          when(mockService.calculateReputation(testUserId, testUserRole))
              .thenAnswer((_) async => recalculatedData);
          return bloc;
        },
        act: (bloc) => bloc.add(RecalculateReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationCalculating(),
          ReputationLoaded(recalculatedData),
        ],
        verify: (_) {
          verify(mockService.calculateReputation(testUserId, testUserRole)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits [ReputationCalculating, ReputationError] when recalculation fails',
        build: () {
          when(mockService.calculateReputation(testUserId, testUserRole))
              .thenThrow(Exception('Calculation failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(RecalculateReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationCalculating(),
          isA<ReputationError>(),
        ],
        verify: (_) {
          verify(mockService.calculateReputation(testUserId, testUserRole)).called(1);
        },
      );
    });

    group('UpdateReputationAfterJob', () {
      const testUserId = 'test-user-123';
      const testUserRole = 'guard';
      const testWorkflowId = 'workflow-456';

      final updatedReputationData = ReputationData.initial(
        userId: testUserId,
        userRole: testUserRole,
      ).copyWith(
        overallScore: 87.5,
        totalJobsCompleted: 26,
        monthlyScoreChange: 2.5,
      );

      blocTest<ReputationBloc, ReputationState>(
        'successfully updates reputation after job completion',
        build: () {
          when(mockService.updateReputationAfterJob(
            userId: testUserId,
            userRole: testUserRole,
            workflowId: testWorkflowId,
            jobCompleted: true,
            newRating: 4.5,
          )).thenAnswer((_) async {});

          when(mockService.getReputation(testUserId, testUserRole, useCache: false))
              .thenAnswer((_) async => updatedReputationData);
          
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateReputationAfterJob(
          userId: testUserId,
          userRole: testUserRole,
          workflowId: testWorkflowId,
          jobCompleted: true,
          newRating: 4.5,
        )),
        expect: () => [
          ReputationLoaded(updatedReputationData),
        ],
        verify: (_) {
          verify(mockService.updateReputationAfterJob(
            userId: testUserId,
            userRole: testUserRole,
            workflowId: testWorkflowId,
            jobCompleted: true,
            newRating: 4.5,
          )).called(1);
          verify(mockService.getReputation(testUserId, testUserRole, useCache: false)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits ReputationUpdateError when update fails',
        build: () {
          when(mockService.updateReputationAfterJob(
            userId: testUserId,
            userRole: testUserRole,
            workflowId: testWorkflowId,
            jobCompleted: false,
          )).thenThrow(Exception('Update failed'));
          
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateReputationAfterJob(
          userId: testUserId,
          userRole: testUserRole,
          workflowId: testWorkflowId,
          jobCompleted: false,
        )),
        expect: () => [
          isA<ReputationUpdateError>(),
        ],
        verify: (_) {
          verify(mockService.updateReputationAfterJob(
            userId: testUserId,
            userRole: testUserRole,
            workflowId: testWorkflowId,
            jobCompleted: false,
          )).called(1);
        },
      );
    });

    group('RefreshReputation', () {
      const testUserId = 'test-user-123';
      const testUserRole = 'guard';

      final currentData = ReputationData.initial(
        userId: testUserId,
        userRole: testUserRole,
      ).copyWith(overallScore: 80.0);

      final refreshedData = currentData.copyWith(
        overallScore: 82.0,
        monthlyScoreChange: 2.0,
      );

      blocTest<ReputationBloc, ReputationState>(
        'shows refreshing state with current data when already loaded',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: false))
              .thenAnswer((_) async => refreshedData);
          return bloc;
        },
        seed: () => ReputationLoaded(currentData),
        act: (bloc) {
          bloc.add(RefreshReputation(testUserId, testUserRole));
        },
        expect: () => [
          ReputationRefreshing(currentData),
          ReputationLoaded(refreshedData),
        ],
        verify: (_) {
          verify(mockService.invalidateCache()).called(1);
          verify(mockService.getReputation(testUserId, testUserRole, useCache: false)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'shows loading state when no current data available',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: false))
              .thenAnswer((_) async => refreshedData);
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationLoading(),
          ReputationLoaded(refreshedData),
        ],
        verify: (_) {
          verify(mockService.invalidateCache()).called(1);
          verify(mockService.getReputation(testUserId, testUserRole, useCache: false)).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits error when refresh fails',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: false))
              .thenThrow(Exception('Refresh failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(RefreshReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationLoading(),
          isA<ReputationError>(),
        ],
        verify: (_) {
          verify(mockService.invalidateCache()).called(1);
          verify(mockService.getReputation(testUserId, testUserRole, useCache: false)).called(1);
        },
      );
    });

    group('ClearReputationCache', () {
      final currentData = ReputationData.initial(
        userId: 'test-user',
        userRole: 'guard',
      );

      blocTest<ReputationBloc, ReputationState>(
        'clears cache and preserves current data when loaded',
        build: () => bloc,
        seed: () => ReputationLoaded(currentData),
        act: (bloc) => bloc.add(ClearReputationCache()),
        expect: () => [
          ReputationCacheCleared(currentData),
        ],
        verify: (_) {
          verify(mockService.invalidateCache()).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'clears cache with null data when not loaded',
        build: () => bloc,
        act: (bloc) => bloc.add(ClearReputationCache()),
        expect: () => [
          ReputationCacheCleared(null),
        ],
        verify: (_) {
          verify(mockService.invalidateCache()).called(1);
        },
      );

      blocTest<ReputationBloc, ReputationState>(
        'emits error when cache clearing fails',
        build: () {
          when(mockService.invalidateCache()).thenThrow(Exception('Cache clear failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(ClearReputationCache()),
        expect: () => [
          isA<ReputationError>(),
        ],
      );
    });

    group('State Equality', () {
      final reputationData = ReputationData.initial(
        userId: 'test-user',
        userRole: 'guard',
      ).copyWith(overallScore: 75.0);

      test('ReputationLoaded states with same data are equal', () {
        final state1 = ReputationLoaded(reputationData);
        final state2 = ReputationLoaded(reputationData);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('ReputationError states with same error are equal', () {
        const error = 'Test error message';
        final state1 = ReputationError(error);
        final state2 = ReputationError(error);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('ReputationUpdateError states with same error are equal', () {
        const error = 'Update error message';
        final state1 = ReputationUpdateError(error);
        final state2 = ReputationUpdateError(error);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });
    });

    group('Event String Representations', () {
      test('LoadReputation toString includes parameters', () {
        final event = LoadReputation('user-123', 'guard', useCache: false);
        expect(event.toString(), contains('user-123'));
        expect(event.toString(), contains('guard'));
        expect(event.toString(), contains('useCache: false'));
      });

      test('RecalculateReputation toString includes parameters', () {
        final event = RecalculateReputation('user-123', 'company');
        expect(event.toString(), contains('user-123'));
        expect(event.toString(), contains('company'));
      });

      test('UpdateReputationAfterJob toString includes parameters', () {
        final event = UpdateReputationAfterJob(
          userId: 'user-123',
          userRole: 'guard',
          workflowId: 'workflow-456',
          jobCompleted: true,
          newRating: 4.5,
        );
        expect(event.toString(), contains('user-123'));
        expect(event.toString(), contains('workflow-456'));
        expect(event.toString(), contains('completed: true'));
      });

      test('RefreshReputation toString includes parameters', () {
        final event = RefreshReputation('user-123', 'guard');
        expect(event.toString(), contains('user-123'));
        expect(event.toString(), contains('guard'));
      });
    });

    group('State String Representations', () {
      test('ReputationLoaded toString includes score', () {
        final reputationData = ReputationData.initial(
          userId: 'test-user',
          userRole: 'guard',
        ).copyWith(overallScore: 85.5);
        
        final state = ReputationLoaded(reputationData);
        expect(state.toString(), contains('86/100')); // Rounded score
      });

      test('ReputationRefreshing toString includes current score', () {
        final reputationData = ReputationData.initial(
          userId: 'test-user',
          userRole: 'guard',
        ).copyWith(overallScore: 75.0);
        
        final state = ReputationRefreshing(reputationData);
        expect(state.toString(), contains('currentScore: 75'));
      });

      test('ReputationError toString includes error message', () {
        const errorMessage = 'Network connection failed';
        final state = ReputationError(errorMessage);
        expect(state.toString(), contains(errorMessage));
      });
    });

    group('Dutch Business Logic Integration', () {
      const testUserId = 'dutch-guard-123';
      const testUserRole = 'guard';

      final dutchGuardData = ReputationData(
        userId: testUserId,
        userRole: testUserRole,
        lastCalculated: DateTime.now(),
        firstJobDate: DateTime.now().subtract(const Duration(days: 730)), // 2 years experience
        overallScore: 88.0,
        jobCompletionRating: 4.4,
        reliabilityScore: 95.0,
        clientFeedbackScore: 90.0,
        complianceScore: 85.0,
        experienceMultiplier: 1.3,
        totalJobsCompleted: 120,
        totalJobsCancelled: 2,
        noShowCount: 1, // Within CAO limits
        lateArrivalCount: 3,
        earlyCompletionCount: 15,
        averageResponseTime: 8.5,
        positiveReviewCount: 95,
        neutralReviewCount: 20,
        negativeReviewCount: 5,
        repeatClientPercentage: 65.0,
        recommendationRate: 79.2,
        wpbrCertified: true, // Required for guards in Netherlands
        kvkVerified: false,
        activeCertificateCount: 3,
        complianceViolationCount: 0,
        monthlyScoreChange: 1.5,
        quarterlyScoreChange: 4.0,
        currentTrend: ReputationTrend.improving,
        achievedMilestones: [
          ReputationMilestone.firstJob,
          ReputationMilestone.tenJobsCompleted,
          ReputationMilestone.fiftyJobsCompleted,
          ReputationMilestone.hundredJobsCompleted,
          ReputationMilestone.reliabilityExpert,
        ],
        specializationScores: {
          'eventSecurity': 4.6,
          'retailSecurity': 4.3,
          'hospitalSecurity': 4.5,
        },
        topSpecialization: 'eventSecurity',
        averageHourlyRate: 18.50, // Above minimum wage
      );

      blocTest<ReputationBloc, ReputationState>(
        'loads reputation data with Dutch CAO compliance indicators',
        build: () {
          when(mockService.getReputation(testUserId, testUserRole, useCache: true))
              .thenAnswer((_) async => dutchGuardData);
          return bloc;
        },
        act: (bloc) => bloc.add(LoadReputation(testUserId, testUserRole)),
        expect: () => [
          ReputationLoading(),
          ReputationLoaded(dutchGuardData),
        ],
        verify: (bloc) {
          final loadedState = bloc.state as ReputationLoaded;
          final reputation = loadedState.reputationData;
          
          // Verify CAO arbeidsrecht compliance
          expect(reputation.isReliableByCAOStandards, isTrue);
          expect(reputation.wpbrCertified, isTrue); // Required for guards
          expect(reputation.averageHourlyRate, greaterThanOrEqualTo(12.0)); // Minimum security wage
          expect(reputation.qualifiesForPremiumJobs, isTrue);
          
          // Verify milestone achievements
          expect(reputation.achievedMilestones, contains(ReputationMilestone.reliabilityExpert));
          expect(reputation.achievedMilestones, contains(ReputationMilestone.hundredJobsCompleted));
          
          // Verify reputation level
          expect(reputation.reputationLevel, 
              anyOf(ReputationLevel.excellent, ReputationLevel.exceptional));
        },
      );
    });
  });
}