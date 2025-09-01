import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  testWidgets('GoRouter navigation test', (WidgetTester tester) async {
    // Initialize the router
    AppRouter.initialize();
    
    // Build the app with GoRouter
    await tester.pumpWidget(
      MaterialApp.router(
        title: 'SecuryFlex',
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        routerConfig: AppRouter.router,
      ),
    );
    
    // Wait for any animations
    await tester.pumpAndSettle();
    
    // Check if login screen loads - look for email field label
    expect(find.text('E-mailadres'), findsWidgets);
    
    print('GoRouter test passed!');
  });
}