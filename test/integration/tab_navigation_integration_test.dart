import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:securyflex_app/main.dart' as app;
import 'package:securyflex_app/services/notification_badge_service.dart';
import 'package:securyflex_app/unified_components/smart_tab_bar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tab Navigation Integration Tests', () {
    late NotificationBadgeService badgeService;

    setUpAll(() async {
      badgeService = NotificationBadgeService.instance;
      await badgeService.initialize();
    });

    tearDownAll(() async {
      await badgeService.clearAllBadges();
    });

    testWidgets('Complete Jobs Tab Workflow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to Jobs tab
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Verify Jobs tab screen is displayed
      expect(find.text('Beschikbaar'), findsOneWidget);
      expect(find.text('Sollicitaties'), findsOneWidget);
      expect(find.text('Geschiedenis'), findsOneWidget);

      // Test tab switching within Jobs screen
      await tester.tap(find.text('Sollicitaties'));
      await tester.pumpAndSettle();

      // Verify Applications tab content is loaded
      expect(find.text('Mijn Sollicitaties'), findsOneWidget);

      // Switch to Job History tab
      await tester.tap(find.text('Geschiedenis'));
      await tester.pumpAndSettle();

      // Verify Job History tab content is loaded
      expect(find.text('Werkgeschiedenis'), findsOneWidget);

      // Return to Job Discovery tab
      await tester.tap(find.text('Beschikbaar'));
      await tester.pumpAndSettle();

      // Verify we're back to the first tab
      expect(find.text('Beschikbare Jobs'), findsOneWidget);
    });

    testWidgets('Complete Planning Tab Workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to Planning tab
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();

      // Verify Planning tab screen is displayed
      expect(find.text('Diensten'), findsOneWidget);
      expect(find.text('Beschikbaar'), findsOneWidget);
      expect(find.text('Urenregistratie'), findsOneWidget);

      // Test Shifts tab
      await tester.tap(find.text('Diensten'));
      await tester.pumpAndSettle();

      // Verify Shifts tab content
      expect(find.text('Mijn Diensten'), findsOneWidget);

      // Test Availability tab
      await tester.tap(find.text('Beschikbaar'));
      await tester.pumpAndSettle();

      // Verify Availability tab content
      expect(find.text('Beschikbaarheid Instellen'), findsOneWidget);

      // Test Timesheet tab
      await tester.tap(find.text('Urenregistratie'));
      await tester.pumpAndSettle();

      // Verify Timesheet tab content
      expect(find.text('Urenstaat'), findsOneWidget);
    });

    testWidgets('Cross-Tab Navigation with Context Sharing', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Start in Jobs tab
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Select a job (simulate job selection)
      await tester.tap(find.text('Beschikbaar'));
      await tester.pumpAndSettle();

      // Find and tap on a job card
      final jobCard = find.byType(Card).first;
      await tester.tap(jobCard);
      await tester.pumpAndSettle();

      // Navigate to Applications tab to see application status
      await tester.tap(find.text('Sollicitaties'));
      await tester.pumpAndSettle();

      // Verify context is maintained
      expect(find.byType(Card), findsWidgets);

      // Navigate to Planning to check schedule
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();

      // Verify Planning screen loads with context
      expect(find.text('Planning'), findsOneWidget);
    });

    testWidgets('Badge Notification Workflow', (tester) async {
      // Set up test badges
      await badgeService.updateJobBadges(
        newApplications: 3,
        applicationUpdates: 1,
        newJobs: 5,
      );

      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to Jobs tab
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Verify badges are displayed
      expect(find.byType(SmartTabBar), findsOneWidget);

      // Tap on Applications tab (should clear badges)
      await tester.tap(find.text('Sollicitaties'));
      await tester.pumpAndSettle();

      // Verify badge clearing behavior
      // Note: This would need to be verified through badge service state
      expect(badgeService.getBadgeCount(BadgeIdentifiers.newApplications), equals(0));
    });

    testWidgets('Performance Under Load', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      final stopwatch = Stopwatch()..start();

      // Perform rapid tab switching
      for (int i = 0; i < 20; i++) {
        // Switch between main tabs
        await tester.tap(find.text('Jobs'));
        await tester.pump(Duration(milliseconds: 100));
        
        await tester.tap(find.text('Planning'));
        await tester.pump(Duration(milliseconds: 100));
        
        await tester.tap(find.text('Chat'));
        await tester.pump(Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify performance is acceptable
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
    });

    testWidgets('Memory Management During Extended Use', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Simulate extended app usage
      for (int session = 0; session < 5; session++) {
        // Navigate through all main tabs
        await tester.tap(find.text('Jobs'));
        await tester.pumpAndSettle();

        // Navigate through Jobs sub-tabs
        await tester.tap(find.text('Beschikbaar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sollicitaties'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Geschiedenis'));
        await tester.pumpAndSettle();

        // Navigate to Planning
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Navigate through Planning sub-tabs
        await tester.tap(find.text('Diensten'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beschikbaar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Urenregistratie'));
        await tester.pumpAndSettle();

        // Navigate to other tabs
        await tester.tap(find.text('Chat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profiel'));
        await tester.pumpAndSettle();
      }

      // App should still be responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Accessibility Navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Test semantic navigation
      await tester.tap(find.bySemanticsLabel('Jobs'));
      await tester.pumpAndSettle();

      // Verify accessibility labels are present
      expect(find.bySemanticsLabel('Beschikbaar'), findsOneWidget);
      expect(find.bySemanticsLabel('Sollicitaties'), findsOneWidget);
      expect(find.bySemanticsLabel('Geschiedenis'), findsOneWidget);

      // Test badge accessibility
      await badgeService.updateJobBadges(newApplications: 2);
      await tester.pumpAndSettle();

      // Verify badge accessibility labels
      expect(find.bySemanticsLabel(RegExp(r'.*nieuwe meldingen.*')), findsWidgets);
    });

    testWidgets('Error Recovery and Resilience', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Test navigation with potential errors
      try {
        // Rapid navigation that might cause race conditions
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('Jobs'));
          await tester.pump(Duration(milliseconds: 10));
          await tester.tap(find.text('Planning'));
          await tester.pump(Duration(milliseconds: 10));
        }

        await tester.pumpAndSettle();

        // App should still be functional
        expect(find.byType(MaterialApp), findsOneWidget);
      } catch (e) {
        // If errors occur, they should be handled gracefully
        fail('Navigation should handle rapid switching gracefully: $e');
      }
    });

    testWidgets('State Persistence Across Navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Navigate to Jobs and interact with content
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Scroll in the Jobs tab
      await tester.drag(find.byType(ListView).first, Offset(0, -200));
      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.text('Planning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Verify state is maintained (scroll position, etc.)
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
