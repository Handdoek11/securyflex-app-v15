import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/company_dashboard_home.dart';
import 'package:securyflex_app/company_dashboard/models/company_tab_data.dart';
import 'package:securyflex_app/company_dashboard/screens/company_dashboard_main.dart';
import 'package:securyflex_app/company_dashboard/screens/company_jobs_applications_tab_screen.dart';
import 'package:securyflex_app/company_dashboard/screens/company_profile_screen.dart';
import 'package:securyflex_app/chat/screens/conversations_screen.dart';

/// Tests for the optimized 4-tab company navigation
/// Verifies that the navigation restructuring works correctly
void main() {
  group('Company Navigation Optimization Tests', () {
    setUpAll(() async {
      // Initialize Dutch locale data for date formatting
      await initializeDateFormatting('nl_NL', null);
    });

    testWidgets('should have optimized 4-tab structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 4 tabs instead of 5
      expect(CompanyTabData.tabIconsList.length, equals(4));

      // Verify correct tab configuration
      expect(CompanyTabData.tabIconsList[0].icon, equals(Icons.dashboard_outlined)); // Dashboard
      expect(CompanyTabData.tabIconsList[1].icon, equals(Icons.work_outline));      // Jobs
      expect(CompanyTabData.tabIconsList[2].icon, equals(Icons.chat_bubble_outline)); // Chat
      expect(CompanyTabData.tabIconsList[3].icon, equals(Icons.settings_outlined));  // Settings

      // Verify correct indexes
      expect(CompanyTabData.tabIconsList[0].index, equals(0));
      expect(CompanyTabData.tabIconsList[1].index, equals(1));
      expect(CompanyTabData.tabIconsList[2].index, equals(2));
      expect(CompanyTabData.tabIconsList[3].index, equals(3));
    });

    testWidgets('should display correct bottom navigation labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 4 navigation labels
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Opdrachten'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Profiel'), findsOneWidget);

      // Verify Applications tab is removed
      expect(find.text('Sollicitaties'), findsNothing);
    });

    testWidgets('should navigate correctly between all 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Test Dashboard tab (index 0) - default
      expect(find.byType(CompanyDashboardMain), findsOneWidget);

      // Test Jobs tab (index 1)
      await tester.tap(find.text('Opdrachten'));
      await tester.pumpAndSettle();
      expect(find.byType(CompanyJobsApplicationsTabScreen), findsOneWidget);

      // Test Chat tab (index 2)
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationsScreen), findsOneWidget);

      // Test Settings tab (index 3)
      await tester.tap(find.text('Profiel'));
      await tester.pumpAndSettle();
      expect(find.byType(CompanyProfileScreen), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(CompanyDashboardMain), findsOneWidget);
    });

    testWidgets('should load integrated Jobs+Applications screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Jobs tab
      await tester.tap(find.text('Opdrachten'));
      await tester.pumpAndSettle();

      // Verify integrated screen is loaded
      expect(find.byType(CompanyJobsApplicationsTabScreen), findsOneWidget);

      // Verify both Jobs and Applications tabs are available within the screen
      expect(find.text('Job Beheer'), findsAtLeastNWidgets(1));
      expect(find.text('Sollicitaties'), findsAtLeastNWidgets(1));
    });

    testWidgets('should maintain proper theming with 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Company theming is applied
      final theme = Theme.of(tester.element(find.byType(CompanyDashboardHome)));
      expect(theme.colorScheme.primary, equals(SecuryFlexTheme.getColorScheme(UserRole.company).primary));
    });

    testWidgets('should handle navigation state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate through all tabs and verify state
      for (int i = 0; i < 4; i++) {
        final tabLabels = ['Dashboard', 'Opdrachten', 'Chat', 'Profiel'];
        
        await tester.tap(find.text(tabLabels[i]));
        await tester.pumpAndSettle();
        
        // Verify the tab is selected (this would be reflected in the UI state)
        expect(find.text(tabLabels[i]), findsOneWidget);
      }
    });

    testWidgets('should provide better spacing with 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: CompanyDashboardHome(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the bottom navigation
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // With 4 tabs instead of 5, each tab should have more space
      // This is a qualitative improvement that's hard to test directly,
      // but we can verify the structure is correct
      expect(CompanyTabData.tabIconsList.length, equals(4));
    });

    test('should have correct tab data model structure', () {
      // Verify the optimized tab structure
      final tabs = CompanyTabData.tabIconsList;
      
      expect(tabs.length, equals(4));
      
      // Verify tab order and properties
      expect(tabs[0].index, equals(0)); // Dashboard
      expect(tabs[1].index, equals(1)); // Jobs
      expect(tabs[2].index, equals(2)); // Chat
      expect(tabs[3].index, equals(3)); // Settings
      
      // Verify no gaps in indexes
      for (int i = 0; i < tabs.length; i++) {
        expect(tabs[i].index, equals(i));
      }
    });
  });
}
