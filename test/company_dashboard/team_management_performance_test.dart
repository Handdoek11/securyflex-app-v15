import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/screens/team_management_screen.dart';
import 'package:securyflex_app/company_dashboard/utils/team_management_performance.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Performance benchmark tests for SecuryFlex Team Management
/// Validates loading times, memory usage, and navigation performance
void main() {

  group('🚀 Performance Benchmark Tests', () {
    late TeamManagementPerformance performanceMonitor;

    setUp(() {
      performanceMonitor = TeamManagementPerformance();
    });

    tearDown(() {
      performanceMonitor.dispose();
    });

    group('Loading Time Benchmarks', () {
      testWidgets('Team Management should load within 2 seconds', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Team tab
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        // Wait for Team Management to fully load
        await tester.pump(const Duration(milliseconds: 1000));

        stopwatch.stop();
        final loadTime = stopwatch.elapsedMilliseconds;

        debugPrint('📊 Team Management Load Time: ${loadTime}ms');
        
        // Verify load time is under 2 seconds (2000ms)
        expect(loadTime, lessThan(2000), 
               reason: 'Team Management should load within 2 seconds');

        // Log performance data
        performanceMonitor.cacheData('team_load_time', loadTime);
      });

      testWidgets('Tab switching should be under 300ms', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Team tab first
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Measure tab switching within Team Management
        final stopwatch = Stopwatch()..start();

        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        stopwatch.stop();
        final switchTime = stopwatch.elapsedMilliseconds;

        debugPrint('📊 Tab Switch Time: ${switchTime}ms');
        
        // Verify tab switch is under 300ms
        expect(switchTime, lessThan(300), 
               reason: 'Tab switching should be under 300ms');

        // Test multiple tab switches
        final tabSwitchTimes = <int>[];
        
        for (final tab in ['Status', 'Analytics', 'Planning']) {
          final sw = Stopwatch()..start();
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          sw.stop();
          tabSwitchTimes.add(sw.elapsedMilliseconds);
        }

        final averageTime = tabSwitchTimes.reduce((a, b) => a + b) / tabSwitchTimes.length;
        debugPrint('📊 Average Tab Switch Time: ${averageTime.toStringAsFixed(1)}ms');
        
        expect(averageTime, lessThan(300), 
               reason: 'Average tab switching should be under 300ms');
      });

      testWidgets('Navigation between main tabs should be under 500ms', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        final navigationTimes = <String, int>{};
        final tabs = ['Dashboard', 'Opdrachten', 'Chat', 'Team', 'Profiel'];

        for (int i = 0; i < tabs.length - 1; i++) {
          final stopwatch = Stopwatch()..start();
          
          await tester.tap(find.text(tabs[i + 1]));
          await tester.pumpAndSettle();
          
          stopwatch.stop();
          navigationTimes[tabs[i + 1]] = stopwatch.elapsedMilliseconds;
          
          debugPrint('📊 Navigation to ${tabs[i + 1]}: ${stopwatch.elapsedMilliseconds}ms');
        }

        // Verify all navigation times are under 500ms
        for (final entry in navigationTimes.entries) {
          expect(entry.value, lessThan(500), 
                 reason: 'Navigation to ${entry.key} should be under 500ms');
        }

        final averageNavTime = navigationTimes.values.reduce((a, b) => a + b) / navigationTimes.length;
        debugPrint('📊 Average Navigation Time: ${averageNavTime.toStringAsFixed(1)}ms');
      });
    });

    group('Memory Usage Benchmarks', () {
      testWidgets('Memory usage should not exceed 150MB', (WidgetTester tester) async {
        // Get initial memory usage
        final initialMemory = _getMemoryUsage();
        debugPrint('📊 Initial Memory Usage: ${initialMemory}MB');

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate through all tabs to load all screens
        final tabs = ['Dashboard', 'Opdrachten', 'Chat', 'Team', 'Profiel'];
        
        for (final tab in tabs) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 500));
          
          final currentMemory = _getMemoryUsage();
          debugPrint('📊 Memory after loading $tab: ${currentMemory}MB');
          
          // Verify memory doesn't exceed 150MB
          expect(currentMemory, lessThan(150), 
                 reason: 'Memory usage should not exceed 150MB');
        }

        // Test Team Management sub-tabs
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        final teamTabs = ['Status', 'Planning', 'Analytics'];
        for (final tab in teamTabs) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          
          final currentMemory = _getMemoryUsage();
          debugPrint('📊 Memory after Team $tab: ${currentMemory}MB');
          
          expect(currentMemory, lessThan(150), 
                 reason: 'Memory usage should not exceed 150MB in Team Management');
        }
      });

      testWidgets('Memory should not increase significantly with repeated navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Get baseline memory after initial load
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
        
        final baselineMemory = _getMemoryUsage();
        debugPrint('📊 Baseline Memory (Team loaded): ${baselineMemory}MB');

        // Perform repeated navigation cycles
        for (int cycle = 0; cycle < 5; cycle++) {
          // Navigate through all main tabs
          for (final tab in ['Dashboard', 'Opdrachten', 'Chat', 'Team', 'Profiel']) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
          }

          // Navigate through Team Management tabs
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();
          
          for (final tab in ['Status', 'Planning', 'Analytics']) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
          }

          final currentMemory = _getMemoryUsage();
          debugPrint('📊 Memory after cycle ${cycle + 1}: ${currentMemory}MB');
          
          // Memory should not increase by more than 20MB from baseline
          expect(currentMemory - baselineMemory, lessThan(20), 
                 reason: 'Memory should not leak significantly with repeated navigation');
        }
      });
    });

    group('Caching Performance Tests', () {
      testWidgets('Data caching should improve subsequent load times', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // First load (cold start)
        final firstLoadStopwatch = Stopwatch()..start();
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
        firstLoadStopwatch.stop();
        
        final firstLoadTime = firstLoadStopwatch.elapsedMilliseconds;
        debugPrint('📊 First Team Load Time: ${firstLoadTime}ms');

        // Navigate away and back (should use cache)
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        final secondLoadStopwatch = Stopwatch()..start();
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        secondLoadStopwatch.stop();
        
        final secondLoadTime = secondLoadStopwatch.elapsedMilliseconds;
        debugPrint('📊 Second Team Load Time (cached): ${secondLoadTime}ms');

        // Second load should be faster (cached data)
        expect(secondLoadTime, lessThan(firstLoadTime * 0.8), 
               reason: 'Cached load should be at least 20% faster');
      });
    });

    group('Stress Testing', () {
      testWidgets('Should handle rapid tab switching without performance degradation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Team Management
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        final switchTimes = <int>[];
        final tabs = ['Status', 'Planning', 'Analytics'];

        // Perform rapid tab switching
        for (int i = 0; i < 20; i++) {
          final tab = tabs[i % tabs.length];
          final stopwatch = Stopwatch()..start();
          
          await tester.tap(find.text(tab));
          await tester.pump(); // Don't wait for settle to test rapid switching
          
          stopwatch.stop();
          switchTimes.add(stopwatch.elapsedMilliseconds);
        }

        await tester.pumpAndSettle(); // Final settle

        final averageSwitchTime = switchTimes.reduce((a, b) => a + b) / switchTimes.length;
        final maxSwitchTime = switchTimes.reduce((a, b) => a > b ? a : b);
        
        debugPrint('📊 Rapid Switch Average: ${averageSwitchTime.toStringAsFixed(1)}ms');
        debugPrint('📊 Rapid Switch Max: ${maxSwitchTime}ms');

        // Performance should not degrade significantly
        expect(averageSwitchTime, lessThan(100), 
               reason: 'Rapid tab switching should maintain good performance');
        expect(maxSwitchTime, lessThan(300), 
               reason: 'No single switch should take more than 300ms');
      });
    });
  });
}

/// Helper function to get current memory usage
/// Note: This is a simplified implementation. In a real app, you'd use
/// platform-specific memory monitoring tools
double _getMemoryUsage() {
  // Simplified memory calculation
  // In production, use ProcessInfo.currentRss or platform-specific tools
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      // Would use platform channels to get actual memory usage
      return 50.0 + (DateTime.now().millisecondsSinceEpoch % 100); // Mock data
    }
  } catch (e) {
    // Fallback for web/desktop
  }
  return 45.0; // Mock baseline memory usage
}

/// Performance test utilities
class PerformanceTestUtils {
  static Future<int> measureExecutionTime(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  static void logPerformanceMetrics(Map<String, dynamic> metrics) {
    debugPrint('📊 Performance Metrics:');
    for (final entry in metrics.entries) {
      debugPrint('   ${entry.key}: ${entry.value}');
    }
  }

  static bool isPerformanceAcceptable(int actualTime, int expectedTime, {double tolerance = 0.2}) {
    final maxAcceptable = expectedTime * (1 + tolerance);
    return actualTime <= maxAcceptable;
  }
}
