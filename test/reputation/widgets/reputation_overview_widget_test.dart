import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:securyflex_app/core/unified_components.dart';
import 'package:securyflex_app/reputation/widgets/reputation_overview_widget.dart';
import 'package:securyflex_app/reputation/bloc/reputation_bloc.dart';
import 'package:securyflex_app/reputation/models/reputation_data.dart';

import 'reputation_overview_widget_test.mocks.dart';

@GenerateMocks([ReputationBloc])
void main() {
  group('ReputationOverviewWidget Tests', () {
    late MockReputationBloc mockBloc;

    setUp(() {
      mockBloc = MockReputationBloc();
    });

    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(ReputationLoading());
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([ReputationLoading()]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Reputatie laden...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays reputation data when loaded', (WidgetTester tester) async {
      // Arrange
      final testReputationData = ReputationData(
        userId: 'test-user-123',
        userRole: 'guard',
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

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoading(),
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      await tester.pump(); // Process loading state
      await tester.pump(); // Process loaded state

      // Assert
      expect(find.text('Reputatie Score'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(find.text('Uitstekend'), findsOneWidget); // ReputationLevel.excellent for score 85
      expect(find.text('25'), findsOneWidget); // totalJobsCompleted
      expect(find.text('Opdrachten voltooid'), findsOneWidget);
    });

    testWidgets('displays trend indicator correctly', (WidgetTester tester) async {
      // Arrange
      final improvingReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      ).copyWith(
        overallScore: 75.0,
        currentTrend: ReputationTrend.improving,
        monthlyScoreChange: 5.0,
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(improvingReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(improvingReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
              showDetailedMetrics: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Stijgende trend'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('+5.0'), findsOneWidget);
    });

    testWidgets('displays metrics grid when showDetailedMetrics is true', (WidgetTester tester) async {
      // Arrange
      final testReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      ).copyWith(
        overallScore: 80.0,
        totalJobsCompleted: 50,
        reliabilityScore: 95.0,
        repeatClientPercentage: 40.0,
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
              showDetailedMetrics: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('50'), findsOneWidget); // Total jobs completed
      expect(find.text('Opdrachten voltooid'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget); // Reliability score
      expect(find.text('Betrouwbaarheid'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget); // Repeat client percentage
      expect(find.text('Herhalings %'), findsOneWidget);
    });

    testWidgets('displays milestones when showMilestones is true', (WidgetTester tester) async {
      // Arrange
      final testReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      ).copyWith(
        achievedMilestones: [
          ReputationMilestone.firstJob,
          ReputationMilestone.tenJobsCompleted,
          ReputationMilestone.firstGoodReview,
        ],
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
              showMilestones: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Recent behaald'), findsOneWidget);
      expect(find.text('Eerste Opdracht'), findsOneWidget);
      expect(find.text('10 Opdrachten Voltooid'), findsOneWidget);
      expect(find.text('Eerste Positieve Review'), findsOneWidget);
    });

    testWidgets('displays error state correctly', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Network connection failed';
      when(mockBloc.state).thenReturn(ReputationError(errorMessage));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationError(errorMessage),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Fout bij laden reputatie'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Opnieuw proberen'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handles tap events correctly', (WidgetTester tester) async {
      // Arrange
      bool tapCalled = false;
      final testReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap on the card
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapCalled, isTrue);
    });

    testWidgets('triggers reputation load on initialization', (WidgetTester tester) async {
      // Arrange
      when(mockBloc.state).thenReturn(ReputationInitial());
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([ReputationInitial()]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      // Assert
      verify(mockBloc.add(argThat(isA<LoadReputation>()))).called(1);
    });

    testWidgets('displays different role-based theming for company', (WidgetTester tester) async {
      // Arrange
      final companyReputationData = ReputationData.initial(
        userId: 'company-123',
        userRole: 'company',
      ).copyWith(
        overallScore: 82.0,
        kvkVerified: true,
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(companyReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(companyReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'company-123',
              userRole: 'company',
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - Should display business icon instead of security icon
      expect(find.byIcon(Icons.business), findsOneWidget);
      expect(find.text('82'), findsOneWidget);
    });

    testWidgets('animates score display correctly', (WidgetTester tester) async {
      // Arrange
      final testReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      ).copyWith(overallScore: 85.0);

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoading(),
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      await tester.pump(); // Loading state
      await tester.pump(); // Loaded state - start animation
      
      // Animation should start from 0 and animate to 85
      expect(find.text('0'), findsOneWidget);
      
      await tester.pump(const Duration(milliseconds: 300)); // Mid-animation
      // Score should be animating upward (exact value depends on animation timing)
      
      await tester.pump(const Duration(seconds: 2)); // Complete animation
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('displays correct Dutch localization', (WidgetTester tester) async {
      // Arrange
      final testReputationData = ReputationData.initial(
        userId: 'test-user-123',
        userRole: 'guard',
      ).copyWith(
        overallScore: 85.0,
        firstJobDate: DateTime.now().subtract(const Duration(days: 180)),
      );

      when(mockBloc.state).thenReturn(ReputationLoaded(testReputationData));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationLoaded(testReputationData),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - Check for Dutch text
      expect(find.text('Reputatie Score'), findsOneWidget);
      expect(find.text('Uitstekend'), findsOneWidget); // Excellence level in Dutch
      expect(find.textContaining('Lid sinds'), findsOneWidget);
      expect(find.textContaining('maanden'), findsOneWidget);
      expect(find.textContaining('Laatst bijgewerkt'), findsOneWidget);
    });

    group('Score Color Testing', () {
      testWidgets('displays green color for excellent scores (90+)', (WidgetTester tester) async {
        // Arrange
        final excellentReputationData = ReputationData.initial(
          userId: 'test-user-123',
          userRole: 'guard',
        ).copyWith(overallScore: 95.0);

        when(mockBloc.state).thenReturn(ReputationLoaded(excellentReputationData));
        when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
          ReputationLoaded(excellentReputationData),
        ]));

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ReputationBloc>.value(
              value: mockBloc,
              child: const ReputationOverviewWidget(
                userId: 'test-user-123',
                userRole: 'guard',
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(seconds: 2)); // Complete animation

        // Assert - Find the score text widget and verify its color
        final scoreTextWidget = find.text('95');
        expect(scoreTextWidget, findsOneWidget);
        
        final textWidget = tester.widget<Text>(scoreTextWidget);
        expect(textWidget.style?.color, equals(DesignTokens.statusCompleted));
      });

      testWidgets('displays red color for poor scores (<60)', (WidgetTester tester) async {
        // Arrange
        final poorReputationData = ReputationData.initial(
          userId: 'test-user-123',
          userRole: 'guard',
        ).copyWith(overallScore: 45.0);

        when(mockBloc.state).thenReturn(ReputationLoaded(poorReputationData));
        when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
          ReputationLoaded(poorReputationData),
        ]));

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ReputationBloc>.value(
              value: mockBloc,
              child: const ReputationOverviewWidget(
                userId: 'test-user-123',
                userRole: 'guard',
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(seconds: 2)); // Complete animation

        // Assert
        final scoreTextWidget = find.text('45');
        expect(scoreTextWidget, findsOneWidget);
        
        final textWidget = tester.widget<Text>(scoreTextWidget);
        expect(textWidget.style?.color, equals(DesignTokens.colorError));
      });
    });

    testWidgets('retry button works on error state', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Network error';
      when(mockBloc.state).thenReturn(ReputationError(errorMessage));
      when(mockBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ReputationError(errorMessage),
      ]));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ReputationBloc>.value(
            value: mockBloc,
            child: const ReputationOverviewWidget(
              userId: 'test-user-123',
              userRole: 'guard',
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap retry button
      await tester.tap(find.text('Opnieuw proberen'));
      await tester.pump();

      // Assert - Should trigger another LoadReputation event
      verify(mockBloc.add(argThat(isA<LoadReputation>()))).called(2); // Initial + retry
    });
  });
}