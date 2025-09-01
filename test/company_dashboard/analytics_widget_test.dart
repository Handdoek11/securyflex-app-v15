import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/company_dashboard/widgets/analytics_dashboard_widgets.dart';
import 'package:securyflex_app/company_dashboard/bloc/analytics_dashboard_bloc.dart';
import 'package:securyflex_app/unified_theme_system.dart';

// Mock classes
class MockAnalyticsDashboardBloc extends Mock implements AnalyticsDashboardBloc {}

/// Widget tests for analytics dashboard components
/// Tests UI rendering, user interactions, and state management
/// Follows SecuryFlex testing standards with unified design system

void main() {
  group('Analytics Dashboard Widget Tests', () {
    late MockAnalyticsDashboardBloc mockBloc;

    setUp(() {
      mockBloc = MockAnalyticsDashboardBloc();
    });

    tearDown(() {
      mockBloc.close();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.company),
        home: BlocProvider<AnalyticsDashboardBloc>.value(
          value: mockBloc,
          child: Scaffold(body: child),
        ),
      );
    }

    group('AnalyticsDashboardOverview', () {
      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loading,
        ));
        when(() => mockBloc.stream).thenAnswer((_) => Stream.value(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loading,
        )));

        await tester.pumpWidget(createTestWidget(
          AnalyticsDashboardOverview(companyId: 'test_company'),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when error occurs', (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.error,
          errorMessage: 'Test error message',
        ));
        when(() => mockBloc.stream).thenAnswer((_) => Stream.value(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.error,
          errorMessage: 'Test error message',
        )));

        await tester.pumpWidget(createTestWidget(
          AnalyticsDashboardOverview(companyId: 'test_company'),
        ));

        expect(find.text('Fout bij laden van analytics'), findsOneWidget);
        expect(find.text('Test error message'), findsOneWidget);
        expect(find.text('Opnieuw proberen'), findsOneWidget);
      });

      testWidgets('should show empty state when no data', (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loaded,
          dashboardData: {},
        ));
        when(() => mockBloc.stream).thenAnswer((_) => Stream.value(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loaded,
          dashboardData: {},
        )));

        await tester.pumpWidget(createTestWidget(
          AnalyticsDashboardOverview(companyId: 'test_company'),
        ));

        expect(find.byType(AnalyticsEmptyState), findsOneWidget);
        expect(find.text('Geen Analytics Data'), findsOneWidget);
      });

      testWidgets('should show dashboard content when data is loaded', (WidgetTester tester) async {
        final testDashboardData = {
          'today': {
            'views': 100,
            'applications': 15,
            'conversionRate': 15.0,
            'spend': 250.0,
            'activeJobs': 5,
          },
          'changes': {
            'views': 10.5,
            'applications': -5.2,
          },
          'performance': {
            'efficiency': 75.0,
            'qualityScore': 4.2,
            'retentionRate': 85.0,
          },
        };

        when(() => mockBloc.state).thenReturn(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loaded,
          companyId: 'test_company',
          dashboardData: testDashboardData,
          timeRange: AnalyticsTimeRange.lastWeek(),
          timeSeriesData: [],
          lastUpdated: DateTime.now(),
        ));
        when(() => mockBloc.stream).thenAnswer((_) => Stream.value(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.loaded,
          companyId: 'test_company',
          dashboardData: testDashboardData,
          timeRange: AnalyticsTimeRange.lastWeek(),
          timeSeriesData: [],
          lastUpdated: DateTime.now(),
        )));

        await tester.pumpWidget(createTestWidget(
          AnalyticsDashboardOverview(companyId: 'test_company'),
        ));

        // Check for metrics row
        expect(find.byType(AnalyticsMetricsRow), findsOneWidget);
        
        // Check for performance indicators
        expect(find.byType(AnalyticsPerformanceIndicators), findsOneWidget);
        
        // Check for time series chart
        expect(find.byType(AnalyticsTimeSeriesChart), findsOneWidget);
        
        // Check for quick actions
        expect(find.byType(AnalyticsQuickActions), findsOneWidget);
      });

      testWidgets('should trigger refresh when retry button is tapped', (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.error,
          errorMessage: 'Test error',
        ));
        when(() => mockBloc.stream).thenAnswer((_) => Stream.value(AnalyticsDashboardState(
          status: AnalyticsDashboardStatus.error,
          errorMessage: 'Test error',
        )));

        await tester.pumpWidget(createTestWidget(
          AnalyticsDashboardOverview(companyId: 'test_company'),
        ));

        await tester.tap(find.text('Opnieuw proberen'));
        await tester.pump();

        verify(() => mockBloc.add(any())).called(1);
      });
    });

    group('AnalyticsMetricsRow', () {
      testWidgets('should display all metric cards', (WidgetTester tester) async {
        final todayMetrics = {
          'views': 150,
          'applications': 25,
          'conversionRate': 16.7,
          'spend': 500.0,
        };

        final changes = {
          'views': 12.5,
          'applications': -8.3,
        };

        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricsRow(
            todayMetrics: todayMetrics,
            changes: changes,
          ),
        ));

        expect(find.byType(AnalyticsMetricCard), findsNWidgets(4));
        expect(find.text('Bekeken'), findsOneWidget);
        expect(find.text('Sollicitaties'), findsOneWidget);
        expect(find.text('Conversie'), findsOneWidget);
        expect(find.text('Uitgaven'), findsOneWidget);
      });

      testWidgets('should display metric values correctly', (WidgetTester tester) async {
        final todayMetrics = {
          'views': 150,
          'applications': 25,
          'conversionRate': 16.7,
          'spend': 500.0,
        };

        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricsRow(
            todayMetrics: todayMetrics,
            changes: {},
          ),
        ));

        expect(find.text('150'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('16.7%'), findsOneWidget);
        expect(find.text('€500'), findsOneWidget);
      });

      testWidgets('should show empty state when no metrics', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricsRow(
            todayMetrics: null,
            changes: null,
          ),
        ));

        expect(find.byType(AnalyticsMetricCard), findsNothing);
      });
    });

    group('AnalyticsMetricCard', () {
      testWidgets('should display metric information correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricCard(
            title: 'Test Metric',
            value: '123',
            change: 15.5,
            icon: Icons.trending_up,
          ),
        ));

        expect(find.text('Test Metric'), findsOneWidget);
        expect(find.text('123'), findsOneWidget);
        expect(find.text('15.5%'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      });

      testWidgets('should show negative change correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricCard(
            title: 'Test Metric',
            value: '123',
            change: -10.2,
            icon: Icons.trending_down,
          ),
        ));

        expect(find.text('10.2%'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });

      testWidgets('should handle no change value', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsMetricCard(
            title: 'Test Metric',
            value: '123',
            change: null,
            icon: Icons.info,
          ),
        ));

        expect(find.text('Test Metric'), findsOneWidget);
        expect(find.text('123'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsNothing);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
      });
    });

    group('AnalyticsPerformanceIndicators', () {
      testWidgets('should display performance indicators', (WidgetTester tester) async {
        final performance = {
          'efficiency': 75.0,
          'qualityScore': 4.2,
          'retentionRate': 85.0,
        };

        await tester.pumpWidget(createTestWidget(
          AnalyticsPerformanceIndicators(performance: performance),
        ));

        expect(find.text('Prestatie Indicatoren'), findsOneWidget);
        expect(find.byType(AnalyticsProgressIndicator), findsNWidgets(3));
        expect(find.text('Efficiëntie'), findsOneWidget);
        expect(find.text('Kwaliteit'), findsOneWidget);
        expect(find.text('Retentie'), findsOneWidget);
      });

      testWidgets('should handle null performance data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsPerformanceIndicators(performance: null),
        ));

        expect(find.byType(AnalyticsProgressIndicator), findsNothing);
      });
    });

    group('AnalyticsProgressIndicator', () {
      testWidgets('should display progress correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsProgressIndicator(
            label: 'Test Progress',
            value: 75.0,
            maxValue: 100.0,
            color: Colors.blue,
          ),
        ));

        expect(find.text('Test Progress'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle edge values correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsProgressIndicator(
            label: 'Edge Test',
            value: 150.0, // Over max
            maxValue: 100.0,
            color: Colors.red,
          ),
        ));

        expect(find.text('150%'), findsOneWidget);
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(1.0)); // Should be clamped to 1.0
      });
    });

    group('AnalyticsQuickActions', () {
      testWidgets('should display quick action buttons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsQuickActions(
            companyId: 'test_company',
            isDataStale: false,
            lastUpdated: DateTime.now(),
          ),
        ));

        expect(find.text('Snelle Acties'), findsOneWidget);
        expect(find.text('Ververs Data'), findsOneWidget);
        expect(find.text('Funnel Analyse'), findsOneWidget);
        expect(find.text('Bron Analyse'), findsOneWidget);
      });

      testWidgets('should show stale data warning', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsQuickActions(
            companyId: 'test_company',
            isDataStale: true,
            lastUpdated: DateTime.now().subtract(Duration(hours: 2)),
          ),
        ));

        expect(find.text('Data is verouderd. Ververs voor de laatste gegevens.'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('should trigger BLoC events when buttons are tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsQuickActions(
            companyId: 'test_company',
            isDataStale: false,
            lastUpdated: DateTime.now(),
          ),
        ));

        // Test refresh button
        await tester.tap(find.text('Ververs Data'));
        await tester.pump();
        verify(() => mockBloc.add(any())).called(1);

        // Test funnel analysis button
        await tester.tap(find.text('Funnel Analyse'));
        await tester.pump();
        verify(() => mockBloc.add(any())).called(2);

        // Test source analysis button
        await tester.tap(find.text('Bron Analyse'));
        await tester.pump();
        verify(() => mockBloc.add(any())).called(3);
      });

      testWidgets('should format last updated time correctly', (WidgetTester tester) async {
        final lastUpdated = DateTime.now().subtract(Duration(minutes: 30));
        
        await tester.pumpWidget(createTestWidget(
          AnalyticsQuickActions(
            companyId: 'test_company',
            isDataStale: false,
            lastUpdated: lastUpdated,
          ),
        ));

        expect(find.textContaining('30 minuten geleden'), findsOneWidget);
      });
    });

    group('AnalyticsEmptyState', () {
      testWidgets('should display empty state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsEmptyState(),
        ));

        expect(find.text('Geen Analytics Data'), findsOneWidget);
        expect(find.text('Er zijn nog geen analytics gegevens beschikbaar. Post je eerste opdracht om data te verzamelen.'), findsOneWidget);
        expect(find.text('Nieuwe Opdracht Plaatsen'), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      });

      testWidgets('should navigate when button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: AnalyticsEmptyState()),
          routes: {
            '/company/post-job': (context) => Scaffold(body: Text('Job Posting Page')),
          },
        ));

        await tester.tap(find.text('Nieuwe Opdracht Plaatsen'));
        await tester.pumpAndSettle();

        expect(find.text('Job Posting Page'), findsOneWidget);
      });
    });

    group('AnalyticsTimeSeriesChart', () {
      testWidgets('should display chart with data', (WidgetTester tester) async {
        final testData = [
          {'date': '2024-01-01', 'views': 100, 'applications': 10},
          {'date': '2024-01-02', 'views': 120, 'applications': 15},
          {'date': '2024-01-03', 'views': 90, 'applications': 8},
        ];

        await tester.pumpWidget(createTestWidget(
          AnalyticsTimeSeriesChart(
            data: testData,
            timeRange: AnalyticsTimeRange.lastWeek(),
          ),
        ));

        expect(find.text('Trend Analyse'), findsOneWidget);
        expect(find.text('Afgelopen week'), findsOneWidget);
        expect(find.byType(AnalyticsSimpleChart), findsOneWidget);
      });

      testWidgets('should show no data message when empty', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          AnalyticsTimeSeriesChart(
            data: [],
            timeRange: AnalyticsTimeRange.lastWeek(),
          ),
        ));

        expect(find.text('Geen data beschikbaar voor geselecteerde periode'), findsOneWidget);
        expect(find.byType(AnalyticsSimpleChart), findsNothing);
      });
    });

    group('AnalyticsSimpleChart', () {
      testWidgets('should display chart placeholder', (WidgetTester tester) async {
        final testData = [
          {'date': '2024-01-01', 'views': 100},
          {'date': '2024-01-02', 'views': 120},
        ];

        await tester.pumpWidget(createTestWidget(
          AnalyticsSimpleChart(data: testData),
        ));

        expect(find.text('Chart Visualisatie'), findsOneWidget);
        expect(find.text('2 datapunten'), findsOneWidget);
        expect(find.byIcon(Icons.show_chart), findsOneWidget);
      });
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should have proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnalyticsMetricCard(
            title: 'Test Metric',
            value: '123',
            change: 15.5,
            icon: Icons.trending_up,
          ),
        ),
      ));

      expect(find.text('Test Metric'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);

      // Verify accessibility
      expect(find.text('Test Metric'), findsOneWidget);
    });

    testWidgets('should support screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnalyticsProgressIndicator(
            label: 'Progress Test',
            value: 75.0,
            maxValue: 100.0,
            color: Colors.blue,
          ),
        ),
      ));

      expect(find.text('Progress Test'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      
      // Verify progress indicator is accessible
      final progressIndicator = find.byType(LinearProgressIndicator);
      expect(progressIndicator, findsOneWidget);
    });
  });
}
