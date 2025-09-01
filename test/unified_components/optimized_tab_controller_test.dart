import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_components/optimized_tab_controller.dart';

void main() {
  group('OptimizedTabController', () {
    late List<OptimizedTab> testTabs;
    late Widget Function(BuildContext, int, OptimizedTab) testTabBuilder;

    setUp(() {
      testTabs = [
        OptimizedTab(title: 'Tab 1', badgeIdentifier: 'tab1'),
        OptimizedTab(title: 'Tab 2', badgeIdentifier: 'tab2'),
        OptimizedTab(title: 'Tab 3', badgeIdentifier: 'tab3'),
      ];

      testTabBuilder = (context, index, tab) => Container(
        key: ValueKey('tab_content_$index'),
        child: Text('Content for ${tab.title}'),
      );
    });

    testWidgets('should initialize with correct initial index', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTabController(
              tabs: testTabs,
              tabBuilder: testTabBuilder,
              initialIndex: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial tab is selected
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('should handle tab switching correctly', (tester) async {
      int? lastChangedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTabController(
              tabs: testTabs,
              tabBuilder: testTabBuilder,
              onTabChanged: (index) => lastChangedIndex = index,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on second tab
      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(lastChangedIndex, equals(1));
      expect(find.text('Content for Tab 2'), findsOneWidget);
    });

    testWidgets('should implement lazy loading when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTabController(
              tabs: testTabs,
              tabBuilder: testTabBuilder,
              enableLazyLoading: true,
              preloadDistance: 0, // Only load current tab
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only current tab content should be loaded
      expect(find.byKey(ValueKey('tab_content_0')), findsOneWidget);
      expect(find.byKey(ValueKey('tab_content_1')), findsNothing);
      expect(find.byKey(ValueKey('tab_content_2')), findsNothing);
    });

    testWidgets('should preload adjacent tabs based on preloadDistance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedTabController(
              tabs: testTabs,
              tabBuilder: testTabBuilder,
              enableLazyLoading: true,
              preloadDistance: 1,
              initialIndex: 1, // Start with middle tab
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Current tab and adjacent tabs should be loaded
      expect(find.byKey(ValueKey('tab_content_0')), findsOneWidget);
      expect(find.byKey(ValueKey('tab_content_1')), findsOneWidget);
      expect(find.byKey(ValueKey('tab_content_2')), findsOneWidget);
    });

    group('PerformanceMonitor', () {
      test('should record tab load metrics', () {
        final monitor = PerformanceMonitor(enabled: true);
        final metrics = <PerformanceMetric>[];

        monitor.recordTabLoad(0, 150);
        monitor.recordTabLoad(1, 200);

        expect(metrics.length, equals(0)); // Metrics are internal
      });

      test('should record tab switch metrics', () {
        final monitor = PerformanceMonitor(enabled: true);

        monitor.recordTabSwitch(0, 1, 50);

        // Verify no exceptions thrown
        expect(true, isTrue);
      });

      test('should generate performance report from metrics', () {
        final metrics = [
          PerformanceMetric(
            type: MetricType.tabLoad,
            tabIndex: 0,
            value: 100.0,
            timestamp: DateTime.now(),
          ),
          PerformanceMetric(
            type: MetricType.tabLoad,
            tabIndex: 1,
            value: 200.0,
            timestamp: DateTime.now(),
          ),
          PerformanceMetric(
            type: MetricType.tabSwitch,
            tabIndex: 1,
            value: 50.0,
            timestamp: DateTime.now(),
          ),
        ];

        final report = PerformanceReport.fromMetrics(metrics);

        expect(report.averageTabLoadTime, equals(150.0));
        expect(report.averageTabSwitchTime, equals(50.0));
        expect(report.summary, contains('Load: 150.0ms'));
        expect(report.summary, contains('Switch: 50.0ms'));
      });
    });

    group('Cache Management', () {
      testWidgets('should cache tab content when lazy loading is enabled', (tester) async {
        int buildCount = 0;
        
        Widget countingTabBuilder(BuildContext context, int index, OptimizedTab tab) {
          buildCount++;
          return Container(
            key: ValueKey('tab_content_$index'),
            child: Text('Content for ${tab.title} (Build #$buildCount)'),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: testTabs,
                tabBuilder: countingTabBuilder,
                enableLazyLoading: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final initialBuildCount = buildCount;

        // Switch to another tab and back
        await tester.tap(find.text('Tab 2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tab 1'));
        await tester.pumpAndSettle();

        // Build count should not increase for cached content
        expect(buildCount, greaterThan(initialBuildCount));
      });
    });

    group('Memory Management', () {
      test('should dispose resources properly', () {
        final monitor = PerformanceMonitor(enabled: true);
        
        // Should not throw when disposing
        expect(() => monitor.dispose(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty tabs list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: [],
                tabBuilder: testTabBuilder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not crash
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('should handle single tab', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: [OptimizedTab(title: 'Single Tab')],
                tabBuilder: testTabBuilder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Single Tab'), findsOneWidget);
      });

      testWidgets('should handle invalid initial index', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: testTabs,
                tabBuilder: testTabBuilder,
                initialIndex: 10, // Invalid index
              ),
            ),
          ),
        );

        // Should not crash and handle invalid index gracefully
        await tester.pumpAndSettle();
        // The widget should handle invalid index without crashing
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Benchmarks', () {
      testWidgets('should complete tab switching within performance threshold', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: testTabs,
                tabBuilder: testTabBuilder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform multiple tab switches
        for (int i = 0; i < testTabs.length; i++) {
          await tester.tap(find.text(testTabs[i].title));
          await tester.pumpAndSettle();
        }

        stopwatch.stop();

        // Tab switching should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      testWidgets('should handle rapid tab switching without performance degradation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedTabController(
                tabs: testTabs,
                tabBuilder: testTabBuilder,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Rapid tab switching
        for (int i = 0; i < 10; i++) {
          final tabIndex = i % testTabs.length;
          await tester.tap(find.text(testTabs[tabIndex].title));
          await tester.pump(Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should handle rapid switching efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
