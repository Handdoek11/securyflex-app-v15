import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/auth/enhanced_glassmorphic_login_screen.dart';
import 'package:securyflex_app/beveiliger_dashboard/beveiliger_dashboard_home.dart';
import 'package:securyflex_app/company_dashboard/company_dashboard_home.dart';
import 'package:securyflex_app/company_dashboard/models/company_data.dart';
import 'package:securyflex_app/company_dashboard/models/company_tab_data.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/main.dart';

void main() {
  group('Company Dashboard Foundation Tests', () {
    setUp(() {
      // Reset authentication state before each test
      AuthService.logout();
    });

    group('Role-Based Routing Tests', () {
      testWidgets('Should route Guard users to BeveiligerDashboardHome', (WidgetTester tester) async {
        // Login as Guard
        await AuthService.login('guard@securyflex.nl', 'guard123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: MyApp(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should find BeveiligerDashboardHome
        expect(find.byType(BeveiligerDashboardHome), findsOneWidget);
        expect(find.byType(CompanyDashboardHome), findsNothing);
      });

      testWidgets('Should route Company users to CompanyDashboardHome', (WidgetTester tester) async {
        // Login as Company
        await AuthService.login('company@securyflex.nl', 'company123');
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: MyApp(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should find CompanyDashboardHome
        expect(find.byType(CompanyDashboardHome), findsOneWidget);
        expect(find.byType(BeveiligerDashboardHome), findsNothing);
      });

      testWidgets('Should route unauthenticated users to LoginScreen', (WidgetTester tester) async {
        // Ensure logged out
        AuthService.logout();
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: MyApp(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should find LoginScreen
        expect(find.byType(EnhancedGlassmorphicLoginScreen), findsOneWidget);
        expect(find.byType(BeveiligerDashboardHome), findsNothing);
        expect(find.byType(CompanyDashboardHome), findsNothing);
      });
    });

    group('Company Dashboard Navigation Tests', () {
      testWidgets('Should display Company dashboard with proper theming', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        // Should find Company dashboard elements
        expect(find.byType(CompanyDashboardHome), findsOneWidget);
        expect(find.text('Bedrijf Dashboard'), findsOneWidget);
        
        // Should have Company theming applied
        final theme = Theme.of(tester.element(find.byType(CompanyDashboardHome)));
        expect(theme.colorScheme.primary, equals(SecuryFlexTheme.getColorScheme(UserRole.company).primary));
      });

      testWidgets('Should have 4 navigation tabs with correct icons', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );

        await tester.pumpAndSettle();

        // Should have 4 tabs (optimized navigation)
        expect(CompanyTabData.tabIconsList.length, equals(4));

        // Verify tab configuration: Dashboard, Jobs, Chat, Settings
        expect(CompanyTabData.tabIconsList[0].icon, equals(Icons.dashboard_outlined));
        expect(CompanyTabData.tabIconsList[1].icon, equals(Icons.work_outline));
        expect(CompanyTabData.tabIconsList[2].icon, equals(Icons.chat_bubble_outline));
        expect(CompanyTabData.tabIconsList[3].icon, equals(Icons.settings_outlined));
      });
    });

    group('Company Data Model Tests', () {
      test('Should create CompanyData with Dutch business validation', () {
        final company = CompanyData(
          companyId: 'COMP001',
          companyName: 'Amsterdam Security BV',
          kvkNumber: '12345678',
          contactPerson: 'Jan van der Berg',
          emailAddress: 'info@amsterdamsecurity.nl',
          phoneNumber: '+31 20 1234567',
          address: 'Damrak 123',
          postalCode: '1012AB',
          city: 'Amsterdam',
          registeredSince: DateTime.now(),
        );
        
        expect(company.companyName, equals('Amsterdam Security BV'));
        expect(company.kvkNumber, equals('12345678'));
        expect(company.postalCode, equals('1012AB'));
        expect(company.status, equals(CompanyStatus.active));
      });

      test('Should support copyWith functionality', () {
        final originalCompany = CompanyData(
          companyId: 'COMP001',
          companyName: 'Original Name',
          kvkNumber: '12345678',
          contactPerson: 'Jan van der Berg',
          emailAddress: 'info@original.nl',
          phoneNumber: '+31 20 1234567',
          address: 'Damrak 123',
          postalCode: '1012AB',
          city: 'Amsterdam',
          registeredSince: DateTime.now(),
        );
        
        final updatedCompany = originalCompany.copyWith(
          companyName: 'Updated Name',
          emailAddress: 'info@updated.nl',
        );
        
        expect(updatedCompany.companyName, equals('Updated Name'));
        expect(updatedCompany.emailAddress, equals('info@updated.nl'));
        expect(updatedCompany.kvkNumber, equals('12345678')); // Should remain unchanged
      });

      test('Should have proper Dutch status display names', () {
        expect(CompanyStatus.active.displayName, equals('Actief'));
        expect(CompanyStatus.inactive.displayName, equals('Inactief'));
        expect(CompanyStatus.suspended.displayName, equals('Opgeschort'));
        expect(CompanyStatus.pending.displayName, equals('In behandeling'));
      });
    });

    group('Company Theme Integration Tests', () {
      testWidgets('Should apply Company theme colors correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: CompanyDashboardHome(),
          ),
        );
        
        await tester.pumpAndSettle();
        
        final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
        
        // Verify Company theme is applied
        expect(companyColors.primary, equals(const Color(0xFF54D3C2))); // Teal
        expect(companyColors.secondary, equals(const Color(0xFF1E3A8A))); // Navy Blue
      });
    });
  });
}
