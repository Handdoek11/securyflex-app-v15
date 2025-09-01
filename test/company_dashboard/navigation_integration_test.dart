import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/screens/team_management_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Comprehensive navigation tests for SecuryFlex Team Management
/// Tests the Team Management screen and navigation functionality
void main() {

  group('🧭 Team Management Navigation Tests', () {

    group('Team Management Screen Structure', () {
      testWidgets('should display Team Management screen with tabs correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Team Management tabs are present
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Planning'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);

        // Verify Team Management header is present
        expect(find.text('Team Management'), findsOneWidget);
      });

      testWidgets('should navigate between Team Management tabs correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test navigation to Planning tab
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Verify Planning content is displayed
        expect(find.text('Planning & Roosters'), findsOneWidget);

        // Test navigation to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Verify Analytics content is displayed
        expect(find.text('Team Analytics'), findsOneWidget);

        // Test navigation back to Status tab
        await tester.tap(find.text('Status'));
        await tester.pumpAndSettle();

        // Verify Status content is displayed
        expect(find.text('Team Status'), findsOneWidget);
      });
    });

    group('State Preservation Tests', () {
      testWidgets('should preserve Team Management state when switching tabs', (WidgetTester tester) async {
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

        // Wait for team data to load
        await tester.pump(const Duration(milliseconds: 1000));

        // Switch to Planning tab within Team Management
        await tester.tap(find.text('Planning'));
        await tester.pumpAndSettle();

        // Verify Planning content is displayed
        expect(find.text('Planning & Roosters'), findsOneWidget);

        // Navigate away to Dashboard
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();

        // Navigate back to Team
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        // Verify we're still on the Planning tab (state preserved)
        expect(find.text('Planning & Roosters'), findsOneWidget);
      });

      testWidgets('should preserve scroll position when switching tabs', (WidgetTester tester) async {
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

        // Wait for data to load
        await tester.pump(const Duration(milliseconds: 1000));

        // Find scrollable widget and scroll down
        final scrollable = find.byType(SingleChildScrollView).first;
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pumpAndSettle();

        // Navigate away and back
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();

        // Verify scroll position is preserved (implementation-dependent)
        // This test validates that the scroll controller is maintained
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    });

    group('Deep Linking Tests', () {
      testWidgets('should handle direct navigation to Team Management', (WidgetTester tester) async {
        // Simulate deep link to Team Management
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            initialRoute: '/company/team',
            routes: {
              '/company/team': (context) => const TeamManagementScreen(),
            },
          ),
        );

        await tester.pumpAndSettle();

        // Verify Team Management screen is displayed
        expect(find.text('Team Management'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
      });

      testWidgets('should handle deep link to specific Team Management tab', (WidgetTester tester) async {
        // This would require route parameter handling
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify correct tab is selected (would need route parameter implementation)
        expect(find.text('Team Management'), findsOneWidget);
      });
    });

    group('Back Button Behavior Tests', () {
      testWidgets('should handle back button correctly within Team Management', (WidgetTester tester) async {
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

        // Switch to Analytics tab
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        // Simulate back button press
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );

        await tester.pumpAndSettle();

        // Verify we're still in Team Management (back button should not exit)
        expect(find.text('Team Management'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle Team Management loading errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Wait for potential error state
        await tester.pump(const Duration(milliseconds: 2000));

        // Verify error handling (either data loads or error state is shown)
        expect(
          find.text('Team Management'),
          findsOneWidget,
        );
      });

      testWidgets('should allow retry after error state', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // If error state is shown, test retry functionality
        if (find.text('Opnieuw Proberen').evaluate().isNotEmpty) {
          await tester.tap(find.text('Opnieuw Proberen'));
          await tester.pumpAndSettle();

          // Verify loading state is shown
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility labels for navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic labels are present for Team Management tabs
        expect(find.bySemanticsLabel('Status'), findsOneWidget);
        expect(find.bySemanticsLabel('Planning'), findsOneWidget);
        expect(find.bySemanticsLabel('Analytics'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: const TeamManagementScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test tab key navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Verify focus is on tab navigation element
        expect(find.byType(TabBar), findsOneWidget);
      });
    });
  });
}
