import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/routing/app_router.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  testWidgets('Navigation from registration to login works without pop error', (WidgetTester tester) async {
    // Initialize the router
    AppRouter.initialize();
    
    // Build the app with GoRouter
    await tester.pumpWidget(
      MaterialApp.router(
        title: 'SecuryFlex Navigation Test',
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        routerConfig: AppRouter.router,
      ),
    );
    
    // Wait for any animations
    await tester.pumpAndSettle();
    
    // Navigate to registration
    AppRouter.router.go('/register');
    await tester.pumpAndSettle();
    
    // Look for the back button in registration screen
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    
    // Tap the back button - this should navigate to login without error
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    
    // Should be on login screen now (check for email field)
    expect(find.text('E-mailadres'), findsWidgets);
    
    print('Navigation fix test passed! No pop error when going back from registration.');
  });
}