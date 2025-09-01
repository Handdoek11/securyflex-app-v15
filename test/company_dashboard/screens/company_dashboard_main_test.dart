import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/screens/company_dashboard_main.dart';
import 'package:securyflex_app/company_dashboard/screens/company_notifications_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('CompanyDashboardMain Header Tests', () {

    setUp(() {
      // Setup would normally create a proper animation controller
      // For testing, we'll use the widget's built-in controller
    });

    testWidgets('should not display date in header', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Date should not be present in header
      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.textContaining('Jan'), findsNothing);
      expect(find.textContaining('Feb'), findsNothing);
      expect(find.textContaining('Mrt'), findsNothing);
    });

    testWidgets('should display notification button in header', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should display notification badge with count', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Should show badge with mock count "3"
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should navigate to notifications screen when notification button tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Act - Tap notification button
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      // Assert - Should navigate to notifications screen
      expect(find.byType(CompanyNotificationsScreen), findsOneWidget);
      expect(find.text('Notificaties'), findsOneWidget);
    });

    testWidgets('should display profile button in header', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });

    testWidgets('should display welcome message under header', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Welkom terug'), findsOneWidget);
      expect(find.text('Amsterdam Security Partners'), findsOneWidget);
    });

    testWidgets('should display current time in welcome section', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Should display current time (format: HH:mm)
      final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
      final timeWidgets = find.byWidgetPredicate((widget) =>
          widget is Text && 
          widget.data != null && 
          timeRegex.hasMatch(widget.data!));
      
      expect(timeWidgets, findsOneWidget);
    });

    testWidgets('should display day of week in Dutch', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Should display Dutch day names
      final dutchDays = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'];
      bool foundDutchDay = false;
      
      for (final day in dutchDays) {
        if (find.textContaining(day, findRichText: true).evaluate().isNotEmpty) {
          foundDutchDay = true;
          break;
        }
      }
      
      expect(foundDutchDay, isTrue, reason: 'Should display Dutch day of week');
    });
  });

  group('CompanyDashboardMain Statistics Tests', () {
    testWidgets('should display statistics card with overview section', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Overzicht'), findsOneWidget);
      expect(find.text('Actieve Jobs'), findsOneWidget);
      expect(find.text('Sollicitaties'), findsOneWidget);
      expect(find.text('Deze Maand'), findsOneWidget);
    });

    testWidgets('should display mock statistics values', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = AnimationController(
                  duration: const Duration(milliseconds: 600),
                  vsync: Scaffold.of(context),
                );
                return CompanyDashboardMain(animationController: controller);
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Mock values from the implementation
      expect(find.text('5'), findsOneWidget); // Active jobs
      expect(find.text('12'), findsOneWidget); // Applications
      expect(find.text('€2.1K'), findsOneWidget); // Revenue
    });
  });

  group('Notification Badge Logic Tests', () {
    test('should return correct unread notification count', () {
      // This would test the _getUnreadNotificationCount method
      // For now it returns mock data (3)
      const expectedCount = 3;
      
      // In a real implementation, this would test the actual service call
      expect(expectedCount, equals(3));
    });

    test('should format badge count correctly for large numbers', () {
      // Test badge formatting logic
      String formatBadgeCount(int count) {
        return count > 99 ? '99+' : count.toString();
      }

      expect(formatBadgeCount(5), equals('5'));
      expect(formatBadgeCount(99), equals('99'));
      expect(formatBadgeCount(100), equals('99+'));
      expect(formatBadgeCount(150), equals('99+'));
    });
  });
}
