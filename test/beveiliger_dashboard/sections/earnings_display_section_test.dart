import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/beveiliger_dashboard/sections/earnings_display_section.dart';
import 'package:securyflex_app/beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('EarningsDisplaySection', () {
    late EnhancedEarningsData mockEarningsData;

    setUp(() {
      mockEarningsData = EnhancedEarningsData(
        totalToday: 125.50,
        totalWeek: 875.25,
        totalMonth: 2450.75,
        hourlyRate: 15.50,
        hoursWorkedToday: 8.0,
        hoursWorkedWeek: 40.0,
        overtimeHours: 0.0,
        overtimeRate: 23.25,
        vakantiegeld: 196.06,
        btwAmount: 514.66,
        isFreelance: false,
        dutchFormattedToday: '€125,50',
        dutchFormattedWeek: '€875,25',
        dutchFormattedMonth: '€2.450,75',
        lastCalculated: DateTime.now(),
      );
    });

    testWidgets('displays earnings correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: EarningsDisplaySection(earnings: mockEarningsData),
          ),
        ),
      );

      // Verify section title
      expect(find.text('Verdiensten'), findsOneWidget);
      
      // Verify today's earnings
      expect(find.text('Vandaag'), findsOneWidget);
      expect(find.text('€125,50'), findsOneWidget);
      
      // Verify monthly earnings
      expect(find.text('Deze maand'), findsOneWidget);
      expect(find.text('€2.450,75'), findsOneWidget);
    });

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: EarningsDisplaySection(earnings: mockEarningsData),
          ),
        ),
      );

      // Verify no exceptions are thrown during render
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses correct guard theming', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: EarningsDisplaySection(earnings: mockEarningsData),
          ),
        ),
      );

      // Verify Container is present (styled card)
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });
}