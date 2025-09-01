import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/beveiliger_agenda/screens/planning_tab_screen.dart';
import 'package:securyflex_app/beveiliger_agenda/tabs/shifts_tab.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  testWidgets('Planning screens render correctly', (WidgetTester tester) async {
    // Create a test app with PlanningTabScreen
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        home: const PlanningTabScreen(),
      ),
    );
    
    // Let the screen build
    await tester.pumpAndSettle();
    
    // Check if the Planning header is shown
    expect(find.text('Planning'), findsOneWidget);
    
    // Check if the tab bar is shown with Dutch labels
    expect(find.text('Diensten'), findsOneWidget);
    expect(find.text('Beschikbaar'), findsOneWidget);
    expect(find.text('Urenregistratie'), findsOneWidget);
    
    // The first tab (Diensten) should be active and showing content
    // Look for typical content that should appear
    expect(find.text('Diensten laden...'), findsNothing); // Should not be loading
    
    print('✅ Planning screens render test passed');
  });
  
  testWidgets('Shifts tab shows content', (WidgetTester tester) async {
    // Create animation controller for testing
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: tester,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        home: Scaffold(
          body: ShiftsTab(
            animationController: animationController,
          ),
        ),
      ),
    );
    
    // Start the animation
    animationController.forward();
    
    // Let the screen build with animation
    await tester.pumpAndSettle();
    
    // Should show some content (either loading or shifts data)
    // The ShiftsTab loads sample data after 500ms
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    
    // Should not be showing loading anymore
    expect(find.text('Diensten laden...'), findsNothing);
    
    print('✅ Shifts tab content test passed');
    
    animationController.dispose();
  });
}