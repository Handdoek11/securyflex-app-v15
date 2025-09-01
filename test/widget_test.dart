// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/enhanced_glassmorphic_login_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'helpers/firebase_test_helper.dart';

void main() {
  group('SecuryFlex App Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing to prevent "No Firebase App created" errors
      await FirebaseTestHelper.setupTestGroup();
    });

    testWidgets('SecuryFlex app smoke test - Login Screen', (WidgetTester tester) async {
      // Build a simplified version of the app for testing
      // Using EnhancedGlassmorphicLoginScreen directly to avoid Firebase initialization issues in main.dart
      await tester.pumpWidget(
        MaterialApp(
          title: 'SecuryFlex Test',
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: EnhancedGlassmorphicLoginScreen(),
        ),
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // Verify that we can find the MaterialApp
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should initialize with MaterialApp'
      );

      // Verify that the login screen is displayed
      expect(
        find.byType(EnhancedGlassmorphicLoginScreen),
        findsOneWidget,
        reason: 'Login screen should be displayed'
      );

      // Verify that the app doesn't crash on startup
      expect(tester.takeException(), isNull);
    });
  });
}
