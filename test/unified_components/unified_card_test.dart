import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('UnifiedCard Tests', () {
    testWidgets('should create standard card with guard theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify card is present
      expect(find.byType(UnifiedCard), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      
      // Verify container structure
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should create elevated card with company theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.company,
              child: const Text('Company Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify card is present with standard variant
      expect(find.byType(UnifiedCard), findsOneWidget);
      expect(find.text('Company Content'), findsOneWidget);
    });

    testWidgets('should apply custom padding correctly', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              padding: customPadding,
              child: const Text('Padded Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the Padding widget
      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(UnifiedCard),
          matching: find.byType(Padding),
        ).first,
      );

      expect(paddingWidget.padding, equals(customPadding));
    });

    testWidgets('should apply custom margin correctly', (WidgetTester tester) async {
      const customMargin = EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              margin: customMargin,
              child: const Text('Margin Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the Container with margin
      final containers = tester.widgetList<Container>(find.byType(Container));
      final marginContainer = containers.firstWhere(
        (container) => container.margin == customMargin,
        orElse: () => throw Exception('Container with custom margin not found'),
      );

      expect(marginContainer.margin, equals(customMargin));
    });

    testWidgets('should handle custom background color', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              backgroundColor: customColor,
              child: const Text('Colored Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the Container with custom background color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final coloredContainer = containers.firstWhere(
        (container) => container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).color == customColor,
        orElse: () => throw Exception('Container with custom color not found'),
      );

      final decoration = coloredContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(customColor));
    });

    testWidgets('should apply custom border radius', (WidgetTester tester) async {
      const customRadius = BorderRadius.all(Radius.circular(20.0));

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              borderRadius: customRadius,
              child: const Text('Rounded Content'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the Container with custom border radius
      final containers = tester.widgetList<Container>(find.byType(Container));
      final roundedContainer = containers.firstWhere(
        (container) => container.decoration is BoxDecoration &&
            (container.decoration as BoxDecoration).borderRadius == customRadius,
        orElse: () => throw Exception('Container with custom border radius not found'),
      );

      final decoration = roundedContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(customRadius));
    });

    testWidgets('should handle different user roles correctly', (WidgetTester tester) async {
      // Test Guard role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              child: const Text('Guard Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Guard Card'), findsOneWidget);

      // Test Company role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.company,
              child: const Text('Company Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Company Card'), findsOneWidget);

      // Test Admin role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.admin),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.admin,
              child: const Text('Admin Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Admin Card'), findsOneWidget);
    });

    testWidgets('should handle different card variants', (WidgetTester tester) async {
      // Test Standard variant
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              child: const Text('Standard Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Standard Card'), findsOneWidget);

      // Test Compact variant
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.compact,
              userRole: UserRole.guard,
              child: const Text('Compact Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Compact Card'), findsOneWidget);

      // Test Featured variant
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.featured,
              userRole: UserRole.guard,
              child: const Text('Featured Card'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Featured Card'), findsOneWidget);
    });

    testWidgets('should handle complex child widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: UnifiedCard(
              variant: UnifiedCardVariant.standard,
              userRole: UserRole.guard,
              child: Column(
                children: [
                  const Text('Title'),
                  const SizedBox(height: 8),
                  const Text('Subtitle'),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify all child widgets are present
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('should build efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedCard(
                variant: UnifiedCardVariant.standard,
                userRole: UserRole.guard,
                child: const Text('Performance Test'),
              ),
            ),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        // Card should build quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      testWidgets('should handle multiple cards efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => UnifiedCard(
                  variant: UnifiedCardVariant.standard,
                  userRole: UserRole.guard,
                  child: Text('Card $index'),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        // Multiple cards should build efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        expect(find.byType(UnifiedCard), findsNWidgets(10));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedCard(
                variant: UnifiedCardVariant.standard,
                userRole: UserRole.guard,
                child: const Text('Accessible Card'),
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify content is accessible
        expect(find.text('Accessible Card'), findsOneWidget);
        
        // Card should not interfere with accessibility
        final semantics = tester.getSemantics(find.text('Accessible Card'));
        expect(semantics.label, equals('Accessible Card'));
      });
    });
  });
}
