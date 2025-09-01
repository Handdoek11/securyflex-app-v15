import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('UnifiedHeader Tests', () {
    testWidgets('should create simple header with guard theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Test Header',
                userRole: UserRole.guard,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();

      // Verify header is present
      expect(find.byType(UnifiedHeader), findsOneWidget);
      expect(find.text('Test Header'), findsOneWidget);
    });

    testWidgets('should create animated header with scroll controller', (WidgetTester tester) async {
      final animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: TestVSync(),
      );

      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.animated(
                title: 'Animated Header',
                animationController: animationController,
                scrollController: scrollController,
                enableScrollAnimation: true,
                userRole: UserRole.guard,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();

      // Verify animated header is present
      expect(find.byType(UnifiedHeader), findsOneWidget);
      expect(find.text('Animated Header'), findsOneWidget);

      // Cleanup
      animationController.dispose();
      scrollController.dispose();
    });

    testWidgets('should handle different user roles correctly', (WidgetTester tester) async {
      // Test Guard role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Guard Header',
                userRole: UserRole.guard,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Guard Header'), findsOneWidget);

      // Test Company role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Company Header',
                userRole: UserRole.company,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Company Header'), findsOneWidget);

      // Test Admin role
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.admin),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Admin Header',
                userRole: UserRole.admin,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Admin Header'), findsOneWidget);
    });

    testWidgets('should handle title alignment correctly', (WidgetTester tester) async {
      // Test left alignment
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Left Aligned',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.left,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Left Aligned'), findsOneWidget);

      // Test center alignment
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Center Aligned',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.center,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Center Aligned'), findsOneWidget);
    });

    testWidgets('should display action buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Header with Actions',
                userRole: UserRole.guard,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();

      // Verify header and actions are present
      expect(find.text('Header with Actions'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('should handle leading widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.simple(
                title: 'Header with Leading',
                userRole: UserRole.guard,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {},
                ),
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();

      // Verify header and leading widget are present
      expect(find.text('Header with Leading'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should handle scroll animation correctly', (WidgetTester tester) async {
      final animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: TestVSync(),
      );

      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  flexibleSpace: UnifiedHeader.animated(
                    title: 'Scrollable Header',
                    animationController: animationController,
                    scrollController: scrollController,
                    enableScrollAnimation: true,
                    userRole: UserRole.guard,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Item $index')),
                    childCount: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify header is present
      expect(find.text('Scrollable Header'), findsOneWidget);

      // Test scrolling
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pump();

      // Should handle scrolling without errors
      expect(tester.takeException(), isNull);

      // Cleanup
      animationController.dispose();
      scrollController.dispose();
    });

    testWidgets('should handle animation lifecycle correctly', (WidgetTester tester) async {
      final animationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: TestVSync(),
      );

      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.animated(
                title: 'Animated Header',
                animationController: animationController,
                scrollController: scrollController,
                enableScrollAnimation: true,
                userRole: UserRole.guard,
              ),
            ),
            body: const Text('Body'),
          ),
        ),
      );

      await tester.pump();

      // Start animation
      animationController.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify animation is progressing
      expect(animationController.value, greaterThan(0.0));

      // Complete animation
      await tester.pumpAndSettle();
      expect(animationController.value, equals(1.0));

      // Cleanup
      animationController.dispose();
      scrollController.dispose();
    });

    group('Performance Tests', () {
      testWidgets('should build efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(AppBar().preferredSize.height),
                child: UnifiedHeader.simple(
                  title: 'Performance Test',
                  userRole: UserRole.guard,
                ),
              ),
              body: const Text('Body'),
            ),
          ),
        );

        await tester.pump();
        stopwatch.stop();

        // Header should build quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      testWidgets('should handle rapid theme changes', (WidgetTester tester) async {
        // Test rapid theme switching
        for (final role in UserRole.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: SecuryFlexTheme.getTheme(role),
              home: Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(AppBar().preferredSize.height),
                  child: UnifiedHeader.simple(
                    title: 'Theme Test',
                    userRole: role,
                  ),
                ),
                body: const Text('Body'),
              ),
            ),
          );

          await tester.pump();
          expect(find.text('Theme Test'), findsOneWidget);
        }

        // Should handle rapid changes without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(AppBar().preferredSize.height),
                child: UnifiedHeader.simple(
                  title: 'Accessible Header',
                  userRole: UserRole.guard,
                ),
              ),
              body: const Text('Body'),
            ),
          ),
        );

        await tester.pump();

        // Verify header content is accessible
        expect(find.text('Accessible Header'), findsOneWidget);
        
        // Header should provide proper semantics
        final semantics = tester.getSemantics(find.text('Accessible Header'));
        expect(semantics.label, equals('Accessible Header'));
      });

      testWidgets('should handle action button accessibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(AppBar().preferredSize.height),
                child: UnifiedHeader.simple(
                  title: 'Header with Actions',
                  userRole: UserRole.guard,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                      tooltip: 'Search',
                    ),
                  ],
                ),
              ),
              body: const Text('Body'),
            ),
          ),
        );

        await tester.pump();

        // Verify action button is accessible
        expect(find.byTooltip('Search'), findsOneWidget);
      });
    });
  });
}

/// Test implementation of TickerProvider for testing
class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
