import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('Header Alignment and Responsive Font Tests', () {
    testWidgets('should render guard header with left alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedHeader.simple(
              title: 'Guard Dashboard',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('Guard Dashboard'), findsOneWidget);
      
      // Verify the text widget exists
      final textWidget = tester.widget<Text>(find.text('Guard Dashboard'));
      expect(textWidget.textAlign, equals(TextAlign.left));
    });

    testWidgets('should render company header with left alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: UnifiedHeader.simple(
              title: 'Company Dashboard',
              userRole: UserRole.company,
              titleAlignment: TextAlign.left,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('Company Dashboard'), findsOneWidget);
      
      // Verify the text widget exists
      final textWidget = tester.widget<Text>(find.text('Company Dashboard'));
      expect(textWidget.textAlign, equals(TextAlign.left));
    });

    testWidgets('should use responsive font sizing for small screens', (WidgetTester tester) async {
      // Set a small screen size
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedHeader.simple(
              title: 'Small Screen Test',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
              enableResponsiveFontSize: true,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('Small Screen Test'), findsOneWidget);
      
      // The font size should be smaller for small screens
      final textWidget = tester.widget<Text>(find.text('Small Screen Test'));
      expect(textWidget.style?.fontSize, lessThan(22.0)); // Should be less than default titleLarge
    });

    testWidgets('should use normal font sizing for large screens', (WidgetTester tester) async {
      // Set a large screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedHeader.simple(
              title: 'Large Screen Test',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
              enableResponsiveFontSize: true,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('Large Screen Test'), findsOneWidget);
      
      // The font size should be normal for large screens
      final textWidget = tester.widget<Text>(find.text('Large Screen Test'));
      expect(textWidget.style?.fontSize, equals(22.0)); // Should be default titleLarge
    });

    testWidgets('should disable responsive font sizing when flag is false', (WidgetTester tester) async {
      // Set a small screen size
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedHeader.simple(
              title: 'No Responsive Test',
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
              enableResponsiveFontSize: false,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('No Responsive Test'), findsOneWidget);
      
      // The font size should remain normal even on small screens
      final textWidget = tester.widget<Text>(find.text('No Responsive Test'));
      expect(textWidget.style?.fontSize, equals(22.0)); // Should be default titleLarge
    });

    testWidgets('animated header should support left alignment', (WidgetTester tester) async {
      final animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: const TestVSync(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedHeader.animated(
              title: 'Animated Header',
              animationController: animationController,
              userRole: UserRole.guard,
              titleAlignment: TextAlign.left,
            ),
          ),
        ),
      );

      // Verify the header renders
      expect(find.text('Animated Header'), findsOneWidget);
      
      // Verify the text widget exists with left alignment
      final textWidget = tester.widget<Text>(find.text('Animated Header'));
      expect(textWidget.textAlign, equals(TextAlign.left));

      animationController.dispose();
    });
  });
}
