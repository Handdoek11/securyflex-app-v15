import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_components/enhanced_guard_header.dart';

void main() {
  group('EnhancedGuardHeader Tests', () {
    testWidgets('renders with basic title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(EnhancedGuardHeader), findsOneWidget);
    });

    testWidgets('shows notification bell when callback provided', (WidgetTester tester) async {
      bool notificationPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
              notificationCount: 5,
              onNotificationPressed: () => notificationPressed = true,
            ),
          ),
        ),
      );

      // Find notification icon
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap notification bell
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      
      expect(notificationPressed, isTrue);
    });

    testWidgets('applies gradient background when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
              enableGradientBackground: true,
            ),
          ),
        ),
      );

      // Find container with decoration
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      
      expect(decoration.gradient, isNotNull);
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('shows pulsing animation with notifications > 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
              notificationCount: 3,
              onNotificationPressed: () {},
            ),
          ),
        ),
      );

      // Pump a few frames to let animation start
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('limits badge count to 99+', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
              notificationCount: 150,
              onNotificationPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('150'), findsNothing);
    });

    testWidgets('includes custom actions when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedGuardHeader(
              title: 'Dashboard',
              actions: [
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}