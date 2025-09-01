import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_status_colors.dart';
import 'package:securyflex_app/beveiliger_agenda/models/shift_data.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';

void main() {
  group('Unified Design System Tests', () {
    
    group('Design Tokens', () {
      test('should have consistent font family', () {
        expect(DesignTokens.fontFamily, equals('WorkSans'));
      });

      test('should have proper color system', () {
        // Test primary colors
        expect(DesignTokens.colorPrimaryBlue, equals(const Color(0xFF1E3A8A)));
        expect(DesignTokens.colorSecondaryTeal, equals(const Color(0xFF54D3C2)));
        
        // Test semantic colors
        expect(DesignTokens.colorSuccess, equals(const Color(0xFF10B981)));
        expect(DesignTokens.colorWarning, equals(const Color(0xFFF59E0B)));
        expect(DesignTokens.colorError, equals(const Color(0xFFEF4444)));
      });

      test('should have consistent spacing system', () {
        expect(DesignTokens.spacingXS, equals(4.0));
        expect(DesignTokens.spacingS, equals(8.0));
        expect(DesignTokens.spacingM, equals(16.0));
        expect(DesignTokens.spacingL, equals(24.0));
        expect(DesignTokens.spacingXL, equals(32.0));
      });

      test('should have consistent border radius system', () {
        expect(DesignTokens.radiusS, equals(4.0));
        expect(DesignTokens.radiusM, equals(8.0));
        expect(DesignTokens.radiusL, equals(12.0));
        expect(DesignTokens.radiusXL, equals(16.0));
      });

      test('should have comprehensive status color system', () {
        // Test status colors are properly defined
        expect(DesignTokens.statusPending, equals(DesignTokens.colorWarning));
        expect(DesignTokens.statusAccepted, equals(DesignTokens.colorInfo));
        expect(DesignTokens.statusConfirmed, equals(DesignTokens.colorSuccess));
        expect(DesignTokens.statusInProgress, equals(DesignTokens.colorPrimaryBlue));
        expect(DesignTokens.statusCompleted, equals(DesignTokens.colorSuccessLight));
        expect(DesignTokens.statusCancelled, equals(DesignTokens.colorError));
      });

      test('should have priority color system', () {
        // Test priority colors are properly defined
        expect(DesignTokens.priorityLow, equals(DesignTokens.colorGray500));
        expect(DesignTokens.priorityMedium, equals(DesignTokens.colorWarning));
        expect(DesignTokens.priorityHigh, equals(DesignTokens.colorError));
        expect(DesignTokens.priorityUrgent, equals(const Color(0xFFDC2626)));
      });

      test('should have proper shadow system', () {
        expect(DesignTokens.shadowLight.color, equals(const Color(0x0A000000)));
        expect(DesignTokens.shadowMedium.color, equals(const Color(0x1A000000)));
        expect(DesignTokens.shadowHeavy.color, equals(const Color(0x26000000)));
      });
    });

    group('Theme System', () {
      test('should provide themes for all user roles', () {
        final guardTheme = SecuryFlexTheme.getTheme(UserRole.guard);
        final companyTheme = SecuryFlexTheme.getTheme(UserRole.company);
        final adminTheme = SecuryFlexTheme.getTheme(UserRole.admin);

        expect(guardTheme, isA<ThemeData>());
        expect(companyTheme, isA<ThemeData>());
        expect(adminTheme, isA<ThemeData>());
      });

      test('should have consistent font family across themes', () {
        final guardTheme = SecuryFlexTheme.getTheme(UserRole.guard);
        expect(guardTheme.textTheme.bodyLarge?.fontFamily, equals(DesignTokens.fontFamily));
      });

      test('should have role-specific color schemes', () {
        final guardColorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
        final companyColorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
        final adminColorScheme = SecuryFlexTheme.getColorScheme(UserRole.admin);

        // Guard theme should use primary blue
        expect(guardColorScheme.primary, equals(DesignTokens.guardPrimary));
        
        // Company theme should use teal
        expect(companyColorScheme.primary, equals(DesignTokens.companyPrimary));
        
        // Admin theme should use charcoal
        expect(adminColorScheme.primary, equals(DesignTokens.adminPrimary));
      });
    });

    group('Unified Header', () {
      testWidgets('should render simple header correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedHeader.simple(
                title: 'Test Header',
                userRole: UserRole.guard,
              ),
            ),
          ),
        );

        expect(find.text('Test Header'), findsOneWidget);
      });

      testWidgets('should support different user roles', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.company),
            home: Scaffold(
              body: UnifiedHeader.simple(
                title: 'Company Header',
                userRole: UserRole.company,
              ),
            ),
          ),
        );

        expect(find.text('Company Header'), findsOneWidget);
      });

      testWidgets('should render with actions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedHeader.simple(
                title: 'Header with Actions',
                actions: [
                  HeaderElements.actionButton(
                    icon: Icons.search,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Header with Actions'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('Unified Buttons', () {
      testWidgets('should render primary button correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedButton.primary(
                text: 'Primary Button',
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Primary Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should render secondary button correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedButton.secondary(
                text: 'Secondary Button',
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Secondary Button'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('should handle button press', (WidgetTester tester) async {
        bool pressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedButton.primary(
                text: 'Clickable Button',
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Clickable Button'));
        expect(pressed, isTrue);
      });
    });

    group('Unified Cards', () {
      testWidgets('should render standard card correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedCard.standard(
                child: Text('Card Content'),
              ),
            ),
          ),
        );

        expect(find.text('Card Content'), findsOneWidget);
      });

      testWidgets('should support different variants', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: Column(
                children: [
                  UnifiedCard.standard(child: Text('Standard')),
                  UnifiedCard.compact(child: Text('Compact')),
                  UnifiedCard.featured(child: Text('Featured')),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Standard'), findsOneWidget);
        expect(find.text('Compact'), findsOneWidget);
        expect(find.text('Featured'), findsOneWidget);
      });

      testWidgets('should handle card tap when clickable', (WidgetTester tester) async {
        bool tapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: UnifiedCard.standard(
                isClickable: true,
                onTap: () {
                  tapped = true;
                },
                child: Text('Clickable Card'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Clickable Card'));
        expect(tapped, isTrue);
      });
    });

    group('Integration Tests', () {
      testWidgets('should work together in a complete screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: Column(
                children: [
                  UnifiedHeader.simple(
                    title: 'Integration Test',
                    userRole: UserRole.guard,
                    actions: [
                      HeaderElements.actionButton(
                        icon: Icons.settings,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingM),
                      child: Column(
                        children: [
                          UnifiedCard.standard(
                            child: Column(
                              children: [
                                Text('Welcome to SecuryFlex'),
                                SizedBox(height: DesignTokens.spacingM),
                                UnifiedButton.primary(
                                  text: 'Get Started',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Integration Test'), findsOneWidget);
        expect(find.text('Welcome to SecuryFlex'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('Status Color System', () {
      test('should provide correct shift status colors', () {
        expect(
          StatusColorHelper.getShiftStatusColor(ShiftStatus.pending),
          equals(DesignTokens.statusPending),
        );
        expect(
          StatusColorHelper.getShiftStatusColor(ShiftStatus.confirmed),
          equals(DesignTokens.statusConfirmed),
        );
        expect(
          StatusColorHelper.getShiftStatusColor(ShiftStatus.completed),
          equals(DesignTokens.statusCompleted),
        );
      });

      test('should provide correct job posting status colors', () {
        expect(
          StatusColorHelper.getJobPostingStatusColor(JobPostingStatus.active),
          equals(DesignTokens.statusConfirmed),
        );
        expect(
          StatusColorHelper.getJobPostingStatusColor(JobPostingStatus.draft),
          equals(DesignTokens.statusDraft),
        );
        expect(
          StatusColorHelper.getJobPostingStatusColor(JobPostingStatus.cancelled),
          equals(DesignTokens.statusCancelled),
        );
      });

      test('should provide correct generic status colors', () {
        expect(
          StatusColorHelper.getGenericStatusColor('pending'),
          equals(DesignTokens.statusPending),
        );
        expect(
          StatusColorHelper.getGenericStatusColor('bevestigd'),
          equals(DesignTokens.statusConfirmed),
        );
        expect(
          StatusColorHelper.getGenericStatusColor('voltooid'),
          equals(DesignTokens.statusCompleted),
        );
      });

      test('should provide correct priority colors', () {
        expect(
          StatusColorHelper.getPriorityColor('low'),
          equals(DesignTokens.priorityLow),
        );
        expect(
          StatusColorHelper.getPriorityColor('urgent'),
          equals(DesignTokens.priorityUrgent),
        );
      });

      test('should provide Dutch status text', () {
        expect(
          StatusColorHelper.getShiftStatusText(ShiftStatus.pending),
          equals('Wachtend'),
        );
        expect(
          StatusColorHelper.getShiftStatusText(ShiftStatus.confirmed),
          equals('Bevestigd'),
        );
      });
    });
  });
}
