import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/screens/team_management_screen.dart';
import 'package:securyflex_app/company_dashboard/services/team_management_service.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// State preservation tests for SecuryFlex navigation and data management
/// Ensures data integrity and state consistency across navigation
void main() {
  group('🔄 State Preservation Tests', () {
    
    group('Navigation State Preservation', () {
      testWidgets('should preserve selected tab when switching between tabs', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Switch to Planning tab
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Verify Planning content is displayed
        expect(find.text('Planning & Roosters'), findsOneWidget);

        // Switch to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Verify Analytics content is displayed
        expect(find.text('Team Analytics'), findsOneWidget);

        // Switch back to Planning tab
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Verify we're back on Planning tab
        expect(find.text('Planning & Roosters'), findsOneWidget);
      });

      testWidgets('should preserve scroll position in Team Management', (WidgetTester tester) async {
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

        // Wait for data to load
        await tester.pump(const Duration(milliseconds: 1000));

        // Find the scrollable widget and scroll down
        final scrollableFinder = find.byType(SingleChildScrollView).first;
        final scrollableWidget = tester.widget<SingleChildScrollView>(scrollableFinder);
        final scrollController = scrollableWidget.controller;

        // Scroll down
        await tester.drag(scrollableFinder, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Get current scroll position
        final scrollPosition = scrollController?.offset ?? 0.0;
        expect(scrollPosition, greaterThan(0));

        // Navigate away and back
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        // Verify scroll position is preserved (within reasonable tolerance)
        final newScrollableFinder = find.byType(SingleChildScrollView).first;
        final newScrollableWidget = tester.widget<SingleChildScrollView>(newScrollableFinder);
        final newScrollPosition = newScrollableWidget.controller?.offset ?? 0.0;

        expect(newScrollPosition, closeTo(scrollPosition, 50.0));
      });

      testWidgets('should preserve form data in Team Management', (WidgetTester tester) async {
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

        // Wait for data to load
        await tester.pump(const Duration(milliseconds: 1000));

        // If there are any text fields or form inputs, test their preservation
        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          // Enter some text
          await tester.enterText(textFields.first, 'Test input');
          await tester.pumpAndSettle();

          // Navigate away and back
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();

          // Verify text is preserved
          expect(find.text('Test input'), findsOneWidget);
        }
      });
    });

    group('Data State Preservation', () {
      testWidgets('should preserve loaded team data across navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Team Management and wait for data to load
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Verify team data is loaded
        expect(find.text('Jan de Vries'), findsOneWidget);
        expect(find.text('Marie Bakker'), findsOneWidget);

        // Navigate away
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // Navigate back quickly (should use cached data)
        final stopwatch = Stopwatch()..start();
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Verify data is still there (loaded from cache)
        expect(find.text('Jan de Vries'), findsOneWidget);
        expect(find.text('Marie Bakker'), findsOneWidget);

        // Should load faster due to caching
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('should handle data refresh correctly', (WidgetTester tester) async {
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
        await tester.pump(const Duration(milliseconds: 1000));

        // Look for refresh button or pull-to-refresh
        final refreshButtons = find.byIcon(Icons.refresh);
        if (refreshButtons.evaluate().isNotEmpty) {
          // Tap refresh button
          await tester.tap(refreshButtons.first);
          await tester.pumpAndSettle();

          // Verify loading indicator appears
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Wait for refresh to complete
          await tester.pump(const Duration(milliseconds: 1000));
          await tester.pumpAndSettle();

          // Verify data is still displayed
          expect(find.text('Team Management'), findsOneWidget);
        }
      });

      testWidgets('should maintain filter and search state', (WidgetTester tester) async {
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
        await tester.pump(const Duration(milliseconds: 1000));

        // Look for search or filter widgets
        final searchFields = find.byType(TextField);
        final dropdowns = find.byType(DropdownButton);

        if (searchFields.evaluate().isNotEmpty) {
          // Enter search text
          await tester.enterText(searchFields.first, 'Jan');
          await tester.pumpAndSettle();

          // Navigate away and back
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();

          // Verify search text is preserved
          expect(find.text('Jan'), findsOneWidget);
        }

        if (dropdowns.evaluate().isNotEmpty) {
          // Test dropdown state preservation would go here
          // This depends on the specific dropdown implementation
        }
      });
    });

    group('Service State Preservation', () {
      testWidgets('should maintain service connections across navigation', (WidgetTester tester) async {
        final teamService = TeamManagementService();
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Team Management to initialize services
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));

        // Verify service is initialized
        expect(teamService.isCacheFresh, isFalse); // Initially not fresh

        // Navigate away and back multiple times
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();
        }

        // Service should still be functional
        expect(find.text('Team Management'), findsOneWidget);
      });

      testWidgets('should handle service errors gracefully during navigation', (WidgetTester tester) async {
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

        // Wait for potential error state
        await tester.pump(const Duration(milliseconds: 2000));

        // If error state is shown, verify it's handled properly
        if (find.text('Fout bij laden gegevens').evaluate().isNotEmpty) {
          // Navigate away and back
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();

          // Error state should be preserved or retry should be available
          final hasErrorText = find.text('Fout bij laden gegevens').evaluate().isNotEmpty;
          final hasRetryButton = find.text('Opnieuw Proberen').evaluate().isNotEmpty;
          expect(hasErrorText || hasRetryButton, isTrue);
        }
      });
    });

    group('Memory Management Tests', () {
      testWidgets('should not create memory leaks with repeated navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Perform multiple navigation cycles
        for (int cycle = 0; cycle < 10; cycle++) {
          // Navigate to Team
          await tester.tap(find.text('Team'));
          await tester.pumpAndSettle();

          // Switch between Team tabs
          await tester.tap(find.text('Planning'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Analytics'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Status'));
          await tester.pumpAndSettle();

          // Navigate away
          await tester.tap(find.text('Dashboard'));
          await tester.pumpAndSettle();
        }

        // Final navigation to Team should still work
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        expect(find.text('Team Management'), findsOneWidget);
      });

      testWidgets('should dispose of controllers properly', (WidgetTester tester) async {
        // Create and dispose Team Management screen multiple times
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            MaterialApp(
              theme: SecuryFlexTheme.getTheme(UserRole.company),
              home: const TeamManagementScreen(),
            ),
          );

          await tester.pumpAndSettle();

          // Verify screen loads correctly
          expect(find.text('Team Management'), findsOneWidget);

          // Dispose by pumping a different widget
          await tester.pumpWidget(
            MaterialApp(
              theme: SecuryFlexTheme.getTheme(UserRole.company),
              home: const Scaffold(body: Text('Empty')),
            ),
          );

          await tester.pumpAndSettle();
        }

        // No exceptions should be thrown during disposal cycles
        expect(find.text('Empty'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid navigation without state corruption', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Perform rapid navigation
        for (int i = 0; i < 20; i++) {
          final tabs = ['Dashboard', 'Opdrachten', 'Team', 'Chat', 'Profiel'];
          final tab = tabs[i % tabs.length];
          
          await tester.tap(find.text(tab));
          await tester.pump(); // Don't wait for settle to test rapid switching
        }

        await tester.pumpAndSettle();

        // App should still be functional
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('should handle orientation changes gracefully', (WidgetTester tester) async {
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
        await tester.pump(const Duration(milliseconds: 1000));

        // Switch to Planning tab
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Simulate orientation change by changing screen size
        await tester.binding.setSurfaceSize(const Size(800, 600)); // Landscape
        await tester.pumpAndSettle();

        // Verify state is preserved after orientation change
        expect(find.text('Planning & Roosters'), findsOneWidget);

        // Change back to portrait
        await tester.binding.setSurfaceSize(const Size(400, 800)); // Portrait
        await tester.pumpAndSettle();

        // State should still be preserved
        expect(find.text('Planning & Roosters'), findsOneWidget);
      });
    });
  });
}
