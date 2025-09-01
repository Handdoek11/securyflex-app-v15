import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('UnifiedHeader Company Gradient Tests', () {
    testWidgets('should create company gradient header with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.companyGradient(
                title: 'Company Dashboard',
              ),
            ),
            body: Container(),
          ),
        ),
      );

      // Verify the header is rendered
      expect(find.text('Company Dashboard'), findsOneWidget);
      
      // Verify gradient container exists
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should create company gradient header with notifications', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.companyGradient(
                title: 'Company Dashboard',
                showNotifications: true,
              ),
            ),
            body: Container(),
          ),
        ),
      );

      // Verify the header is rendered
      expect(find.text('Company Dashboard'), findsOneWidget);
      
      // Verify notifications icon exists
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should create company gradient header with TabBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(AppBar().preferredSize.height + 48),
                child: UnifiedHeader.companyGradient(
                  title: 'Company Dashboard',
                  tabBar: TabBar(
                    tabs: [
                      Tab(text: 'Jobs'),
                      Tab(text: 'Applications'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                children: [
                  Text('Jobs'),
                  Text('Applications'),
                  Text('Analytics'),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify the header is rendered
      expect(find.text('Company Dashboard'), findsOneWidget);

      // Verify TabBar exists
      expect(find.byType(TabBar), findsOneWidget);

      // Verify TabBarView exists
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('should create company gradient header without notifications', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.companyGradient(
                title: 'Company Dashboard',
                showNotifications: false,
              ),
            ),
            body: Container(),
          ),
        ),
      );

      // Verify the header is rendered
      expect(find.text('Company Dashboard'), findsOneWidget);
      
      // Verify notifications icon does NOT exist
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('should create company gradient header with custom actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(AppBar().preferredSize.height),
              child: UnifiedHeader.companyGradient(
                title: 'Company Dashboard',
                showNotifications: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            body: Container(),
          ),
        ),
      );

      // Verify the header is rendered
      expect(find.text('Company Dashboard'), findsOneWidget);
      
      // Verify both notifications and search icons exist
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
